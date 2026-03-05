import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      username: 'alice_wonder',
      userProfileImage: 'https://i.pravatar.cc/150?img=1',
      type: NotificationType.like,
      postImage: 'https://picsum.photos/100/100?random=1',
      timeAgo: '2m',
    ),
    NotificationItem(
      id: '2',
      username: 'bob_builder',
      userProfileImage: 'https://i.pravatar.cc/150?img=2',
      type: NotificationType.follow,
      timeAgo: '1h',
    ),
    NotificationItem(
      id: '3',
      username: 'charlie_fit',
      userProfileImage: 'https://i.pravatar.cc/150?img=3',
      type: NotificationType.comment,
      postImage: 'https://picsum.photos/100/100?random=3',
      timeAgo: '5h',
    ),
  ];

  void _handleFollow(int index) {
    setState(() {
      // Toggle follow state logic can be added here
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are now following ${_notifications[index].username}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(notification.userProfileImage),
            ),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: notification.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _getNotificationText(notification.type)),
                  TextSpan(
                    text: ' ${notification.timeAgo}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            trailing: _getNotificationTrailing(notification, index),
            onTap: () {
              // Logic to open the specific post or profile
            },
          );
        },
      ),
    );
  }

  String _getNotificationText(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return ' liked your post.';
      case NotificationType.comment:
        return ' commented on your post.';
      case NotificationType.follow:
        return ' started following you.';
    }
  }

  Widget _getNotificationTrailing(NotificationItem item, int index) {
    if (item.type == NotificationType.follow) {
      return SizedBox(
        width: 90,
        height: 30,
        child: ElevatedButton(
          onPressed: () => _handleFollow(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (item.postImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(item.postImage!, width: 40, height: 40, fit: BoxFit.cover),
      );
    }
    return const SizedBox.shrink();
  }
}
