import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

class Reel {
  final String id;
  final String username;
  final String userProfileImage;
  final String mediaUrl;
  final bool isVideo;
  final String caption;
  String reaction;
  int likesCount;
  bool isFollowing;
  final List<String> comments;

  Reel({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.mediaUrl,
    required this.caption,
    this.isVideo = false,
    this.reaction = 'None',
    this.likesCount = 0,
    this.isFollowing = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final String currentLoggedInUser = 'kriselz_';

  final List<String> reelsVideos = [
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
  ];

  late List<Reel> _reels = List.generate(
    10,
        (index) => Reel(
      id: index.toString(),
      username: index == 0 ? currentLoggedInUser : 'travel_vlogger_$index',
      userProfileImage: 'https://i.pravatar.cc/150?img=${index + 20}',
      mediaUrl: index % 2 == 0
          ? 'https://picsum.photos/400/800?random=${index + 200}'
          : reelsVideos[index % reelsVideos.length],
      isVideo: index % 2 != 0,
      caption: 'Vibing with the view! #nature #reels$index',
      likesCount: (index + 1) * 100,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          return ReelItem(
            key: ValueKey(_reels[index].id),
            reel: _reels[index],
            currentUser: currentLoggedInUser,
            onReact: (reaction) => setState(() {
              if (_reels[index].reaction == 'None' && reaction != 'None') {
                _reels[index].likesCount++;
              } else if (_reels[index].reaction != 'None' && reaction == 'None') {
                _reels[index].likesCount--;
              }
              _reels[index].reaction = reaction;
            }),
            onNotInterested: () {
              setState(() => _reels.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post hidden')),
              );
            },
          );
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Reel reel;
  final String currentUser;
  final Function(String) onReact;
  final VoidCallback onNotInterested;

  const ReelItem({
    super.key,
    required this.reel,
    required this.currentUser,
    required this.onReact,
    required this.onNotInterested,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  VideoPlayerController? _videoController;
  final GlobalKey _reactionButtonKey = GlobalKey();
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
    if (widget.reel.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _showCommentsSheet() {
    TextEditingController commentController = TextEditingController();
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
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: widget.reel.comments.isEmpty
                      ? const Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    itemCount: widget.reel.comments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 18)),
                        title: Text('user_$index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(widget.reel.comments[index], style: const TextStyle(color: Colors.black)),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: commentController, decoration: const InputDecoration(hintText: "Add a comment...", border: InputBorder.none))),
                      TextButton(
                        onPressed: () {
                          if (commentController.text.isNotEmpty) {
                            setState(() => widget.reel.comments.add(commentController.text));
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Not Interested'),
              onTap: () {
                Navigator.pop(context);
                widget.onNotInterested();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.reel.mediaUrl));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share to...'),
              onTap: () {
                Navigator.pop(context);
                Share.share('Check out this reel: ${widget.reel.mediaUrl}');
              },
            ),
          ],
        ),
      ),
    );
  }

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
              top: position.dy - 70,
              right: 20,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media Layer
        widget.reel.isVideo && _videoController != null && _videoController!.value.isInitialized
            ? FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        )
            : Image.network(widget.reel.mediaUrl, fit: BoxFit.cover),

        // Gradient Overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Info Layer
        Positioned(
          bottom: 40,
          left: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.reel.userProfileImage)),
                  const SizedBox(width: 10),
                  Text('@${widget.reel.username}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 10),
                  if (widget.reel.username != widget.currentUser)
                    GestureDetector(
                      onTap: () => setState(() => widget.reel.isFollowing = !widget.reel.isFollowing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                          color: widget.reel.isFollowing ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                        child: Text(widget.reel.isFollowing ? 'Following' : 'Follow', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Text(widget.reel.caption, style: const TextStyle(color: Colors.white))
              ),
            ],
          ),
        ),

        // Action Buttons (Consistent with Explore)
        Positioned(
          bottom: 40,
          right: 15,
          child: Column(
            children: [
              GestureDetector(
                key: _reactionButtonKey,
                onLongPress: _showReactionPopup,
                onTap: () => widget.onReact(widget.reel.reaction == 'None' ? 'Love' : 'None'),
                child: widget.reel.reaction == 'None'
                    ? const Icon(Icons.favorite_border, color: Colors.white, size: 35)
                    : (widget.reel.reaction == 'Love'
                    ? const Icon(Icons.favorite, color: Colors.red, size: 35)
                    : Text(reactionsList.firstWhere((e) => e['name'] == widget.reel.reaction)['icon']!, style: const TextStyle(fontSize: 30))),
              ),
              Text('${widget.reel.likesCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32), onPressed: _showCommentsSheet),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 32),
                onPressed: () => Share.share('Check out this reel: ${widget.reel.mediaUrl}'),
              ),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 32),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
