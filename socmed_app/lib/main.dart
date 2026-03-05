import 'package:flutter/material.dart';
import 'models/post.dart';
import 'widgets/post_card.dart';
import 'widgets/story_circle.dart';
import 'screens/search_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/explore_screen.dart';

void main() {
  runApp(const InstagramClone());
}

class InstagramClone extends StatelessWidget {
  const InstagramClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSidebarHovered = false;

  final List<Post> _posts = [
    Post(
      id: '1',
      username: 'ynnah_314',
      userProfileImage: 'https://i.pravatar.cc/150?img=1',
      location: 'Manila, Philippines',
      postImageUrls: ['https://picsum.photos/600/600?random=1', 'https://picsum.photos/600/600?random=11'],
      caption: 'February Celebrant ... more',
      timeAgo: '1w',
      likesCount: 2,
    ),
    Post(
      id: '2',
      username: 'capcaprice',
      userProfileImage: 'https://i.pravatar.cc/150?img=2',
      location: 'GMA Network',
      postImageUrls: ['https://picsum.photos/600/800?random=2'],
      caption: 'Enjoying the day!',
      timeAgo: '1d',
      likesCount: 150,
    ),
  ];

  void _handleReact(int index, String reaction) {
    setState(() {
      if (_posts[index].reaction == 'None' && reaction != 'None') {
        _posts[index].likesCount++;
      } else if (_posts[index].reaction != 'None' && reaction == 'None') {
        _posts[index].likesCount--;
      }
      _posts[index].reaction = reaction;
    });
  }

  void _handleComment(int index, String comment) {
    setState(() {
      _posts[index].comments.add(comment);
    });
  }

  void _handleSave(int index) {
    setState(() {
      _posts[index].isSaved = !_posts[index].isSaved;
    });
  }

  void _addNewPost(String caption, List<String> imageUrls, String location) {
    setState(() {
      _posts.insert(0, Post(
        id: DateTime.now().toString(),
        username: 'kriselz_',
        userProfileImage: 'https://i.pravatar.cc/150?img=11',
        postImageUrls: imageUrls,
        caption: caption,
        location: location,
        timeAgo: 'JUST NOW',
      ));
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    final List<Widget> pages = [
      HomePage(
        posts: _posts, 
        onReact: _handleReact, 
        onComment: _handleComment,
        onSave: _handleSave,
      ),
      const ExploreScreen(),
      AddPostScreen(onPost: _addNewPost, onClose: () => setState(() => _selectedIndex = 0)),
      const ReelsScreen(),
      ProfileScreen(userPosts: _posts.where((p) => p.username == 'kriselz_').toList()),
      MessagesScreen(),
      NotificationsScreen(),
      const SearchScreen(),
    ];

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            // SIDEBAR
            MouseRegion(
              onEnter: (_) => setState(() => _isSidebarHovered = true),
              onExit: (_) => setState(() => _isSidebarHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isSidebarHovered ? 240 : 80,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey[200]!)),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isSidebarHovered
                              ? const Text('Instagram',
                                  key: ValueKey('text'),
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold))
                              : const Icon(Icons.camera_alt_outlined,
                                  key: ValueKey('icon'), size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SidebarItem(activeIcon: Icons.home_filled, inactiveIcon: Icons.home_outlined, label: 'Home', index: 0, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.search, inactiveIcon: Icons.search, label: 'Search', index: 7, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.explore, inactiveIcon: Icons.explore_outlined, label: 'Explore', index: 1, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.movie, inactiveIcon: Icons.movie_outlined, label: 'Reels', index: 3, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.chat_bubble, inactiveIcon: Icons.chat_bubble_outline, label: 'Messages', index: 5, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, badge: '4', onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.favorite, inactiveIcon: Icons.favorite_outline, label: 'Notifications', index: 6, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: Icons.add_box, inactiveIcon: Icons.add_box_outlined, label: 'Create', index: 2, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                          SidebarItem(activeIcon: null, inactiveIcon: null, label: 'Profile', index: 4, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                        ],
                      ),
                    ),
                    SidebarItem(activeIcon: Icons.menu, inactiveIcon: Icons.menu, label: 'More', index: -1, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) {}),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // CENTER
            Expanded(
              flex: 3,
              child: pages[_selectedIndex > 7 ? 0 : _selectedIndex],
            ),
            // SUGGESTIONS
            if (screenWidth > 1100 && (_selectedIndex == 0 || _selectedIndex > 7))
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 40, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                        title: Text('kriselz_', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Krisel'),
                        trailing: Text('Switch', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Suggested for you', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('See all', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildSuggestionItem('Jerick Rupert Isip', 'https://i.pravatar.cc/150?img=50'),
                      _buildSuggestionItem('sofiantastic', 'https://i.pravatar.cc/150?img=51'),
                      const SizedBox(height: 40),
                      const Text('About · Help · Privacy · Terms', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 20),
                      const Text('© 2024 INSTAGRAM FROM META', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: pages[_selectedIndex > 4 ? 0 : _selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
            BottomNavigationBarItem(icon: Icon(Icons.movie_outlined), label: 'Reels'),
            BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')), label: 'Profile'),
          ],
        ),
      );
    }
  }

  Widget _buildSuggestionItem(String name, String imageUrl) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: const Text('Suggested for you', style: TextStyle(fontSize: 11)),
      trailing: const Text('Follow', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class SidebarItem extends StatefulWidget {
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final bool isSidebarHovered;
  final String? badge;
  final Function(int) onTap;

  const SidebarItem({super.key, this.activeIcon, this.inactiveIcon, required this.label, required this.index, required this.selectedIndex, required this.isSidebarHovered, this.badge, required this.onTap});

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isItemHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.selectedIndex == widget.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _isItemHovered = true),
      onExit: (_) => setState(() => _isItemHovered = false),
      child: InkWell(
        onTap: () => widget.onTap(widget.index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[100] : (_isItemHovered ? Colors.grey[50] : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.isSidebarHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _isItemHovered ? 1.1 : 1.0,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: widget.label == 'Profile'
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
                          child: isSelected ? Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2))) : null,
                        )
                      : (widget.badge != null 
                          ? Badge(label: Text(widget.badge!), child: Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28))
                          : Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28)),
                ),
              ),
              if (widget.isSidebarHovered)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset((1.0 - value) * -10, 0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Post> posts;
  final Function(int, String) onReact;
  final Function(int, String) onComment;
  final Function(int) onSave;

  const HomePage({super.key, required this.posts, required this.onReact, required this.onComment, required this.onSave});

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: isWeb ? null : AppBar(title: const Text('Instagram', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)), actions: [IconButton(icon: const Icon(Icons.favorite_border), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()))), IconButton(icon: const Icon(Icons.send_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen())))], backgroundColor: Colors.white, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              Container(
                height: 110,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  itemBuilder: (context, index) => StoryCircle(username: index == 0 ? 'blythe' : 'user_$index', imageUrl: 'https://i.pravatar.cc/150?img=${index + 20}', isMe: index == 0),
                ),
              ),
              ...List.generate(posts.length, (index) => PostCard(post: posts[index], onReact: (react) => onReact(index, react), onComment: (comment) => onComment(index, comment), onSave: () => onSave(index))),
            ],
          ),
        ),
      ),
    );
  }
}
