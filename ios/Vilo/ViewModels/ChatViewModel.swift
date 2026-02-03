import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messagesByChat: [String: [Message]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private let wsService = WebSocketService.shared
    private let cryptoService = CryptoService.shared
    private let storage = Storage.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupWebSocketHandlers()
        loadLocalChats()
    }

    /// Setup WebSocket message handlers
    private func setupWebSocketHandlers() {
        wsService.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.handleIncomingMessage(message)
            }
        }

        wsService.onTyping = { [weak self] senderId in
            Task { @MainActor in
                self?.handleTyping(from: senderId)
            }
        }

        wsService.onDelivered = { [weak self] messageId in
            Task { @MainActor in
                self?.updateMessageStatus(id: messageId, status: .delivered)
            }
        }

        wsService.onRead = { [weak self] messageIds in
            Task { @MainActor in
                for id in messageIds {
                    self?.updateMessageStatus(id: id, status: .read)
                }
            }
        }
    }

    /// Load chats from local storage
    private func loadLocalChats() {
        chats = storage.getChats()

        for chat in chats {
            messagesByChat[chat.id] = storage.getMessages(for: chat.id)
        }
    }

    /// Get messages for a specific chat
    func messages(for chatId: String) -> [Message] {
        return messagesByChat[chatId] ?? []
    }

    /// Send a text message
    func sendMessage(text: String, to recipientId: String) async {
        guard let chat = chats.first(where: { $0.recipientId == recipientId }) else {
            // Create new chat if doesn't exist
            await startNewChat(with: recipientId, firstMessage: text)
            return
        }

        await sendMessageToChat(chat: chat, text: text)
    }

    /// Send a message to existing chat
    private func sendMessageToChat(chat: Chat, text: String) async {
        // Create local message
        let message = Message(
            id: UUID().uuidString,
            chatId: chat.id,
            senderId: storage.getCurrentUserId() ?? "",
            recipientId: chat.recipientId,
            text: text,
            imageUrl: nil,
            timestamp: Date(),
            status: .sending,
            isFromMe: true
        )

        // Add to local messages
        if messagesByChat[chat.id] == nil {
            messagesByChat[chat.id] = []
        }
        messagesByChat[chat.id]?.append(message)
        storage.saveMessage(message)

        // Update chat's last message
        updateChatLastMessage(chatId: chat.id, message: text)

        do {
            // Encrypt message
            let encryptedContent = try await cryptoService.encrypt(text, for: chat.recipientId)

            // Send via WebSocket
            wsService.sendMessage(
                to: chat.recipientId,
                encryptedContent: encryptedContent,
                type: .text
            )

            // Update status to sent
            updateMessageStatus(id: message.id, status: .sent)
        } catch {
            // Handle encryption/send failure
            updateMessageStatus(id: message.id, status: .sending)
            errorMessage = "Failed to send message"
        }
    }

    /// Start a new chat
    private func startNewChat(with recipientId: String, firstMessage: String) async {
        do {
            // Find user by ID or phone
            let recipient = try await apiService.findUser(by: recipientId)

            // Create new chat
            let chat = Chat(
                id: UUID().uuidString,
                recipientId: recipient.id,
                recipientName: recipient.name ?? recipient.phone,
                recipientAvatar: recipient.avatar,
                lastMessage: firstMessage,
                lastMessageTime: Date(),
                unreadCount: 0,
                isOnline: false
            )

            chats.insert(chat, at: 0)
            storage.saveChat(chat)

            await sendMessageToChat(chat: chat, text: firstMessage)
        } catch {
            errorMessage = "User not found"
        }
    }

    /// Handle incoming message from WebSocket
    private func handleIncomingMessage(_ wsMessage: WSChatMessage) {
        Task {
            do {
                // Decrypt message
                let text = try await cryptoService.decrypt(wsMessage.encryptedContent, from: wsMessage.from)

                // Find or create chat
                var chat = chats.first { $0.recipientId == wsMessage.from }

                if chat == nil {
                    // Fetch sender info and create chat
                    let sender = try await apiService.findUser(by: wsMessage.from)
                    chat = Chat(
                        id: UUID().uuidString,
                        recipientId: sender.id,
                        recipientName: sender.name ?? sender.phone,
                        recipientAvatar: sender.avatar,
                        lastMessage: text,
                        lastMessageTime: Date(),
                        unreadCount: 1,
                        isOnline: true
                    )
                    chats.insert(chat!, at: 0)
                    storage.saveChat(chat!)
                }

                // Create message
                let message = Message(
                    id: wsMessage.id,
                    chatId: chat!.id,
                    senderId: wsMessage.from,
                    recipientId: storage.getCurrentUserId() ?? "",
                    text: text,
                    imageUrl: wsMessage.type == "image" ? text : nil,
                    timestamp: Date(timeIntervalSince1970: TimeInterval(wsMessage.timestamp) / 1000),
                    status: .delivered,
                    isFromMe: false
                )

                // Add to messages
                if messagesByChat[chat!.id] == nil {
                    messagesByChat[chat!.id] = []
                }
                messagesByChat[chat!.id]?.append(message)
                storage.saveMessage(message)

                // Update chat
                updateChatLastMessage(chatId: chat!.id, message: text)
                incrementUnreadCount(chatId: chat!.id)

                // Send delivered receipt
                wsService.sendDelivered(to: wsMessage.from, messageId: wsMessage.id)
            } catch {
                print("Failed to process incoming message: \(error)")
            }
        }
    }

    /// Handle typing indicator
    private func handleTyping(from senderId: String) {
        // Update UI to show typing indicator
        // This could be published as a separate @Published property
    }

    /// Update message status
    private func updateMessageStatus(id: String, status: MessageStatus) {
        for (chatId, messages) in messagesByChat {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messagesByChat[chatId]?[index].status = status
                storage.updateMessageStatus(id: id, status: status)
                break
            }
        }
    }

    /// Update chat's last message
    private func updateChatLastMessage(chatId: String, message: String) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].lastMessage = message
            chats[index].lastMessageTime = Date()
            storage.saveChat(chats[index])

            // Move to top
            let chat = chats.remove(at: index)
            chats.insert(chat, at: 0)
        }
    }

    /// Increment unread count for chat
    private func incrementUnreadCount(chatId: String) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].unreadCount += 1
            storage.saveChat(chats[index])
        }
    }

    /// Mark chat as read
    func markAsRead(chatId: String) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            let chat = chats[index]
            chats[index].unreadCount = 0
            storage.saveChat(chats[index])

            // Send read receipts
            let messageIds = messagesByChat[chatId]?
                .filter { !$0.isFromMe && $0.status != .read }
                .map { $0.id } ?? []

            if !messageIds.isEmpty {
                wsService.sendRead(to: chat.recipientId, messageIds: messageIds)
            }
        }
    }

    /// Send typing indicator
    func sendTyping(to recipientId: String) {
        wsService.sendTyping(to: recipientId)
    }
}
