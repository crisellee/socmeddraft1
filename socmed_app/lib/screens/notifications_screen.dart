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
    
    batch.set(FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('followers').doc(fromId), {'timestamp': FieldValue.serverTimestamp()});
    batch.set(FirebaseFirestore.instance.collection('users').doc(fromId).collection('following').doc(currentUser!.uid), {'timestamp': FieldValue.serverTimestamp()});

    // 2. Update notification status
    batch.update(FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('notifications').doc(notificationId), {
      'status': 'accepted',
      'message': 'is now following you.',
      'type': 'follow', 
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
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final String type = data['type'] ?? '';
              final String fromName = data['fromName']?.toString() ?? 'User';
              final String message = data['message']?.toString() ?? '';
              final String fromImage = data['fromImage']?.toString() ?? 'https://i.pravatar.cc/150';
              
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(fromImage)),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' '),
                      TextSpan(text: message),
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
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey), 
                      onPressed: () => _deleteNotification(docId)
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
