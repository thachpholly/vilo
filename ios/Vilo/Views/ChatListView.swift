import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var showNewChat = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viloBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.viloTextSecondary)

                        TextField("Search chats", text: $searchText)
                            .foregroundColor(.viloTextPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.viloSurface)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Chat List
                    if filteredChats.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredChats) { chat in
                                    NavigationLink(destination: ChatView(chat: chat)) {
                                        ChatRowView(chat: chat)
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                        .background(Color.viloBorder)
                                        .padding(.leading, 76)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Profile action
                    }) {
                        if let avatar = authViewModel.currentUser?.avatar {
                            AsyncImage(url: URL(string: avatar)) { image in
                                image.resizable()
                            } placeholder: {
                                Circle()
                                    .fill(Color.viloSurface)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.viloTextSecondary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewChat = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundColor(.viloPrimary)
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
        }
        .tint(.viloPrimary)
    }

    private var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chatViewModel.chats
        }
        return chatViewModel.chats.filter {
            $0.recipientName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.viloTextSecondary)

            Text("No chats yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.viloTextPrimary)

            Text("Start a conversation by tapping\nthe compose button")
                .font(.subheadline)
                .foregroundColor(.viloTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showNewChat = true
            }) {
                Text("Start Chat")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.viloPrimary)
                    .cornerRadius(24)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

struct ChatRowView: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let avatar = chat.recipientAvatar {
                    AsyncImage(url: URL(string: avatar)) { image in
                        image.resizable()
                    } placeholder: {
                        Circle()
                            .fill(Color.viloSurface)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.viloSurface)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(chat.recipientName.prefix(1).uppercased())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.viloTextSecondary)
                        )
                }

                // Online indicator
                if chat.isOnline {
                    Circle()
                        .fill(Color.viloOnline)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.viloBackground, lineWidth: 2)
                        )
                }
            }

            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.recipientName)
                        .font(.headline)
                        .foregroundColor(.viloTextPrimary)

                    Spacer()

                    Text(chat.lastMessageTime.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.viloTextSecondary)
                }

                HStack {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.viloTextSecondary)
                        .lineLimit(1)

                    Spacer()

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.viloBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.viloSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var phoneNumber = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viloBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Enter phone number to start chatting")
                        .font(.subheadline)
                        .foregroundColor(.viloTextSecondary)
                        .padding(.top, 16)

                    HStack(spacing: 12) {
                        Text("🇻🇳 +84")
                            .foregroundColor(.viloTextPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .background(Color.viloSurface)
                            .cornerRadius(12)

                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .foregroundColor(.viloTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.viloSurface)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.viloTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        // Start chat
                        dismiss()
                    }
                    .foregroundColor(.viloPrimary)
                    .disabled(phoneNumber.count < 9)
                }
            }
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(AuthViewModel())
        .environmentObject(ChatViewModel())
}
