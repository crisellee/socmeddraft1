import 'dart:typed_data';

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? storyReplyImage;
  final Uint8List? fileBytes; // ✅ Para sa pagpapakita ng images sa Web
  final String? audioUrl;    // ✅ Link/Blob URL para sa voice message playback

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.storyReplyImage,
    this.fileBytes,
    this.audioUrl,
  });
}

class ChatConversation {
  final String id;
  final String username;
  final String userProfileImage;
  final String? storyImage;
  final List<ChatMessage> messages;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;

  // ✅ UI State fields
  bool isArchived;
  bool isMuted;

  ChatConversation({
    required this.id,
    required this.username,
    required this.userProfileImage,
    this.storyImage,
    required this.messages,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isUnread = false,
    this.isArchived = false, // Default: nakalitaw sa inbox
    this.isMuted = false,    // Default: may notification
  });
}