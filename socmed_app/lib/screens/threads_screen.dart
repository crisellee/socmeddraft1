import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';

class ThreadsScreen extends StatefulWidget {
  final List<Post> threads;

  const ThreadsScreen({super.key, required this.threads});

  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  final List<Post> _randomThreads = [
    Post(id: 'r1', username: 'daily_quotes', userProfileImage: 'https://i.pravatar.cc/150?img=1', caption: 'Your only limit is your mind. Keep pushing! ✨', timeAgo: '1h', postImageUrls: []),
    Post(id: 'r2', username: 'tech_insider', userProfileImage: 'https://i.pravatar.cc/150?img=2', caption: 'The new Flutter update is a game changer for web performance! 🚀', timeAgo: '3h', postImageUrls: []),
    Post(id: 'r3', username: 'chef_mike', userProfileImage: 'https://i.pravatar.cc/150?img=3', caption: 'Just perfected my adobo recipe. Who wants some? 🍲', timeAgo: '5h', postImageUrls: []),
    Post(id: 'r4', username: 'travel_junkie', userProfileImage: 'https://i.pravatar.cc/150?img=4', caption: 'Missing the sunsets in Siargao. Take me back! 🌅', timeAgo: '8h', postImageUrls: []),
    Post(id: 'r5', username: 'fitness_bro', userProfileImage: 'https://i.pravatar.cc/150?img=5', caption: 'Consistency over intensity. Get those gains! 💪', timeAgo: '12h', postImageUrls: []),
    Post(id: 'r6', username: 'study_vibes', userProfileImage: 'https://i.pravatar.cc/150?img=6', caption: 'Deep work session starting now. 📖☕', timeAgo: '1d', postImageUrls: []),
    Post(id: 'r7', username: 'gaming_news', userProfileImage: 'https://i.pravatar.cc/150?img=7', caption: 'GTA VI trailer release date might be closer than we think! 🎮', timeAgo: '1d', postImageUrls: []),
    Post(id: 'r8', username: 'minimalist_life', userProfileImage: 'https://i.pravatar.cc/150?img=8', caption: 'Less is more. Clearing out my workspace today. ☁️', timeAgo: '2d', postImageUrls: []),
  ];

  late List<Post> _allThreads;
  final Map<String, String> _threadReactions = {}; 
  OverlayEntry? _reactionOverlay;

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️'},
    {'name': 'Haha', 'icon': '😆'},
    {'name': 'Wow', 'icon': '😮'},
    {'name': 'Sad', 'icon': '😢'},
    {'name': 'Angry', 'icon': '😡'},
  ];

  @override
  void initState() {
    super.initState();
    _allThreads = [...widget.threads, ..._randomThreads];
  }

  @override
  void didUpdateWidget(ThreadsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.threads != oldWidget.threads) {
      setState(() {
        final existingIds = _allThreads.map((t) => t.id).toSet();
        final newThreads = widget.threads.where((t) => !existingIds.contains(t.id)).toList();
        _allThreads.insertAll(0, newThreads);
      });
    }
  }

  void _showReactionPopup(BuildContext context, GlobalKey key, String threadId) {
    if (_reactionOverlay != null) return;

    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    _reactionOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideReactionPopup,
        child: Stack(
          children: [
            Positioned(
              top: position.dy - 60,
              left: position.dx,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactionsList.map((r) => GestureDetector(
                      onTap: () {
                        setState(() => _threadReactions[threadId] = r['name']!);
                        _hideReactionPopup();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(r['icon']!, style: const TextStyle(fontSize: 24)),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_reactionOverlay!);
  }

  void _hideReactionPopup() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  Widget _getReactionIcon(String threadId) {
    String reaction = _threadReactions[threadId] ?? 'None';
    if (reaction == 'None') return const Icon(Icons.favorite_border, size: 22);
    if (reaction == 'Love') return const Icon(Icons.favorite, size: 22, color: Colors.red);
    
    final reactData = reactionsList.firstWhere((r) => r['name'] == reaction, orElse: () => reactionsList[0]);
    return Text(reactData['icon']!, style: const TextStyle(fontSize: 18));
  }

  void _showCommentSheet(Post thread) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const Text('Replies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Expanded(
                  child: thread.comments.isEmpty
                      ? const Center(child: Text("No replies yet", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: thread.comments.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: const CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                            title: const Text('kriselz_', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(thread.comments[i]),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Add a reply...', border: InputBorder.none))),
                    TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() => thread.comments.add(controller.text));
                          setModalState(() {});
                          controller.clear();
                        }
                      },
                      child: const Text('Post', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(Post thread) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            if (thread.username == 'kriselz_')
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Thread', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _allThreads.remove(thread));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thread deleted.')));
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred, color: Colors.red), 
              title: const Text('Report', style: TextStyle(color: Colors.red)), 
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported.')));
              }
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined), 
              title: const Text('Not Interested'), 
              onTap: () {
                Navigator.pop(context);
                setState(() => _allThreads.remove(thread));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post hidden.')));
              }
            ),
            ListTile(
              leading: const Icon(Icons.link), 
              title: const Text('Copy Link'), 
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: "Thread by ${thread.username}: ${thread.caption}"));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              }
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined), 
              title: const Text('Share to...'),
              onTap: () {
                Navigator.pop(context);
                Share.share("${thread.username}: ${thread.caption}");
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Threads', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 26)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _allThreads.isEmpty
              ? const Center(child: Text("No threads yet. Share your thoughts!", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _allThreads.length,
                  itemBuilder: (context, index) {
                    final thread = _allThreads[index];
                    final GlobalKey reactionKey = GlobalKey();

                    return Column(
                      children: [
                        ListTile(
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: CircleAvatar(radius: 22, backgroundImage: NetworkImage(thread.userProfileImage)),
                          title: Row(
                            children: [
                              Text(thread.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              if (thread.username != 'kriselz_')
                                GestureDetector(
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Following ${thread.username}'))),
                                  child: const Text('Follow', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              const Spacer(),
                              Text(thread.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 10),
                              GestureDetector(onTap: () => _showMoreOptions(thread), child: const Icon(Icons.more_horiz, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(thread.caption, style: const TextStyle(color: Colors.black, fontSize: 16, height: 1.4)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    GestureDetector(
                                      key: reactionKey,
                                      onLongPress: () => _showReactionPopup(context, reactionKey, thread.id),
                                      onTap: () {
                                        setState(() {
                                          if (_threadReactions[thread.id] == 'Love') {
                                            _threadReactions[thread.id] = 'None';
                                          } else {
                                            _threadReactions[thread.id] = 'Love';
                                          }
                                        });
                                      },
                                      child: _getReactionIcon(thread.id),
                                    ),
                                    const SizedBox(width: 25),
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 22),
                                      onPressed: () => _showCommentSheet(thread),
                                      constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 25),
                                    IconButton(
                                      icon: Icon(
                                        thread.isSaved ? Icons.bookmark : Icons.bookmark_border, 
                                        size: 22,
                                        color: thread.isSaved ? Colors.yellow[700] : Colors.black,
                                      ),
                                      onPressed: () {
                                        setState(() => thread.isSaved = !thread.isSaved);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(thread.isSaved ? 'Saved to bookmarks' : 'Removed from bookmarks')));
                                      },
                                      constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 25),
                                    IconButton(
                                      icon: const Icon(Icons.send_outlined, size: 22),
                                      onPressed: () => Share.share("${thread.username}: ${thread.caption}"),
                                      constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
