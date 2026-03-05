import 'package:flutter/material.dart';
import '../models/post.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String) onReact;
  final Function(String) onComment;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onSave,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  final PageController _imagePageController = PageController();
  final FocusNode _commentFocusNode = FocusNode();
  int _currentImageIndex = 0;
  bool _showReactions = false;
  bool _showComments = false;

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️', 'color': '0xFFF44336'},
    {'name': 'Haha', 'icon': '😆', 'color': '0xFFFFC107'},
    {'name': 'Wow', 'icon': '😮', 'color': '0xFFFFC107'},
    {'name': 'Sad', 'icon': '😢', 'color': '0xFFFFC107'},
    {'name': 'Angry', 'icon': '😡', 'color': '0xFFE91E63'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _imagePageController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _toggleReactions() {
    setState(() {
      _showReactions = !_showReactions;
    });
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      if (_showComments) {
        Future.delayed(Duration.zero, () {
          _commentFocusNode.requestFocus();
        });
      }
    });
  }

  Widget _getReactionIcon() {
    if (widget.post.reaction == 'None') {
      return const Icon(Icons.favorite_border, color: Colors.black, size: 28);
    }
    if (widget.post.reaction == 'Like' || widget.post.reaction == 'Love') {
      return const Icon(Icons.favorite, color: Colors.red, size: 28);
    }
    final react = reactionsList.firstWhere(
      (r) => r['name'] == widget.post.reaction,
      orElse: () => reactionsList[0],
    );
    return Text(react['icon']!, style: const TextStyle(fontSize: 24));
  }

  Color _getReactionColor() {
    if (widget.post.reaction == 'None') return Colors.black;
    if (widget.post.reaction == 'Like' || widget.post.reaction == 'Love') return Colors.red;
    final react = reactionsList.firstWhere(
      (r) => r['name'] == widget.post.reaction,
      orElse: () => reactionsList[0],
    );
    return Color(int.parse(react['color']!));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.post.userProfileImage)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (widget.post.location.isNotEmpty) Text(widget.post.location, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),
          
          // Image Carousel
          if (widget.post.postImageUrls.isNotEmpty)
            SizedBox(
              height: 400,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: widget.post.postImageUrls.length,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      String path = widget.post.postImageUrls[index];
                      return kIsWeb || path.startsWith('http')
                          ? Image.network(path, fit: BoxFit.cover, width: double.infinity)
                          : Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
                    },
                  ),
                  if (widget.post.postImageUrls.length > 1) ...[
                    if (_currentImageIndex > 0)
                      Positioned(
                        left: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: CircleAvatar(
                            backgroundColor: Colors.white70,
                            radius: 15,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, size: 15, color: Colors.black),
                              onPressed: () => _imagePageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                            ),
                          ),
                        ),
                      ),
                    if (_currentImageIndex < widget.post.postImageUrls.length - 1)
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: CircleAvatar(
                            backgroundColor: Colors.white70,
                            radius: 15,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, size: 15, color: Colors.black),
                              onPressed: () => _imagePageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_currentImageIndex + 1}/${widget.post.postImageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              clipBehavior: Clip.none, // Mahalaga para lumabas ang popup
              children: [
                Row(
                  children: [
                    // Clickable & Long-pressable Reaction Button
                    InkWell(
                      onLongPress: _toggleReactions,
                      onTap: () {
                        if (widget.post.reaction == 'None') {
                          widget.onReact('Love');
                        } else {
                          widget.onReact('None');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            _getReactionIcon(),
                            if (widget.post.reaction != 'None') ...[
                              const SizedBox(width: 4),
                              Text(widget.post.reaction, style: TextStyle(color: _getReactionColor(), fontWeight: FontWeight.bold)),
                            ]
                          ],
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(_showComments ? Icons.chat_bubble : Icons.chat_bubble_outline), onPressed: _toggleComments),
                    IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
                    const Spacer(),
                    IconButton(
                      icon: Icon(widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border, color: widget.post.isSaved ? Colors.yellow[700] : Colors.black),
                      onPressed: widget.onSave,
                    ),
                  ],
                ),
                // Reactions Popup (Overlay)
                if (_showReactions)
                  Positioned(
                    bottom: 55,
                    left: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: reactionsList.map((r) => _ReactionItem(
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
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.likesCount > 0) Text('${widget.post.likesCount} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(text: '${widget.post.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
                if (_showComments) ...[
                  if (widget.post.comments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...widget.post.comments.map((comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 8, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                          const SizedBox(width: 8),
                          Expanded(child: Text(comment, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )).toList(),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _commentController, focusNode: _commentFocusNode, decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)), onSubmitted: (val) { if (val.isNotEmpty) { widget.onComment(val); _commentController.clear(); } })),
                        TextButton(onPressed: () { if (_commentController.text.isNotEmpty) { widget.onComment(_commentController.text); _commentController.clear(); } }, child: const Text('Post', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(widget.post.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionItem extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;
  const _ReactionItem({required this.icon, required this.name, required this.onTap});
  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Sisiguraduhin na mahuhuli ang tap
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isHovered ? 1.3 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 28)),
                if (_isHovered) 
                  Text(widget.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
              ]
            ),
          ),
        ),
      ),
    );
  }
}
