import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class MessagesScreen extends StatelessWidget {
  final List<ChatConversation> conversations = [
    ChatConversation(
      id: '1',
      username: 'alice_wonder',
      userProfileImage: 'https://i.pravatar.cc/150?img=1',
      messages: [],
      lastMessage: 'That photo is amazing! 😍',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isUnread: true,
    ),
    ChatConversation(
      id: '2',
      username: 'bob_builder',
      userProfileImage: 'https://i.pravatar.cc/150?img=2',
      messages: [],
      lastMessage: 'See you tomorrow at the gym!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ChatConversation(
      id: '3',
      username: 'charlie_fit',
      userProfileImage: 'https://i.pravatar.cc/150?img=3',
      messages: [],
      lastMessage: 'Sent a reel',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('user_name', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.video_call_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          // Notes / Active users
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 20}'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text('user_$index', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Conversation List
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final chat = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(chat.userProfileImage),
                  ),
                  title: Text(chat.username, style: TextStyle(fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: chat.isUnread ? Colors.black : Colors.grey, fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatDetailScreen(conversation: chat)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final ChatConversation conversation;
  final TextEditingController _messageController = TextEditingController();

  ChatDetailScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 15, backgroundImage: NetworkImage(conversation.userProfileImage)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.username, style: const TextStyle(fontSize: 16)),
                const Text('Active now', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Example messages
                _buildMessageBubble('Hey! How are you?', false),
                _buildMessageBubble('I\'m good! Just saw your new post.', true),
                _buildMessageBubble('That photo is amazing! 😍', false),
              ],
            ),
          ),
          // Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), onPressed: () {}),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.mic_none, color: Colors.black), onPressed: () {}),
                IconButton(icon: const Icon(Icons.image_outlined, color: Colors.black), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
