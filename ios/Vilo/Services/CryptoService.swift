import Foundation
import CryptoKit

/// E2EE Encryption Service using CryptoKit
/// Implements X3DH key agreement and Signal-like encryption
class CryptoService {
    static let shared = CryptoService()

    private var identityKey: Curve25519.KeyAgreement.PrivateKey?
    private var signedPreKey: Curve25519.KeyAgreement.PrivateKey?
    private var preKeys: [String: Curve25519.KeyAgreement.PrivateKey] = [:]
    private var sessionKeys: [String: SymmetricKey] = [:]

    private let storage = Storage.shared

    private init() {
        loadKeys()
    }

    // MARK: - Key Generation

    /// Generate new key bundle for registration
    func generateKeys() throws -> PublicKeys {
        // Generate identity key
        identityKey = Curve25519.KeyAgreement.PrivateKey()

        // Generate signed pre-key
        signedPreKey = Curve25519.KeyAgreement.PrivateKey()

        // Generate one-time pre-keys
        var preKeyPublics: [String] = []
        for i in 0..<100 {
            let preKey = Curve25519.KeyAgreement.PrivateKey()
            let keyId = UUID().uuidString
            preKeys[keyId] = preKey
            preKeyPublics.append(preKey.publicKey.rawRepresentation.base64EncodedString())
        }

        // Save keys locally
        saveKeys()

        return PublicKeys(
            identityKey: identityKey!.publicKey.rawRepresentation.base64EncodedString(),
            signedPreKey: signedPreKey!.publicKey.rawRepresentation.base64EncodedString(),
            preKeys: preKeyPublics
        )
    }

    // MARK: - Encryption

    /// Encrypt message for recipient
    func encrypt(_ plaintext: String, for recipientId: String) async throws -> String {
        // Get or establish session key
        let sessionKey = try await getSessionKey(for: recipientId)

        // Generate nonce
        let nonce = AES.GCM.Nonce()

        // Encrypt
        let plaintextData = plaintext.data(using: .utf8)!
        let sealedBox = try AES.GCM.seal(plaintextData, using: sessionKey, nonce: nonce)

        // Combine nonce + ciphertext + tag
        var combined = Data()
        combined.append(nonce.withUnsafeBytes { Data($0) })
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined.base64EncodedString()
    }

    /// Decrypt message from sender
    func decrypt(_ ciphertext: String, from senderId: String) async throws -> String {
        // Get or establish session key
        let sessionKey = try await getSessionKey(for: senderId)

        // Decode base64
        guard let combined = Data(base64Encoded: ciphertext) else {
            throw CryptoError.invalidData
        }

        // Extract components
        let nonceData = combined.prefix(12)
        let tagData = combined.suffix(16)
        let ciphertextData = combined.dropFirst(12).dropLast(16)

        // Create nonce and sealed box
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)

        // Decrypt
        let plaintextData = try AES.GCM.open(sealedBox, using: sessionKey)

        guard let plaintext = String(data: plaintextData, encoding: .utf8) else {
            throw CryptoError.invalidData
        }

        return plaintext
    }

    // MARK: - Key Exchange (X3DH)

    /// Get or establish session key for user
    private func getSessionKey(for userId: String) async throws -> SymmetricKey {
        // Check if we have existing session
        if let key = sessionKeys[userId] {
            return key
        }

        // Fetch recipient's public keys
        let recipientKeys = try await APIService.shared.getPublicKey(for: userId)

        // Perform X3DH key agreement
        let sessionKey = try performX3DH(with: recipientKeys)

        // Cache session key
        sessionKeys[userId] = sessionKey

        return sessionKey
    }

    /// Perform X3DH key agreement
    private func performX3DH(with recipientKeys: UserPublicKey) throws -> SymmetricKey {
        guard let identityKey = identityKey else {
            throw CryptoError.noKeys
        }

        // Decode recipient's identity key
        guard let recipientIdentityKeyData = Data(base64Encoded: recipientKeys.identityKey),
              let recipientSignedPreKeyData = Data(base64Encoded: recipientKeys.signedPreKey),
              let recipientPreKeyData = Data(base64Encoded: recipientKeys.preKey) else {
            throw CryptoError.invalidData
        }

        let recipientIdentityKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientIdentityKeyData)
        let recipientSignedPreKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientSignedPreKeyData)
        let recipientPreKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPreKeyData)

        // Generate ephemeral key
        let ephemeralKey = Curve25519.KeyAgreement.PrivateKey()

        // Perform 4 DH operations
        let dh1 = try identityKey.sharedSecretFromKeyAgreement(with: recipientSignedPreKey)
        let dh2 = try ephemeralKey.sharedSecretFromKeyAgreement(with: recipientIdentityKey)
        let dh3 = try ephemeralKey.sharedSecretFromKeyAgreement(with: recipientSignedPreKey)
        let dh4 = try ephemeralKey.sharedSecretFromKeyAgreement(with: recipientPreKey)

        // Combine shared secrets
        var combinedSecret = Data()
        dh1.withUnsafeBytes { combinedSecret.append(contentsOf: $0) }
        dh2.withUnsafeBytes { combinedSecret.append(contentsOf: $0) }
        dh3.withUnsafeBytes { combinedSecret.append(contentsOf: $0) }
        dh4.withUnsafeBytes { combinedSecret.append(contentsOf: $0) }

        // Derive symmetric key using HKDF
        let symmetricKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: combinedSecret),
            salt: "VILO-X3DH".data(using: .utf8)!,
            info: Data(),
            outputByteCount: 32
        )

        return symmetricKey
    }

    // MARK: - Key Storage

    private func saveKeys() {
        guard let identityKey = identityKey,
              let signedPreKey = signedPreKey else { return }

        // Save to Keychain
        storage.saveKeyData(identityKey.rawRepresentation, forKey: "identity_key")
        storage.saveKeyData(signedPreKey.rawRepresentation, forKey: "signed_pre_key")

        // Save pre-keys
        var preKeyData: [String: Data] = [:]
        for (id, key) in preKeys {
            preKeyData[id] = key.rawRepresentation
        }
        if let data = try? JSONEncoder().encode(preKeyData) {
            storage.saveKeyData(data, forKey: "pre_keys")
        }
    }

    private func loadKeys() {
        // Load from Keychain
        if let identityData = storage.getKeyData(forKey: "identity_key") {
            identityKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: identityData)
        }

        if let signedData = storage.getKeyData(forKey: "signed_pre_key") {
            signedPreKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: signedData)
        }

        if let preKeyData = storage.getKeyData(forKey: "pre_keys"),
           let decoded = try? JSONDecoder().decode([String: Data].self, from: preKeyData) {
            for (id, data) in decoded {
                preKeys[id] = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
            }
        }
    }
}

enum CryptoError: Error {
    case noKeys
    case invalidData
    case encryptionFailed
    case decryptionFailed
}
