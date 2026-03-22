import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// --- MODEL: DATA PARA SA EXPLORE ---
class ExplorePost {
  final String id;
  final String username;
  final String userProfileImage;
  final List<String> imageUrls;
  final String caption;
  String reaction;
  int likesCount;
  bool isFollowing;
  bool isSaved;
  final List<Map<String, String>> comments; // Map para may 'user' at 'text'

  ExplorePost({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.imageUrls,
    required this.caption,
    this.reaction = 'None',
    this.likesCount = 0,
    this.isFollowing = false,
    this.isSaved = false,
    List<Map<String, String>>? comments,
  }) : comments = comments ?? [
    {'user': 'traveler_01', 'text': 'Ganda naman dito! 😍'},
    {'user': 'snap_master', 'text': 'Solid shot! 🔥'},
  ];
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final String currentUser = 'kriselz_';
  late List<ExplorePost> _explorePosts;

  @override
  void initState() {
    super.initState();
    _explorePosts = List.generate(
      50,
          (index) => ExplorePost(
        id: index.toString(),
        username: index == 0 ? currentUser : 'explore_user_$index',
        userProfileImage: 'https://i.pravatar.cc/150?img=${(index % 50) + 1}',
        imageUrls: index % 3 == 0
            ? ['https://picsum.photos/600/800?random=$index', 'https://picsum.photos/600/800?random=${index + 500}']
            : ['https://picsum.photos/600/800?random=$index'],
        caption: 'Discovering something new! #explore #vibe #post$index',
        likesCount: (index + 1) * 15,
      ),
    );
  }

  void _removePost(String id) {
    setState(() {
      _explorePosts.removeWhere((post) => post.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _explorePosts.length,
        itemBuilder: (context, index) {
          final post = _explorePosts[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExploreFeedView(
                    posts: _explorePosts,
                    initialIndex: index,
                    currentUser: currentUser,
                    onPostRemoved: (id) => _removePost(id),
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            child: Image.network(post.imageUrls[0], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}

class ExploreFeedView extends StatefulWidget {
  final List<ExplorePost> posts;
  final int initialIndex;
  final String currentUser;
  final Function(String) onPostRemoved;

  const ExploreFeedView({super.key, required this.posts, required this.initialIndex, required this.currentUser, required this.onPostRemoved});

  @override
  State<ExploreFeedView> createState() => _ExploreFeedViewState();
}

class _ExploreFeedViewState extends State<ExploreFeedView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return ExploreFeedItem(
            post: widget.posts[index],
            currentUser: widget.currentUser,
            onRemove: () {
              widget.onPostRemoved(widget.posts[index].id);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

class ExploreFeedItem extends StatefulWidget {
  final ExplorePost post;
  final String currentUser;
  final VoidCallback onRemove;

  const ExploreFeedItem({super.key, required this.post, required this.currentUser, required this.onRemove});

  @override
  State<ExploreFeedItem> createState() => _ExploreFeedItemState();
}

class _ExploreFeedItemState extends State<ExploreFeedItem> {
  final PageController _imagePageController = PageController();
  final GlobalKey _reactionButtonKey = GlobalKey();
  OverlayEntry? _reactionOverlay;

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️'},
    {'name': 'Haha', 'icon': '😆'},
    {'name': 'Wow', 'icon': '😮'},
    {'name': 'Sad', 'icon': '😢'},
    {'name': 'Angry', 'icon': '😡'},
  ];

  // --- CONSISTENT COMMENT SHEET ---
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
                Container(
                  width: 40, 
                  height: 4, 
                  margin: const EdgeInsets.symmetric(vertical: 10), 
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                ),
                const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.post.comments[index];
                      return ListTile(
                        leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 18)),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            children: [
                              TextSpan(text: '${comment['user']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: comment['text']),
                            ],
                          ),
                        ),
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
                            setState(() => widget.post.comments.add({'user': widget.currentUser, 'text': commentController.text}));
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

  // --- CONSISTENT 3-DOTS OPTIONS ---
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            if (widget.post.username == widget.currentUser)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red), 
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)), 
                onTap: () { Navigator.pop(context); widget.onRemove(); }
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
                widget.onRemove(); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We will show fewer posts like this.')));
              }
            ),
            ListTile(
              leading: const Icon(Icons.link), 
              title: const Text('Copy Link'), 
              onTap: () { 
                Navigator.pop(context); 
                Clipboard.setData(ClipboardData(text: widget.post.imageUrls[0]));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              }
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined), 
              title: const Text('Share to...'), 
              onTap: () {
                Navigator.pop(context);
                Share.share('Check out this post by ${widget.post.username}: ${widget.post.caption}');
              }
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
                        setState(() {
                          if (widget.post.reaction == 'None') widget.post.likesCount++;
                          widget.post.reaction = r['name']!;
                        });
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
        PageView.builder(
          controller: _imagePageController,
          itemCount: widget.post.imageUrls.length,
          itemBuilder: (context, i) => Image.network(widget.post.imageUrls[i], fit: BoxFit.cover),
        ),
        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent], stops: const [0, 0.4]))),

        Positioned(
          bottom: 40,
          left: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('@${widget.post.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 10),
                  if (widget.post.username != widget.currentUser)
                    GestureDetector(
                      onTap: () => setState(() => widget.post.isFollowing = !widget.post.isFollowing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                          color: widget.post.isFollowing ? Colors.transparent : Colors.white.withOpacity(0.2),
                        ),
                        child: Text(widget.post.isFollowing ? 'Following' : 'Follow', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(widget.post.caption, style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),

        Positioned(
          bottom: 40,
          right: 15,
          child: Column(
            children: [
              GestureDetector(
                key: _reactionButtonKey,
                onLongPress: _showReactionPopup,
                onTap: () {
                  setState(() {
                    if (widget.post.reaction == 'None') { widget.post.reaction = 'Love'; widget.post.likesCount++; }
                    else { widget.post.reaction = 'None'; widget.post.likesCount--; }
                  });
                },
                child: widget.post.reaction == 'None'
                    ? const Icon(Icons.favorite_border, color: Colors.white, size: 35)
                    : (widget.post.reaction == 'Love'
                    ? const Icon(Icons.favorite, color: Colors.red, size: 35)
                    : Text(reactionsList.firstWhere((e) => e['name'] == widget.post.reaction)['icon']!, style: const TextStyle(fontSize: 30))),
              ),
              Text('${widget.post.likesCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32), onPressed: _showCommentsSheet),
              const SizedBox(height: 10),
              // SAVED BUTTON (Consistent with Home)
              IconButton(
                icon: Icon(
                  widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border, 
                  color: widget.post.isSaved ? Colors.yellow[700] : Colors.white, 
                  size: 32
                ),
                onPressed: () {
                  setState(() => widget.post.isSaved = !widget.post.isSaved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.post.isSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'))
                  );
                },
              ),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 32), 
                onPressed: () => Share.share('Check out this post by ${widget.post.username}: ${widget.post.caption}')
              ),
              const SizedBox(height: 10),
              IconButton(icon: const Icon(Icons.more_vert, color: Colors.white, size: 32), onPressed: _showMoreOptions),
            ],
          ),
        ),
      ],
    );
  }
}
