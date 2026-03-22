import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PostCard extends StatelessWidget {
  final Post post;
  final Function(String) onReact;
  final Function(String) onComment;
  final VoidCallback onSave;
  final VoidCallback onMoreTap;
  final VoidCallback? onDelete; // Optional para sa Profile delete logic

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onSave,
    required this.onMoreTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(post.userProfileImage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMoreTap, // Tatawag sa menu ng Home o Profile
                ),
              ],
            ),
          ),

          // --- IMAGE ---
          if (post.postImageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.postImageUrls[0],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

          // --- ACTIONS ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.reaction != "None" ? Icons.favorite : Icons.favorite_border,
                    color: post.reaction != "None" ? Colors.red : Colors.black,
                  ),
                  onPressed: () => onReact(post.reaction == "None" ? "Love" : "None"),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => onComment(""),
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {
                    Share.share('Check out this post by ${post.username}: ${post.caption}');
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? Colors.yellow[700] : Colors.black,
                  ),
                  onPressed: onSave,
                ),
              ],
            ),
          ),

          // --- CAPTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(text: "${post.username} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(post.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
