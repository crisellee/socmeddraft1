import 'package:flutter/material.dart';

class ExplorePost {
  final String id;
  final String username;
  final String userProfileImage;
  final List<String> imageUrls;
  final String caption;
  String reaction;
  int likesCount;
  final List<String> comments;

  ExplorePost({
    required this.id,
    required this.username,
    required this.userProfileImage,
    required this.imageUrls,
    required this.caption,
    this.reaction = 'None',
    this.likesCount = 0,
    List<String>? comments,
  }) : comments = comments ?? [];
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<ExplorePost> _explorePosts = List.generate(
    50,
    (index) => ExplorePost(
      id: index.toString(),
      username: 'explore_user_$index',
      userProfileImage: 'https://i.pravatar.cc/150?img=${(index % 50) + 1}',
      imageUrls: index % 3 == 0 
        ? ['https://picsum.photos/600/800?random=$index', 'https://picsum.photos/600/800?random=${index+500}']
        : ['https://picsum.photos/600/800?random=$index'],
      caption: 'Discovering something new! #explore #vibe #post$index',
      likesCount: (index + 1) * 15,
    ),
  );

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWeb ? 4 : 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
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
                  ),
                ),
              ).then((_) => setState(() {})); // Rebuild grid when coming back
            },
            child: ClipRRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.imageUrls[0],
                    fit: BoxFit.cover,
                  ),
                  if (post.imageUrls.length > 1)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(Icons.collections, color: Colors.white, size: 20),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExploreFeedView extends StatefulWidget {
  final List<ExplorePost> posts;
  final int initialIndex;

  const ExploreFeedView({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return ExploreFeedItem(post: widget.posts[index]);
        },
      ),
    );
  }
}

class ExploreFeedItem extends StatefulWidget {
  final ExplorePost post;

  const ExploreFeedItem({super.key, required this.post});

  @override
  State<ExploreFeedItem> createState() => _ExploreFeedItemState();
}

class _ExploreFeedItemState extends State<ExploreFeedItem> {
  bool _showReactions = false;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  final List<Map<String, String>> reactionsList = [
    {'name': 'Love', 'icon': '❤️', 'color': '0xFFF44336'},
    {'name': 'Haha', 'icon': '😆', 'color': '0xFFFFC107'},
    {'name': 'Wow', 'icon': '😮', 'color': '0xFFFFC107'},
    {'name': 'Sad', 'icon': '😢', 'color': '0xFFFFC107'},
    {'name': 'Angry', 'icon': '😡', 'color': '0xFFE91E63'},
  ];

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _toggleReactions() {
    setState(() {
      _showReactions = !_showReactions;
    });
  }

  Widget _getReactionIcon() {
    if (widget.post.reaction == 'None') {
      return const Icon(Icons.favorite_border, color: Colors.white, size: 30);
    }
    if (widget.post.reaction == 'Like' || widget.post.reaction == 'Love') {
      return const Icon(Icons.favorite, color: Colors.red, size: 30);
    }
    final react = reactionsList.firstWhere(
      (r) => r['name'] == widget.post.reaction,
      orElse: () => reactionsList[0],
    );
    return Text(react['icon']!, style: const TextStyle(fontSize: 30));
  }

  void _showCommentSheet() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const CircleAvatar(
                        radius: 15,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      ),
                      title: Text(widget.post.comments[i]),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            widget.post.comments.add(controller.text);
                          });
                          setModalState(() {});
                          controller.clear();
                        }
                      },
                      child: const Text(
                        'Post',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
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
        PageView.builder(
          controller: _imagePageController,
          itemCount: widget.post.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, i) {
            return Image.network(widget.post.imageUrls[i], fit: BoxFit.cover);
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.3)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        if (widget.post.imageUrls.length > 1) ...[
          if (_currentImageIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 40),
                  onPressed: () {
                    _imagePageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentImageIndex < widget.post.imageUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 40),
                  onPressed: () {
                    _imagePageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],

        if (widget.post.imageUrls.length > 1)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
              child: Text('${_currentImageIndex + 1} / ${widget.post.imageUrls.length}', 
                style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(widget.post.userProfileImage),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.post.username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.post.caption, style: const TextStyle(color: Colors.white)),
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
                      setState(() {
                        if (widget.post.reaction == 'None') {
                          widget.post.reaction = 'Love';
                          widget.post.likesCount++;
                        } else {
                          widget.post.reaction = 'None';
                          widget.post.likesCount--;
                        }
                      });
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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: reactionsList.map((r) => _ExploreReactionItem(
                              icon: r['icon']!,
                              name: r['name']!,
                              onTap: () {
                                setState(() {
                                  if (widget.post.reaction == 'None') {
                                    widget.post.likesCount++;
                                  }
                                  widget.post.reaction = r['name']!;
                                });
                                _toggleReactions();
                              },
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                widget.post.likesCount.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                onPressed: _showCommentSheet,
              ),
              Text(
                widget.post.comments.length.toString(),
                style: const TextStyle(color: Colors.white),
              ),
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

class _ExploreReactionItem extends StatefulWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;

  const _ExploreReactionItem({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  State<_ExploreReactionItem> createState() => _ExploreReactionItemState();
}

class _ExploreReactionItemState extends State<_ExploreReactionItem> {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 24)),
                if (_isHovered)
                  Text(widget.name, style: const TextStyle(fontSize: 10, color: Colors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
