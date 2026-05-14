import SwiftUI

struct ChatView: View {
    let project: Project

    @EnvironmentObject private var store: AppStore
    @State private var messages: [ChatMessage] = ChatMessage.previewSet
    @State private var draft: String = ""
    @State private var sending = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg).id(msg.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Reply to Claude…", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: sending ? "ellipsis" : "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || sending)
            }
            .padding(8)
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMessages() }
    }

    private func loadMessages() async {
        guard let pairing = store.pairing else { return }
        do {
            messages = try await MissionControlClient(server: pairing)
                .fetchMessages(sessionId: project.id)
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func send() async {
        guard let pairing = store.pairing else { return }
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        sending = true
        defer { sending = false }
        do {
            try await MissionControlClient(server: pairing)
                .send(sessionId: project.id, text: text)
            draft = ""
            await loadMessages()
        } catch {
            store.lastError = error.localizedDescription
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role.label)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(message.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding(10)
            .background(message.bubbleColor, in: .rect(cornerRadius: 12))
            if message.role != .user { Spacer(minLength: 40) }
        }
    }
}

private extension ChatMessage {
    var bubbleColor: Color {
        switch role {
        case .user: .blue.opacity(0.15)
        case .assistant: Color(.secondarySystemBackground)
        case .tool: Color(.tertiarySystemBackground)
        case .system: .yellow.opacity(0.12)
        }
    }
}

private extension ChatMessage.Role {
    var label: String {
        switch self {
        case .user: "you"
        case .assistant: "claude"
        case .tool: "tool"
        case .system: "system"
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(project: Project.previewSet[1])
            .environmentObject(AppStore())
    }
}
