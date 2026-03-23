import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  runApp(const SnaptalkClone());
}

class SnaptalkClone extends StatefulWidget {
  const SnaptalkClone({super.key});

  @override
  State<SnaptalkClone> createState() => _SnaptalkCloneState();
}

class _SnaptalkCloneState extends State<SnaptalkClone> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snaptalk Buddy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white, brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return MainScreen(onThemeChanged: toggleTheme, currentThemeMode: _themeMode);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const MainScreen({super.key, required this.onThemeChanged, required this.currentThemeMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSidebarHovered = false;
  String _currentUserName = 'user';
  String _currentUserProfileImage = 'https://i.pravatar.cc/150?img=11';

  final List<Map<String, String>> _storyData = [
    {'username': 'Your Story', 'imageUrl': 'https://i.pravatar.cc/150?img=11'},
    {'username': 'blythe', 'imageUrl': 'https://i.pravatar.cc/150?img=11'},
    {'username': 'yayang_', 'imageUrl': 'https://i.pravatar.cc/150?img=12'},
    {'username': 'selena_g', 'imageUrl': 'https://i.pravatar.cc/150?img=13'},
    {'username': 'joven', 'imageUrl': 'https://i.pravatar.cc/150?img=14'},
    {'username': 'shaina', 'imageUrl': 'https://i.pravatar.cc/150?img=15'},
    {'username': 'kaila', 'imageUrl': 'https://i.pravatar.cc/150?img=16'},
    {'username': 'supremo_dp', 'imageUrl': 'https://i.pravatar.cc/150?img=17'},
    {'username': 'rei', 'imageUrl': 'https://i.pravatar.cc/150?img=18'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserName = userDoc.data()?['username']?.toString() ?? 'user';
          _currentUserProfileImage = userDoc.data()?['profileImageUrl']?.toString() ?? 'https://i.pravatar.cc/150?u=${user.uid}';
        });
      }
    }
  }

  Future<void> _handlePost(String cap, List<String> urls, String loc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Save post
    await FirebaseFirestore.instance.collection('posts').add({
      'username': _currentUserName,
      'userProfileImage': _currentUserProfileImage,
      'caption': cap,
      'postImageUrls': urls,
      'location': loc,
      'timestamp': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'isSaved': false,
      'comments': [],
      'reaction': 'None',
      'userId': user.uid,
    });

    // 2. Notify followers
    try {
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in followersSnapshot.docs) {
        final followerId = doc.id;
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(followerId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'type': 'post',
          'fromId': user.uid,
          'fromName': _currentUserName,
          'fromImage': _currentUserProfileImage,
          'timestamp': FieldValue.serverTimestamp(),
          'message': urls.isEmpty ? 'shared a new thread.' : 'shared a new post.',
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error notifying followers: $e");
    }

    setState(() {
      if (urls.isEmpty) {
        _selectedIndex = 8;
      } else {
        _selectedIndex = 0;
      }
    });
  }

  Future<void> _handleReaction(Post post, String reaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Update Post
    await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
      'reaction': reaction,
      'likesCount': reaction != 'None' ? post.likesCount + 1 : post.likesCount - (post.likesCount > 0 ? 1 : 0),
    });

    // 2. Notify Post Owner
    if (reaction != 'None') {
      try {
        final postDoc = await FirebaseFirestore.instance.collection('posts').doc(post.id).get();
        final postOwnerId = postDoc.data()?['userId']?.toString();

        if (postOwnerId != null && postOwnerId != user.uid) {
          String reactEmoji = '❤️';
          if (reaction == 'Haha') reactEmoji = '😆';
          if (reaction == 'Wow') reactEmoji = '😮';
          if (reaction == 'Sad') reactEmoji = '😢';
          if (reaction == 'Angry') reactEmoji = '😡';

          await FirebaseFirestore.instance
              .collection('users')
              .doc(postOwnerId)
              .collection('notifications')
              .add({
            'type': 'reaction',
            'fromId': user.uid,
            'fromName': _currentUserName,
            'fromImage': _currentUserProfileImage,
            'timestamp': FieldValue.serverTimestamp(),
            'message': 'reacted $reactEmoji to your post.',
            'postId': post.id,
          });
        }
      } catch (e) {
        debugPrint("Error sending reaction notification: $e");
      }
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: widget.currentThemeMode == ThemeMode.dark,
              onChanged: (bool value) {
                widget.onThemeChanged(value);
                Navigator.pop(context);
              },
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        List<Post> allPosts = [];
        if (snapshot.hasData) {
          allPosts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Post(
              id: doc.id,
              username: data['username']?.toString() ?? '',
              userProfileImage: data['userProfileImage']?.toString() ?? '',
              location: data['location']?.toString() ?? '',
              postImageUrls: List<String>.from(data['postImageUrls'] ?? []),
              caption: data['caption']?.toString() ?? '',
              timeAgo: 'Just now', 
              reaction: data['reaction']?.toString() ?? 'None',
              likesCount: int.tryParse(data['likesCount']?.toString() ?? '0') ?? 0,
              isSaved: data['isSaved'] == true,
              comments: List<String>.from(data['comments'] ?? []),
            );
          }).toList();
        }

        final List<Widget> pages = [
          HomePage(
            posts: allPosts.where((p) => p.postImageUrls.isNotEmpty).toList(),
            stories: _storyData,
            onReact: (index, reaction) {
              final post = allPosts.where((p) => p.postImageUrls.isNotEmpty).toList()[index];
              _handleReaction(post, reaction);
            },
            onComment: (index, comment) {
              final post = allPosts.where((p) => p.postImageUrls.isNotEmpty).toList()[index];
              FirebaseFirestore.instance.collection('posts').doc(post.id).update({
                'comments': FieldValue.arrayUnion(["$_currentUserName: $comment"]),
              });
            },
            onSave: (index) {
              final post = allPosts.where((p) => p.postImageUrls.isNotEmpty).toList()[index];
              FirebaseFirestore.instance.collection('posts').doc(post.id).update({
                'isSaved': !post.isSaved,
              });
            },
            onDirectMessage: () => setState(() => _selectedIndex = 5),
          ),
          const ExploreScreen(),
          AddPostScreen(
              onPost: _handlePost,
              onAddStory: (url) => setState(() => _storyData.insert(1, {'username': 'Your Story', 'imageUrl': url})),
              onClose: () => setState(() => _selectedIndex = 0)),
          const ReelsScreen(),
          ProfileScreen(
            allPosts: allPosts,
            onDeletePost: (id) => FirebaseFirestore.instance.collection('posts').doc(id).delete(),
            onReact: (i, r) {}, 
            onComment: (i, c) {}, 
            onSave: (i) {},
          ),
          MessagesScreen(stories: _storyData),
          NotificationsScreen(),
          const SearchScreen(),
          ThreadsScreen(threads: allPosts.where((p) => p.postImageUrls.isEmpty).toList()),
        ];

        return Scaffold(
          body: Row(
            children: [
              if (isWeb) _buildSidebar(context),
              Expanded(
                child: Container(
                  alignment: Alignment.topCenter,
                  color: Theme.of(context).scaffoldBackgroundColor,
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
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarHovered = true),
      onExit: (_) => setState(() => _isSidebarHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSidebarHovered ? 240 : 80,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSidebarHovered
                      ? Text('Snaptalk', key: const ValueKey('text'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface))
                      : Icon(Icons.camera_alt_outlined, key: const ValueKey('icon'), size: 30, color: colorScheme.onSurface),
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
    final colorScheme = Theme.of(context).colorScheme;
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? (_selectedIndex == 8 ? 4 : 0) : _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.onSurface,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final colorScheme = Theme.of(context).colorScheme;

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
            color: isSelected ? colorScheme.surfaceVariant : (_isItemHovered ? colorScheme.surfaceVariant.withOpacity(0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: widget.isSidebarHovered ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              widget.label == 'Profile'
                  ? CircleAvatar(radius: 14, backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), child: isSelected ? Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.onSurface, width: 2))) : null)
                  : (widget.badge != null
                  ? Badge(label: Text(widget.badge!), child: Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28, color: colorScheme.onSurface))
                  : Icon(isSelected ? widget.activeIcon : widget.inactiveIcon, size: 28, color: colorScheme.onSurface)),
              if (widget.isSidebarHovered)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      widget.label,
                      style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: colorScheme.onSurface),
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