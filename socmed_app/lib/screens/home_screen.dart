import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle.dart';
import 'story_view_screen.dart';

class HomePage extends StatelessWidget {
  final List<Post> posts;
  final List<Map<String, String>> stories;
  final Function(int, String) onReact;
  final Function(int, String) onComment;
  final Function(int) onSave;
  final VoidCallback onDirectMessage;

  const HomePage({
    super.key,
    required this.posts,
    required this.stories,
    required this.onReact,
    required this.onComment,
    required this.onSave,
    required this.onDirectMessage,
  });

  // --- BUTTON DESIGN: MODAL BOTTOM SHEET PARA SA 3 DOTS ---
  void _showPostOptions(BuildContext context, int index) {
    final post = posts[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // Design: Rounded corners sa taas para magmukhang modern
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sakto lang ang laki sa content
            children: [
              // Design: "Handle bar" sa taas ng menu
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Option 1: Report
              ListTile(
                leading: const Icon(Icons.report_gmailerrorred, color: Colors.red),
                title: const Text('Report', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported.')));
                },
              ),
              // Option 2: Not Interested
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Not Interested'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We will show fewer posts like this.')));
                },
              ),
              // Option 3: Copy Link
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: post.postImageUrls.isNotEmpty ? post.postImageUrls[0] : "Check out this post by ${post.username}"));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                },
              ),
              // Option 4: Share
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share to...'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share('Check out this post by ${post.username}: ${post.caption}');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // --- DESIGN: STORY SECTION ---
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StoryViewScreen(
                          stories: stories,
                          initialIndex: index,
                          onDirectMessage: onDirectMessage
                      )
                  )
              ),
              child: StoryCircle(
                username: stories[index]['username']!,
                imageUrl: stories[index]['imageUrl']!,
                isMe: index == 0,
              ),
            ),
          ),
        ),

        // --- DESIGN: POSTS LIST SECTION ---
        ...List.generate(
          posts.length,
              (index) => PostCard(
            post: posts[index],
            onReact: (react) => onReact(index, react),
            onComment: (comment) => onComment(index, comment),
            onSave: () => onSave(index),
            // IPINAPASA ANG FUNCTION DITO PARA SA 3 DOTS
            onMoreTap: () => _showPostOptions(context, index),
          ),
        ),
      ],
    );
  }
}
