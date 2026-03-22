import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

  final List<ChatConversation> conversations = [
    ChatConversation(
      id: '1',
      username: 'alice',
      userProfileImage: 'https://i.pravatar.cc/150?img=1',
      messages: [],
      lastMessage: 'That photo is amazing! 😍',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isUnread: true,
    ),
    ChatConversation(
      id: '2',
      username: 'bob',
      userProfileImage: 'https://i.pravatar.cc/150?img=2',
      messages: [],
      lastMessage: 'See you tomorrow at the gym!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      isUnread: false,
    ),
  ];

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
                onPressed: () {
                  final selected = availableUsers.where((u) => u.isSelected).toList();
                  if (selected.isEmpty) return;
                  setState(() {
                    conversations.insert(0, ChatConversation(
                      id: DateTime.now().toString(),
                      username: _groupNameController.text.isEmpty
                          ? selected.map((u) => u.name).join(", ")
                          : _groupNameController.text,
                      userProfileImage: 'https://cdn-icons-png.flaticon.com/512/3211/3211463.png',
                      messages: [],
                      lastMessage: 'Group created',
                      lastMessageTime: DateTime.now(),
                    ));
                    for (var u in availableUsers) { u.isSelected = false; }
                  });
                  Navigator.pop(context);
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
      // Idinagdag ang bottom border para pareho sa Home Screen
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
                  // Ginamit ang mas magandang StoryViewScreen para consistent
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
    final visible = conversations.where((c) => !c.isArchived && c.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
              archivedConversations: conversations.where((c) => c.isArchived).toList(),
              onUnarchive: (chat) => setState(() => chat.isArchived = false),
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
              itemCount: visible.length + 1, // +1 for AI TALK BUDDY
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            conversation: ChatConversation(
                              id: 'ai_buddy',
                              username: 'AI TALK BUDDY',
                              userProfileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
                              messages: [],
                              lastMessage: 'Your buddy for every chat.',
                              lastMessageTime: DateTime.now(),
                            ),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                      ),
                      child: const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/4712/4712035.png'),
                      ),
                    ),
                    title: const Text('AI TALK BUDDY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                    subtitle: const Text('Your buddy for every chat.', style: TextStyle(color: Colors.black54, fontSize: 13)),
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
                      CustomSlidableAction(onPressed: (_) => setState(() => chat.isMuted = !chat.isMuted), backgroundColor: Colors.transparent, child: Icon(chat.isMuted ? Icons.notifications_off : Icons.notifications_none, color: Colors.purple, size: 22)),
                      CustomSlidableAction(onPressed: (_) => setState(() => chat.isArchived = true), backgroundColor: Colors.transparent, child: const Icon(Icons.archive_outlined, color: Colors.black, size: 22)),
                      CustomSlidableAction(onPressed: (_) => setState(() => conversations.remove(chat)), backgroundColor: Colors.transparent, child: const Icon(Icons.delete_outline, color: Colors.red, size: 22)),
                    ],
                  ),
                  child: ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(conversation: chat))),
                    leading: CircleAvatar(backgroundImage: NetworkImage(chat.userProfileImage)),
                    title: Text(chat.username, style: TextStyle(fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(chat.lastMessage),
                    trailing: chat.isUnread ? const Icon(Icons.circle, size: 10, color: Colors.blue) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatUser {
  final String name;
  final String imageUrl;
  bool isSelected;
  bool hasStory;
  ChatUser({required this.name, required this.imageUrl, this.isSelected = false, this.hasStory = false});
}
