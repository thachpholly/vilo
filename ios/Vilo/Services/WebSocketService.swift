import Foundation

class WebSocketService: NSObject {
    static let shared = WebSocketService()

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession!
    private var token: String?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    // Callbacks
    var onMessage: ((WSChatMessage) -> Void)?
    var onTyping: ((String) -> Void)?
    var onDelivered: ((String) -> Void)?
    var onRead: (([String]) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?

    private override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }

    // MARK: - Connection

    func connect(token: String) {
        self.token = token

        #if DEBUG
        let urlString = "ws://localhost:3000/ws"
        #else
        let urlString = "wss://api.vilo.app/ws"
        #endif

        guard let url = URL(string: urlString) else { return }

        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        // Authenticate
        authenticate()

        // Start receiving messages
        receiveMessage()

        // Start ping-pong
        startPingPong()
    }

    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        token = nil
        onConnectionStateChanged?(false)
    }

    private func authenticate() {
        guard let token = token else { return }

        let authMessage: [String: Any] = [
            "type": "auth",
            "payload": ["token": token]
        ]

        send(authMessage)
    }

    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts, let token = token else {
            return
        }

        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2.0 // Exponential backoff

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect(token: token)
        }
    }

    // MARK: - Send Messages

    func sendMessage(to recipientId: String, encryptedContent: String, type: WSMessageType) {
        let message: [String: Any] = [
            "type": "message",
            "payload": [
                "to": recipientId,
                "encryptedContent": encryptedContent,
                "type": type.rawValue
            ]
        ]
        send(message)
    }

    func sendTyping(to recipientId: String) {
        let message: [String: Any] = [
            "type": "typing",
            "payload": ["to": recipientId]
        ]
        send(message)
    }

    func sendDelivered(to recipientId: String, messageId: String) {
        let message: [String: Any] = [
            "type": "delivered",
            "payload": [
                "to": recipientId,
                "messageId": messageId
            ]
        ]
        send(message)
    }

    func sendRead(to recipientId: String, messageIds: [String]) {
        let message: [String: Any] = [
            "type": "read",
            "payload": [
                "to": recipientId,
                "messageIds": messageIds
            ]
        ]
        send(message)
    }

    private func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let string = String(data: data, encoding: .utf8) else {
            return
        }

        webSocket?.send(.string(string)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    // MARK: - Receive Messages

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                // Continue receiving
                self?.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.isConnected = false
                self?.onConnectionStateChanged?(false)
                self?.reconnect()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "authenticated":
            isConnected = true
            reconnectAttempts = 0
            onConnectionStateChanged?(true)

        case "message":
            if let payload = json["payload"] as? [String: Any],
               let payloadData = try? JSONSerialization.data(withJSONObject: payload),
               let chatMessage = try? JSONDecoder().decode(WSChatMessage.self, from: payloadData) {
                onMessage?(chatMessage)
            }

        case "typing":
            if let payload = json["payload"] as? [String: Any],
               let from = payload["from"] as? String {
                onTyping?(from)
            }

        case "delivered":
            if let payload = json["payload"] as? [String: Any],
               let messageId = payload["messageId"] as? String {
                onDelivered?(messageId)
            }

        case "read":
            if let payload = json["payload"] as? [String: Any],
               let messageIds = payload["messageIds"] as? [String] {
                onRead?(messageIds)
            }

        case "sent":
            // Message confirmed sent
            break

        case "queued":
            // Message queued for offline delivery
            break

        case "pong":
            // Ping response
            break

        default:
            print("Unknown message type: \(type)")
        }
    }

    // MARK: - Ping-Pong

    private func startPingPong() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        let message: [String: Any] = ["type": "ping"]
        send(message)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed: \(closeCode)")
        isConnected = false
        onConnectionStateChanged?(false)
        reconnect()
    }
}
