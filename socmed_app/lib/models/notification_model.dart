enum NotificationType { like, comment, follow }

class NotificationItem {
  final String id;
  final String username;
  final String userProfileImage;
  final NotificationType type;
  final String? postImage;
  final String timeAgo;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.type,
    this.postImage,
    required this.timeAgo,
    this.isRead = false,
  });
}
