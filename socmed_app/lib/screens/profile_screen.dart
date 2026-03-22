import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final List<Post> allPosts;
  final Function(String) onDeletePost;
  final Function(int, String) onReact;
  final Function(int, String) onComment;
  final Function(int) onSave;

  const ProfileScreen({
    super.key,
    required this.allPosts,
    required this.onDeletePost,
    required this.onReact,
    required this.onComment,
    required this.onSave,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedTabIndex = 0; // 0: Posts, 1: Reels, 2: Threads, 3: Saved

  String _userName = 'kriselz_';
  String _fullName = 'Krisel';
  String _bio = 'Digital Creator\nLiving my best life ✨';
  String _profileImageUrl = 'https://i.pravatar.cc/150?img=11';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc.data()?['username'] ?? 'user';
          _fullName = userDoc.data()?['fullName'] ?? '';
          _bio = userDoc.data()?['bio'] ?? '';
          _profileImageUrl = userDoc.data()?['profileImageUrl'] ?? 'https://i.pravatar.cc/150?u=${currentUser!.uid}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: EDIT PROFILE ---
  void _editProfile() {
    TextEditingController nameController = TextEditingController(text: _fullName);
    TextEditingController bioController = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (currentUser != null) {
                await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                  'fullName': nameController.text.trim(),
                  'bio': bioController.text.trim(),
                });
                setState(() {
                  _fullName = nameController.text;
                  _bio = bioController.text;
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: SHOW DELETE OPTIONS (CONSISTENT DESIGN) ---
  void _showProfilePostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (post.username == _userName)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Close detail screen
                  widget.onDeletePost(post.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: post.postImageUrls.isNotEmpty ? post.postImageUrls[0] : "Check out this post by ${post.username}"));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              },
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final userPosts = widget.allPosts.where((p) => p.username == _userName).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Stats & Avatar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 40, backgroundImage: NetworkImage(_profileImageUrl)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(userPosts.length.toString(), 'Posts'),
                        _buildStatColumn('1.2k', 'Followers'),
                        _buildStatColumn('350', 'Following'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bio & Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_bio),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _editProfile,
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Share Profile', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            // Tab Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabIcon(Icons.grid_on, 0),
                _buildTabIcon(Icons.movie_outlined, 1),
                _buildTabIcon(Icons.alternate_email, 2),
                _buildTabIcon(Icons.bookmark_border, 3),
              ],
            ),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index) {
    return IconButton(
      icon: Icon(icon, color: _selectedTabIndex == index ? Colors.black : Colors.grey),
      onPressed: () => setState(() => _selectedTabIndex = index),
    );
  }

  Widget _buildTabContent() {
    final myPosts = widget.allPosts.where((p) => p.username == _userName).toList();
    List<Post> currentList = [];

    if (_selectedTabIndex == 0) currentList = myPosts.where((p) => p.postImageUrls.isNotEmpty).toList();
    else if (_selectedTabIndex == 2) currentList = myPosts.where((p) => p.postImageUrls.isEmpty).toList();
    else if (_selectedTabIndex == 3) currentList = widget.allPosts.where((p) => p.isSaved).toList();

    if (_selectedTabIndex == 1) return const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text("No Reels yet")));

    if (currentList.isEmpty) return const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text("No items to show")));

    if (_selectedTabIndex == 2) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: currentList.length,
        itemBuilder: (context, index) => ListTile(
          onTap: () => _showPostDetail(currentList[index]),
          leading: CircleAvatar(backgroundImage: NetworkImage(currentList[index].userProfileImage)),
          title: Text(currentList[index].username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(currentList[index].caption, maxLines: 1),
          trailing: const Icon(Icons.chevron_right, size: 16),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final post = currentList[index];
        return InkWell(
          onTap: () => _showPostDetail(post),
          child: Image.network(post.postImageUrls[0], fit: BoxFit.cover),
        );
      },
    );
  }

  void _showPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(post.postImageUrls.isEmpty ? 'Thread' : 'Post'), 
            backgroundColor: Colors.white, 
            foregroundColor: Colors.black,
            elevation: 0.5
          ),
          body: ListView(
            children: [
              PostCard(
                post: post,
                onReact: (react) => widget.onReact(widget.allPosts.indexOf(post), react),
                onComment: (comment) => widget.onComment(widget.allPosts.indexOf(post), comment),
                onSave: () => widget.onSave(widget.allPosts.indexOf(post)),
                onMoreTap: () => _showProfilePostOptions(post),
                onDelete: post.username == _userName ? () {
                  widget.onDeletePost(post.id);
                  Navigator.pop(context);
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
