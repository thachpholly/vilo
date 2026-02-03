import SwiftUI

struct ChatView: View {
    let chat: Chat
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showImagePicker = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.viloBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(chatViewModel.messages(for: chat.id)) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: chatViewModel.messages(for: chat.id).count) { _ in
                        if let lastMessage = chatViewModel.messages(for: chat.id).last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input Bar
                inputBar
            }
        }
        .navigationTitle(chat.recipientName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(chat.recipientName)
                        .font(.headline)
                        .foregroundColor(.viloTextPrimary)

                    if chat.isOnline {
                        Text("online")
                            .font(.caption)
                            .foregroundColor(.viloOnline)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            // Image picker would go here
            Text("Image Picker")
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.viloBorder)

            HStack(spacing: 12) {
                // Image button
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundColor(.viloTextSecondary)
                }

                // Text field
                HStack {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .foregroundColor(.viloTextPrimary)
                        .focused($isInputFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.viloSurface)
                .cornerRadius(20)

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(messageText.isEmpty ? .viloTextSecondary : .viloPrimary)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.viloBackground)
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            await chatViewModel.sendMessage(text: text, to: chat.recipientId)
            messageText = ""
        }
    }
}

struct MessageBubbleView: View {
    let message: Message

    private var isSent: Bool {
        message.isFromMe
    }

    var body: some View {
        HStack {
            if isSent { Spacer(minLength: 60) }

            VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                // Message content
                if let imageUrl = message.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.viloSurface)
                    }
                    .frame(maxWidth: 240, maxHeight: 320)
                    .cornerRadius(16)
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .foregroundColor(isSent ? .white : .viloTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSent ? Color.viloPrimary : Color.viloSurface)
                        .cornerRadius(18)
                }

                // Status and time
                HStack(spacing: 4) {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.viloTextSecondary)

                    if isSent {
                        statusIcon
                    }
                }
            }

            if !isSent { Spacer(minLength: 60) }
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                Image(systemName: "clock")
            case .sent:
                Image(systemName: "checkmark")
            case .delivered:
                Image(systemName: "checkmark.circle")
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.viloSecondary)
            }
        }
        .font(.caption2)
        .foregroundColor(.viloTextSecondary)
    }
}

#Preview {
    NavigationStack {
        ChatView(chat: Chat.sample)
            .environmentObject(ChatViewModel())
    }
}
