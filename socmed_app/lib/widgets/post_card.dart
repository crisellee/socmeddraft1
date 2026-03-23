import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String) onReact;
  final Function(String) onComment;
  final VoidCallback onSave;
  final VoidCallback onMoreTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onSave,
    required this.onMoreTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _reactionButtonKey = GlobalKey();
  OverlayEntry? _reactionOverlay;

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️'},
    {'name': 'Haha', 'icon': '😆'},
    {'name': 'Wow', 'icon': '😮'},
    {'name': 'Sad', 'icon': '😢'},
    {'name': 'Angry', 'icon': '😡'},
  ];

  void _showReactionPopup() {
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
              top: position.dy - 60,
              left: position.dx,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactionsList.map((r) => GestureDetector(
                      onTap: () {
                        widget.onReact(r['name']!);
                        _hideReactionPopup();
                      },
                      child: Padding(padding: const EdgeInsets.all(8.0), child: Text(r['icon']!, style: const TextStyle(fontSize: 25))),
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

  void _showCommentsSheet() {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Container(
                  width: 40, 
                  height: 4, 
                  margin: const EdgeInsets.symmetric(vertical: 10), 
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                ),
                const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: widget.post.comments.isEmpty
                      ? const Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: widget.post.comments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 18)),
                              title: Text(widget.post.comments[index], style: const TextStyle(fontSize: 14)),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController, 
                          decoration: const InputDecoration(hintText: "Add a comment...", border: InputBorder.none)
                        )
                      ),
                      TextButton(
                        onPressed: () {
                          if (commentController.text.isNotEmpty) {
                            widget.onComment(commentController.text);
                            setModalState(() {});
                            commentController.clear();
                          }
                        },
                        child: const Text("Post", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
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
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.post.userProfileImage)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.post.username, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: widget.onMoreTap),
              ],
            ),
          ),
          if (widget.post.postImageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(widget.post.postImageUrls[0], fit: BoxFit.cover, width: double.infinity),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  key: _reactionButtonKey,
                  onLongPress: _showReactionPopup,
                  onTap: () => widget.onReact(widget.post.reaction == "None" ? "Love" : "None"),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: widget.post.reaction == "None"
                        ? const Icon(Icons.favorite_border, size: 28)
                        : (widget.post.reaction == "Love"
                            ? const Icon(Icons.favorite, color: Colors.red, size: 28)
                            : Text(reactionsList.firstWhere((e) => e['name'] == widget.post.reaction)['icon']!, style: const TextStyle(fontSize: 24))),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 26), onPressed: _showCommentsSheet),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 26), 
                  onPressed: () => Share.share('Check out this post by ${widget.post.username}: ${widget.post.caption}')
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.post.isSaved ? Colors.yellow[700] : Colors.black,
                    size: 26,
                  ),
                  onPressed: widget.onSave,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${widget.post.likesCount} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(text: "${widget.post.username} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
                if (widget.post.comments.isNotEmpty)
                  GestureDetector(
                    onTap: _showCommentsSheet,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('View all ${widget.post.comments.length} comments', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(widget.post.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
