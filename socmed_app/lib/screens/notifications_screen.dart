import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _acceptRequest(String notificationId, Map<String, dynamic> data) async {
    if (currentUser == null) return;

    final String fromId = data['fromId'];
    
    // 1. Add to followers/following
    final batch = FirebaseFirestore.instance.batch();
    
    // Current user follows back (optional, but usually "Accept" means both follow each other in some apps, 
    // or just "Allow" them to follow you). Let's make it a mutual follow.
    
    batch.set(FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('followers').doc(fromId), {'timestamp': FieldValue.serverTimestamp()});
    batch.set(FirebaseFirestore.instance.collection('users').doc(fromId).collection('following').doc(currentUser!.uid), {'timestamp': FieldValue.serverTimestamp()});

    // 2. Update notification status
    batch.update(FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('notifications').doc(notificationId), {
      'status': 'accepted',
      'message': 'is now following you.',
      'type': 'follow', // Change type so it looks like a normal follow now
    });

    await batch.commit();
  }

  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('notifications').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Please log in")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final String type = data['type'] ?? '';
              
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(data['fromImage'] ?? 'https://i.pravatar.cc/150')),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(text: data['fromName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' ${data['message']}'),
                    ],
                  ),
                ),
                trailing: type == 'follow_request' && data['status'] == 'pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptRequest(docId, data),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 30)),
                          child: const Text('Accept', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          onPressed: () => _deleteNotification(docId),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 30)),
                          child: const Text('Delete', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  : IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => _deleteNotification(docId)),
              );
            },
          );
        },
      ),
    );
  }
}
