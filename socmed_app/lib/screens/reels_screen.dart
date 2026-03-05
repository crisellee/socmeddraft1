import 'package:flutter/material.dart';

class Reel {
  final String id;
  final String username;
  final String userProfileImage;
  final String imageUrl;
  final String caption;
  String reaction;
  int likesCount;
  final List<String> comments;

  Reel({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.imageUrl,
    required this.caption,
    this.reaction = 'None',
    this.likesCount = 0,
    List<String>? comments,
  }) : comments = comments ?? [];
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final List<Reel> _reels = List.generate(10, (index) => Reel(
    id: index.toString(),
    username: 'user_$index',
    userProfileImage: 'https://i.pravatar.cc/150?img=${index + 20}',
    imageUrl: 'https://picsum.photos/400/800?random=${index + 200}',
    caption: 'Amazing view #$index! #reels #viral #nature',
    likesCount: (index + 1) * 100,
  ));

  void _handleReact(int index, String reaction) {
    setState(() {
      if (_reels[index].reaction == 'None' && reaction != 'None') {
        _reels[index].likesCount++;
      } else if (_reels[index].reaction != 'None' && reaction == 'None') {
        _reels[index].likesCount--;
      }
      _reels[index].reaction = reaction;
    });
  }

  void _handleComment(int index, String comment) {
    setState(() {
      _reels[index].comments.add(comment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          return ReelItem(
            reel: _reels[index],
            onReact: (react) => _handleReact(index, react),
            onComment: (comment) => _handleComment(index, comment),
          );
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Reel reel;
  final Function(String) onReact;
  final Function(String) onComment;

  const ReelItem({
    super.key,
    required this.reel,
    required this.onReact,
    required this.onComment,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool _showReactions = false;

  final List<Map<String, String>> reactions = [
    {'name': 'Like', 'icon': '❤️', 'color': '0xFFF44336'},
    {'name': 'Haha', 'icon': '😆', 'color': '0xFFFFC107'},
    {'name': 'Wow', 'icon': '😮', 'color': '0xFFFFC107'},
    {'name': 'Sad', 'icon': '😢', 'color': '0xFFFFC107'},
    {'name': 'Angry', 'icon': '😡', 'color': '0xFFE91E63'},
  ];

  void _toggleReactions() {
    setState(() {
      _showReactions = !_showReactions;
    });
  }

  Widget _getReactionIcon() {
    if (widget.reel.reaction == 'None') {
      return const Icon(Icons.favorite_border, color: Colors.white, size: 30);
    }
    if (widget.reel.reaction == 'Like') {
      return const Icon(Icons.favorite, color: Colors.red, size: 30);
    }
    final react = reactions.firstWhere((r) => r['name'] == widget.reel.reaction, orElse: () => reactions[0]);
    return Text(react['icon']!, style: const TextStyle(fontSize: 30));
  }

  void _showCommentSheet() {
    final TextEditingController _controller = TextEditingController();
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
                const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.reel.comments.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                      title: Text(widget.reel.comments[i]),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          widget.onComment(_controller.text);
                          setModalState(() {}); // Refresh modal list
                          _controller.clear();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(widget.reel.imageUrl, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 15,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 15, backgroundImage: NetworkImage(widget.reel.userProfileImage)),
                  const SizedBox(width: 10),
                  Text(widget.reel.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(5)),
                    child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.reel.caption, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 15,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onLongPress: _toggleReactions,
                    onTap: () {
                      if (widget.reel.reaction == 'None') {
                        widget.onReact('Like');
                      } else {
                        widget.onReact('None');
                      }
                    },
                    child: _getReactionIcon(),
                  ),
                  if (_showReactions)
                    Positioned(
                      right: 40,
                      bottom: 0,
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: reactions.map((r) => _ReelReactionItem(
                              icon: r['icon']!,
                              name: r['name']!,
                              onTap: () {
                                widget.onReact(r['name']!);
                                _toggleReactions();
                              },
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Text(widget.reel.likesCount.toString(), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                onPressed: _showCommentSheet,
              ),
              Text(widget.reel.comments.length.toString(), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              const Icon(Icons.send_outlined, color: Colors.white, size: 30),
              const SizedBox(height: 20),
              const Icon(Icons.more_vert, color: Colors.white, size: 30),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelReactionItem extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;

  const _ReelReactionItem({required this.icon, required this.name, required this.onTap});

  @override
  State<_ReelReactionItem> createState() => _ReelReactionItemState();
}

class _ReelReactionItemState extends State<_ReelReactionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isHovered ? 1.3 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(widget.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
