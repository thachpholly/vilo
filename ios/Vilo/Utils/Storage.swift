import Foundation
import Security

/// Local storage manager for VILO
/// Uses UserDefaults for non-sensitive data and Keychain for sensitive data
class Storage {
    static let shared = Storage()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let keychainService = "app.vilo.keychain"

    private init() {}

    // MARK: - Token Management

    func saveToken(_ token: String) {
        saveToKeychain(token, forKey: "auth_token")
    }

    func getToken() -> String? {
        return getFromKeychain(forKey: "auth_token")
    }

    // MARK: - User Management

    func saveUser(_ user: User) {
        if let data = try? encoder.encode(user) {
            defaults.set(data, forKey: "current_user")
        }
    }

    func getUser() -> User? {
        guard let data = defaults.data(forKey: "current_user") else { return nil }
        return try? decoder.decode(User.self, from: data)
    }

    func getCurrentUserId() -> String? {
        return getUser()?.id
    }

    // MARK: - Chat Management

    func saveChat(_ chat: Chat) {
        var chats = getChats()
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        } else {
            chats.insert(chat, at: 0)
        }

        if let data = try? encoder.encode(chats) {
            defaults.set(data, forKey: "chats")
        }
    }

    func getChats() -> [Chat] {
        guard let data = defaults.data(forKey: "chats") else { return [] }
        return (try? decoder.decode([Chat].self, from: data)) ?? []
    }

    func deleteChat(id: String) {
        var chats = getChats()
        chats.removeAll { $0.id == id }

        if let data = try? encoder.encode(chats) {
            defaults.set(data, forKey: "chats")
        }

        // Also delete messages
        defaults.removeObject(forKey: "messages_\(id)")
    }

    // MARK: - Message Management

    func saveMessage(_ message: Message) {
        var messages = getMessages(for: message.chatId)
        messages.append(message)

        if let data = try? encoder.encode(messages) {
            defaults.set(data, forKey: "messages_\(message.chatId)")
        }
    }

    func getMessages(for chatId: String) -> [Message] {
        guard let data = defaults.data(forKey: "messages_\(chatId)") else { return [] }
        return (try? decoder.decode([Message].self, from: data)) ?? []
    }

    func updateMessageStatus(id: String, status: MessageStatus) {
        // Find and update message across all chats
        let chats = getChats()
        for chat in chats {
            var messages = getMessages(for: chat.id)
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].status = status
                if let data = try? encoder.encode(messages) {
                    defaults.set(data, forKey: "messages_\(chat.id)")
                }
                break
            }
        }
    }

    // MARK: - Key Storage (Keychain)

    func saveKeyData(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        SecItemAdd(query as CFDictionary, nil)
    }

    func getKeyData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        saveKeyData(data, forKey: key)
    }

    private func getFromKeychain(forKey key: String) -> String? {
        guard let data = getKeyData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Clear All

    func clearAll() {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)

        // Clear Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
    }
}
