import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../widgets/story_circle.dart';
import 'chat_detail_screen.dart';
import 'archived_chats_screen.dart';
import 'story_view_screen.dart';

class MessagesScreen extends StatefulWidget {
  final List<Map<String, String>> stories;
  const MessagesScreen({super.key, this.stories = const []});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  String _searchQuery = "";

  final List<ChatUser> availableUsers = [
    ChatUser(name: "Charlie", imageUrl: "https://i.pravatar.cc/150?img=3"),
    ChatUser(name: "David", imageUrl: "https://i.pravatar.cc/150?img=4"),
    ChatUser(name: "Eve", imageUrl: "https://i.pravatar.cc/150?img=5"),
  ];

  void _showUserSelection() {
    _groupNameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("New Group Chat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                    hintText: "Group Name",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    return CheckboxListTile(
                      secondary: CircleAvatar(backgroundImage: NetworkImage(user.imageUrl)),
                      title: Text(user.name),
                      value: user.isSelected,
                      onChanged: (val) => setModalState(() => user.isSelected = val!),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final selected = availableUsers.where((u) => u.isSelected).toList();
                  if (selected.isEmpty) return;
                  
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;

                  final groupName = _groupNameController.text.isEmpty
                      ? selected.map((u) => u.name).join(", ")
                      : _groupNameController.text;

                  await FirebaseFirestore.instance.collection('chats').add({
                    'participants': [currentUser.uid, ...selected.map((u) => u.name)], 
                    'names': {
                      currentUser.uid: currentUser.displayName ?? 'Me',
                      for (var u in selected) u.name: u.name,
                    },
                    'images': {
                      currentUser.uid: currentUser.photoURL ?? '',
                      for (var u in selected) u.name: u.imageUrl,
                    },
                    'lastMessage': 'Group created',
                    'lastTimestamp': FieldValue.serverTimestamp(),
                    'isGroup': true,
                    'groupName': groupName,
                  });

                  for (var u in availableUsers) { u.isSelected = false; }
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                child: const Text("Create Group", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorySection() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: widget.stories, 
                    initialIndex: index, 
                    onDirectMessage: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            child: StoryCircle(
              username: story['username']!,
              imageUrl: story['imageUrl']!,
              isMe: index == 0,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: currentUser == null 
          ? const Stream.empty() 
          : FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        List<ChatConversation> allConversations = [];
        
        if (snapshot.hasData) {
          allConversations = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUid = participants.firstWhere((id) => id != currentUser?.uid, orElse: () => '');
            
            final names = data['names'] as Map<String, dynamic>? ?? {};
            final images = data['images'] as Map<String, dynamic>? ?? {};
            
            String username = names[otherUid] ?? 'Unknown';
            String userProfileImage = images[otherUid] ?? 'https://i.pravatar.cc/150';
            
            if (data['isGroup'] == true) {
              username = data['groupName'] ?? username;
              userProfileImage = 'https://cdn-icons-png.flaticon.com/512/3211/3211463.png';
            } else if (otherUid == 'ai_buddy') {
              username = 'AI TALK BUDDY';
              userProfileImage = 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png';
            }

            return ChatConversation(
              id: doc.id,
              username: username,
              userProfileImage: userProfileImage,
              messages: [],
              lastMessage: data['lastMessage'] ?? '',
              lastMessageTime: (data['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isArchived: data['isArchived'] ?? false,
              isMuted: data['isMuted'] ?? false,
              isUnread: false, 
            );
          }).toList();
        }

        final filtered = allConversations.where((c) => c.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        // Use where().firstOrNull pattern for better safety in Dart
        final aiChatList = filtered.where((c) => c.id.contains('ai_buddy')).toList();
        ChatConversation? aiChatFromDB = aiChatList.isNotEmpty ? aiChatList.first : null;
        
        final visible = filtered.where((c) => !c.isArchived && !c.id.contains('ai_buddy')).toList();
        visible.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        final archived = filtered.where((c) => c.isArchived).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Direct', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: Colors.black, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArchivedChatsScreen(
                  archivedConversations: archived,
                  onUnarchive: (chat) => FirebaseFirestore.instance.collection('chats').doc(chat.id).update({'isArchived': false}),
                ))),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showUserSelection,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search), border: InputBorder.none),
                  ),
                ),
              ),
              _buildStorySection(),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: visible.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatDetailScreen(
                            contactName: 'AI TALK BUDDY',
                            contactImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
                            contactUid: 'ai_buddy',
                          )));
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.purple, Colors.blue])),
                          child: const CircleAvatar(radius: 25, backgroundColor: Colors.white, backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/4712/4712035.png')),
                        ),
                        title: const Text('AI TALK BUDDY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                        subtitle: Text(aiChatFromDB?.lastMessage ?? 'Your buddy for every chat.', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        tileColor: Colors.purple.withOpacity(0.05),
                      );
                    }

                    final chat = visible[index - 1];
                    return Slidable(
                      key: Key(chat.id),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.3,
                        children: [
                          CustomSlidableAction(onPressed: (_) => FirebaseFirestore.instance.collection('chats').doc(chat.id).update({'isMuted': !chat.isMuted}), backgroundColor: Colors.transparent, child: Icon(chat.isMuted ? Icons.notifications_off : Icons.notifications_none, color: Colors.purple, size: 22)),
                          CustomSlidableAction(onPressed: (_) => FirebaseFirestore.instance.collection('chats').doc(chat.id).update({'isArchived': true}), backgroundColor: Colors.transparent, child: const Icon(Icons.archive_outlined, color: Colors.black, size: 22)),
                          CustomSlidableAction(onPressed: (_) => FirebaseFirestore.instance.collection('chats').doc(chat.id).delete(), backgroundColor: Colors.transparent, child: const Icon(Icons.delete_outline, color: Colors.red, size: 22)),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          final participants = chat.id.contains('_') ? chat.id.split('_') : [chat.id];
                          final otherUid = participants.firstWhere((id) => id != currentUser?.uid, orElse: () => chat.id);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(
                            contactName: chat.username,
                            contactImage: chat.userProfileImage,
                            contactUid: otherUid,
                            chatId: chat.id,
                          )));
                        },
                        leading: CircleAvatar(backgroundImage: NetworkImage(chat.userProfileImage)),
                        title: Text(chat.username, style: TextStyle(fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: chat.isUnread ? const Icon(Icons.circle, size: 10, color: Colors.blue) : Text(_formatTime(chat.lastMessageTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) return "${time.day}/${time.month}";
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class ChatUser {
  final String name;
  final String imageUrl;
  bool isSelected;
  bool hasStory;
  ChatUser({required this.name, required this.imageUrl, this.isSelected = false, this.hasStory = false});
}
