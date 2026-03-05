class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
}

class ChatConversation {
  final String id;
  final String username;
  final String userProfileImage;
  final List<ChatMessage> messages;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;

  ChatConversation({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.messages,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isUnread = false,
  });
}
