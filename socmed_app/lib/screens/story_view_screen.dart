import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Map<String, String>> stories;
  final int initialIndex;
  final VoidCallback onDirectMessage;

  const StoryViewScreen({super.key, required this.stories, required this.initialIndex, required this.onDirectMessage});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  final Map<int, String> _storyReactions = {}; 
  final GlobalKey _reactionButtonKey = GlobalKey();
  OverlayEntry? _reactionOverlay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️', 'color': '0xFFF44336'},
    {'name': 'Haha', 'icon': '😆', 'color': '0xFFFFC107'},
    {'name': 'Wow', 'icon': '😮', 'color': '0xFFFFC107'},
    {'name': 'Sad', 'icon': '😢', 'color': '0xFFFFC107'},
    {'name': 'Angry', 'icon': '😡', 'color': '0xFFE91E63'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _hideReactionPopup();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ SEND REPLY TO FIRESTORE
  Future<void> _sendStoryReply(String username, String text, String storyImage) async {
    final chatId = username.toLowerCase().replaceAll(' ', '_'); // Simple unique ID
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': 'currentUser',
      'text': text,
      'type': 'story_reply',
      'storyImage': storyImage, // Reference to the story being replied to
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update conversation metadata
    await _firestore.collection('conversations').doc(chatId).set({
      'lastMessage': 'Replied to your story',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'username': username,
    }, SetOptions(merge: true));
  }

  void _showReactionPopup(int index) {
    if (_reactionOverlay != null) return;

    final overlay = Overlay.of(context);
    final renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _reactionOverlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideReactionPopup,
        child: Stack(
          children: [
            Positioned(
              bottom: 70,
              right: 15,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactionsList.map((r) => _StoryReactionItem(
                      icon: r['icon']!,
                      name: r['name']!,
                      onTap: () async {
                        setState(() => _storyReactions[index] = r['name']!);
                        _hideReactionPopup();
                        
                        // Send reaction as a message
                        final story = widget.stories[index];
                        await _sendStoryReply(
                          story['username']!, 
                          "Reacted ${r['icon']} to your story", 
                          story['imageUrl']!
                        );
                      },
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_reactionOverlay!);
  }

  void _hideReactionPopup() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  Widget _getReactionIcon(int index) {
    String reaction = _storyReactions[index] ?? 'None';
    if (reaction == 'None') return const Icon(Icons.favorite_border, color: Colors.white, size: 28);
    if (reaction == 'Love') return const Icon(Icons.favorite, color: Colors.red, size: 28);
    final react = reactionsList.firstWhere((r) => r['name'] == reaction, orElse: () => reactionsList[0]);
    return Text(react['icon']!, style: const TextStyle(fontSize: 24));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network('https://picsum.photos/1080/1920?random=$index', fit: BoxFit.cover),
              Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.5), Colors.transparent, Colors.black.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Row(
                children: [
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {
                    if (index > 0) _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    else Navigator.pop(context);
                  })),
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {
                    if (index < widget.stories.length - 1) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    else Navigator.pop(context);
                  })),
                ],
              ),
              Positioned(
                top: 50, left: 10, right: 10,
                child: Column(
                  children: [
                    Row(children: List.generate(widget.stories.length, (i) => Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i == index ? Colors.white : Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(1)))))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(radius: 15, backgroundImage: NetworkImage(story['imageUrl']!)),
                        const SizedBox(width: 10),
                        Text(story['username']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20, left: 15, right: 15,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(25)),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (value) async {
                            if (value.isNotEmpty) {
                              await _sendStoryReply(story['username']!, value, story['imageUrl']!);
                              Navigator.pop(context);
                              widget.onDirectMessage();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replied to ${story['username']}')));
                            }
                          },
                          decoration: const InputDecoration(hintText: 'Send message', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      key: index == _pageController.page?.round() ? _reactionButtonKey : null,
                      onLongPress: () => _showReactionPopup(index),
                      onTap: () async {
                        setState(() => _storyReactions[index] = 'Love');
                        await _sendStoryReply(story['username']!, "❤️", story['imageUrl']!);
                      },
                      child: _getReactionIcon(index),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.send_outlined, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryReactionItem extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;
  const _StoryReactionItem({required this.icon, required this.name, required this.onTap});
  @override
  State<_StoryReactionItem> createState() => _StoryReactionItemState();
}

class _StoryReactionItemState extends State<_StoryReactionItem> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isHovered ? 1.3 : 1.0,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), child: Text(widget.icon, style: const TextStyle(fontSize: 28))),
        ),
      ),
    );
  }
}
