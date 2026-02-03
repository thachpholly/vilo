import Foundation

struct User: Codable, Identifiable {
    let id: String
    let phone: String
    var name: String?
    var avatar: String?
    var isNewUser: Bool
    var createdAt: Date?

    init(id: String, phone: String, name: String? = nil, avatar: String? = nil, isNewUser: Bool = false, createdAt: Date? = nil) {
        self.id = id
        self.phone = phone
        self.name = name
        self.avatar = avatar
        self.isNewUser = isNewUser
        self.createdAt = createdAt
    }
}

// MARK: - API Response Models

struct SendOTPResponse: Codable {
    let success: Bool
    let message: String
}

struct VerifyOTPResponse: Codable {
    let success: Bool
    let token: String
    let user: User
}

struct ProfileUpdateResponse: Codable {
    let success: Bool
    let user: User
}

// MARK: - Public Keys

struct PublicKeys: Codable {
    let identityKey: String
    let signedPreKey: String
    let preKeys: [String]
}

struct UserPublicKey: Codable {
    let userId: String
    let identityKey: String
    let signedPreKey: String
    let preKey: String
}
