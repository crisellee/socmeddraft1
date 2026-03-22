import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// MODELS
import 'models/post.dart';

// SCREENS
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/add_post_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/threads_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
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
      postImageUrls: ['https://picsum.photos/600/600?random=1'],
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

  final List<Map<String, String>> _storyData = [
    {'username': 'blythe', 'imageUrl': 'https://i.pravatar.cc/150?img=11'},
    {'username': 'yayang_', 'imageUrl': 'https://i.pravatar.cc/150?img=12'},
    {'username': 'selena_g', 'imageUrl': 'https://i.pravatar.cc/150?img=13'},
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

  void _showMoreMenu(BuildContext context) {
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
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Your Activity'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Saved'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    final List<Widget> pages = [
      HomePage(
        posts: _posts.where((p) => p.postImageUrls.isNotEmpty).toList(),
        stories: _storyData,
        onReact: (filteredIndex, react) {
          final post = _posts.where((p) => p.postImageUrls.isNotEmpty).toList()[filteredIndex];
          final originalIndex = _posts.indexOf(post);
          _handleReact(originalIndex, react);
        },
        onComment: (filteredIndex, c) {
          final post = _posts.where((p) => p.postImageUrls.isNotEmpty).toList()[filteredIndex];
          setState(() => post.comments.add(c));
        },
        onSave: (filteredIndex) {
          final post = _posts.where((p) => p.postImageUrls.isNotEmpty).toList()[filteredIndex];
          setState(() => post.isSaved = !post.isSaved);
        },
        onDirectMessage: () => setState(() => _selectedIndex = 5),
      ),
      const ExploreScreen(),
      AddPostScreen(
          onPost: (cap, urls, loc) => setState(() {
            _posts.insert(0, Post(
              id: DateTime.now().toString(), 
              username: 'kriselz_', 
              userProfileImage: 'https://i.pravatar.cc/150?img=11', 
              postImageUrls: urls, 
              caption: cap, 
              location: loc, 
              timeAgo: 'JUST NOW'
            ));
            if (urls.isEmpty) {
              _selectedIndex = 8; 
            } else {
              _selectedIndex = 0; 
            }
          }),
          onAddStory: (url) => setState(() => _storyData.insert(0, {'username': 'Your Story', 'imageUrl': url})),
          onClose: () => setState(() => _selectedIndex = 0)),
      const ReelsScreen(),
      ProfileScreen(
        allPosts: _posts,
        onDeletePost: (id) => setState(() => _posts.removeWhere((p) => p.id == id)),
        onReact: _handleReact,
        onComment: (i, c) => setState(() => _posts[i].comments.add(c)),
        onSave: (i) => setState(() => _posts[i].isSaved = !_posts[i].isSaved),
      ),
      MessagesScreen(stories: _storyData),
      NotificationsScreen(),
      const SearchScreen(),
      ThreadsScreen(threads: _posts.where((p) => p.postImageUrls.isEmpty).toList()),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isWeb) _buildSidebar(context),
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 600,
                    child: IndexedStack(
                      index: _selectedIndex < pages.length && _selectedIndex >= 0 ? _selectedIndex : 0,
                      children: pages,
                    ),
                  ),
                  if (isWeb && screenWidth > 1150 && (_selectedIndex == 0 || _selectedIndex == 8))
                    Padding(
                      padding: const EdgeInsets.only(left: 50, top: 40),
                      child: SizedBox(width: 320, child: _buildSuggestions(screenWidth)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWeb ? null : _buildBottomNav(),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarHovered = true),
      onExit: (_) => setState(() => _isSidebarHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSidebarHovered ? 240 : 80,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey[200]!))),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSidebarHovered
                      ? const Text('Instagram', key: ValueKey('text'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                      : const Icon(Icons.camera_alt_outlined, key: ValueKey('icon'), size: 30),
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
                  SidebarItem(activeIcon: Icons.alternate_email, inactiveIcon: Icons.alternate_email, label: 'Threads', index: 8, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: Icons.explore, inactiveIcon: Icons.explore_outlined, label: 'Explore', index: 1, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: Icons.movie, inactiveIcon: Icons.movie_outlined, label: 'Reels', index: 3, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: Icons.chat_bubble, inactiveIcon: Icons.chat_bubble_outline, label: 'Messages', index: 5, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, badge: '4', onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: Icons.favorite, inactiveIcon: Icons.favorite_outline, label: 'Notifications', index: 6, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: Icons.add_box, inactiveIcon: Icons.add_box_outlined, label: 'Create', index: 2, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                  SidebarItem(activeIcon: null, inactiveIcon: null, label: 'Profile', index: 4, selectedIndex: _selectedIndex, isSidebarHovered: _isSidebarHovered, onTap: (i) => setState(() => _selectedIndex = i)),
                ],
              ),
            ),
            SidebarItem(
              activeIcon: Icons.menu, 
              inactiveIcon: Icons.menu, 
              label: 'More', 
              index: -1, 
              selectedIndex: _selectedIndex, 
              isSidebarHovered: _isSidebarHovered, 
              onTap: (i) => _showMoreMenu(context)
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? (_selectedIndex == 8 ? 4 : 0) : _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      showSelectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.movie_outlined), label: 'Reels'),
        BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')), label: 'Profile'),
      ],
    );
  }

  Widget _buildSuggestions(double screenWidth) {
    return Column(
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
        const Text('Suggested for you', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 15),
        _suggestionItem('jerick_rupert', 'https://i.pravatar.cc/150?img=50'),
        _suggestionItem('sofiantastic', 'https://i.pravatar.cc/150?img=51'),
      ],
    );
  }

  Widget _suggestionItem(String name, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundImage: NetworkImage(url)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            mainAxisAlignment: widget.isSidebarHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              widget.label == 'Profile'
                  ? CircleAvatar(radius: 14, backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), child: isSelected ? Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2))) : null)
                  : (widget.badge != null
                  ? Badge(label: Text(widget.badge!), child: Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28))
                  : Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28)),
              if (widget.isSidebarHovered)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      widget.label,
                      style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      overflow: TextOverflow.ellipsis,
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