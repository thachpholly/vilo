import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
}

struct Message: Identifiable, Codable {
    let id: String
    let chatId: String
    let senderId: String
    let recipientId: String
    let text: String
    let imageUrl: String?
    let timestamp: Date
    var status: MessageStatus
    let isFromMe: Bool

    init(id: String, chatId: String, senderId: String, recipientId: String, text: String, imageUrl: String?, timestamp: Date, status: MessageStatus, isFromMe: Bool) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.recipientId = recipientId
        self.text = text
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.status = status
        self.isFromMe = isFromMe
    }
}

struct Chat: Identifiable, Codable {
    let id: String
    let recipientId: String
    let recipientName: String
    let recipientAvatar: String?
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var isOnline: Bool

    init(id: String, recipientId: String, recipientName: String, recipientAvatar: String?, lastMessage: String, lastMessageTime: Date, unreadCount: Int, isOnline: Bool) {
        self.id = id
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.recipientAvatar = recipientAvatar
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.isOnline = isOnline
    }

    static var sample: Chat {
        Chat(
            id: "1",
            recipientId: "user123",
            recipientName: "Minh Anh",
            recipientAvatar: nil,
            lastMessage: "Hello! How are you?",
            lastMessageTime: Date(),
            unreadCount: 2,
            isOnline: true
        )
    }
}

// MARK: - WebSocket Message

struct WSChatMessage: Codable {
    let id: String
    let from: String
    let to: String
    let encryptedContent: String
    let timestamp: Int64
    let type: String
}

enum WSMessageType: String, Codable {
    case text
    case image
}
