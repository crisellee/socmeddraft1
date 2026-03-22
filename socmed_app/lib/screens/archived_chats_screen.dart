import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/chat_model.dart';

class ArchivedChatsScreen extends StatefulWidget {
  final List<ChatConversation> archivedConversations;
  final Function(ChatConversation) onUnarchive;

  const ArchivedChatsScreen({super.key, required this.archivedConversations, required this.onUnarchive});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Archived Chats', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
      ),
      body: widget.archivedConversations.isEmpty
          ? const Center(child: Text("No archived chats"))
          : ListView.builder(
        itemCount: widget.archivedConversations.length,
        itemBuilder: (context, index) {
          final chat = widget.archivedConversations[index];
          return Slidable(
            key: Key(chat.id),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.15,
              children: [
                CustomSlidableAction(
                  onPressed: (context) {
                    setState(() {
                      widget.onUnarchive(chat);
                      widget.archivedConversations.removeAt(index);
                    });
                  },
                  backgroundColor: Colors.transparent,
                  child: const Icon(Icons.unarchive_outlined, color: Colors.blue, size: 24),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(chat.userProfileImage)),
              title: Text(chat.username),
              subtitle: const Text("Swipe to unarchive"),
            ),
          );
        },
      ),
    );
  }
}