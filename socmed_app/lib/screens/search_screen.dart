import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';
import '../models/post.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentSearches = [];

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();
      setState(() {
        _searchResults = results.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id; // Siguraduhin na may UID galing sa Document ID
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToUserProfile(Map<String, dynamic> userData) {
    if (!_recentSearches.any((u) => u['uid'] == userData['uid'])) {
      setState(() {
        _recentSearches.insert(0, userData);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileView(userData: userData)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('Search', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                ),
              ),
            ),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                itemCount: _searchController.text.isEmpty ? _recentSearches.length : _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchController.text.isEmpty ? _recentSearches[index] : _searchResults[index];
                  return ListTile(
                    onTap: () => _navigateToUserProfile(item),
                    leading: CircleAvatar(backgroundImage: NetworkImage(item['profileImageUrl'] ?? 'https://i.pravatar.cc/150')),
                    title: Text(item['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['fullName'] ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserProfileView({super.key, required this.userData});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  bool _isFollowing = false;
  bool _hasSentRequest = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    if (currentUser == null) return;
    
    try {
      // Check if already following
      final followDoc = await FirebaseFirestore.instance
          .collection('users').doc(currentUser!.uid)
          .collection('following').doc(widget.userData['uid']).get();
      
      // Check if request is pending
      final requestDoc = await FirebaseFirestore.instance
          .collection('users').doc(widget.userData['uid'])
          .collection('notifications')
          .where('fromId', isEqualTo: currentUser!.uid)
          .where('type', isEqualTo: 'follow_request')
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
          _hasSentRequest = requestDoc.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Error checking follow status: $e");
    }
  }

  Future<void> _handleFollowClick() async {
    if (currentUser == null || _isFollowing || _hasSentRequest) return;

    try {
      // 1. Get Current User Data for Notification
      final meDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final myData = meDoc.data() ?? {};

      // 2. Send Follow Request Notification
      await FirebaseFirestore.instance
          .collection('users').doc(widget.userData['uid'])
          .collection('notifications').add({
        'type': 'follow_request',
        'fromId': currentUser!.uid,
        'fromName': myData['fullName'] ?? currentUser!.displayName ?? 'User',
        'fromUsername': myData['username'] ?? 'user',
        'fromImage': myData['profileImageUrl'] ?? currentUser!.photoURL ?? 'https://i.pravatar.cc/150',
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'wants to follow you.',
        'status': 'pending',
      });

      setState(() => _hasSentRequest = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow request sent!')));
    } catch (e) {
      debugPrint("Error sending follow request: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.userData['username'] ?? 'User')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('username', isEqualTo: widget.userData['username'])
            .snapshots(),
        builder: (context, snapshot) {
          List<Post> userPosts = [];
          if (snapshot.hasData) {
            userPosts = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post(
                id: doc.id,
                username: data['username'] ?? '',
                userProfileImage: data['userProfileImage'] ?? '',
                location: data['location'] ?? '',
                postImageUrls: List<String>.from(data['postImageUrls'] ?? []),
                caption: data['caption'] ?? '',
                timeAgo: 'Now',
              );
            }).toList();
            userPosts.sort((a, b) => b.id.compareTo(a.id)); 
          }

          final imagesOnly = userPosts.where((p) => p.postImageUrls.isNotEmpty).toList();
          final threadsOnly = userPosts.where((p) => p.postImageUrls.isEmpty).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(radius: 40, backgroundImage: NetworkImage(widget.userData['profileImageUrl'] ?? 'https://i.pravatar.cc/150')),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat('Posts', userPosts.length.toString()),
                          _stat('Followers', '0'),
                          _stat('Following', '0'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleFollowClick,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[300] : (_hasSentRequest ? Colors.blue[100] : Colors.blue),
                          foregroundColor: _isFollowing ? Colors.black : Colors.white,
                        ),
                        child: Text(_isFollowing ? 'Following' : (_hasSentRequest ? 'Requested' : 'Follow')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(contactName: widget.userData['username'], contactImage: widget.userData['profileImageUrl'] ?? 'https://i.pravatar.cc/150', contactUid: widget.userData['uid']))),
                        child: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(tabs: [Tab(icon: Icon(Icons.grid_on)), Tab(icon: Icon(Icons.alternate_email))]),
                      Expanded(
                        child: TabBarView(
                          children: [
                            imagesOnly.isEmpty 
                              ? const Center(child: Text("No photos yet"))
                              : GridView.builder(
                                  padding: const EdgeInsets.all(1),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
                                  itemCount: imagesOnly.length,
                                  itemBuilder: (context, i) => Image.network(imagesOnly[i].postImageUrls[0], fit: BoxFit.cover),
                                ),
                            threadsOnly.isEmpty
                              ? const Center(child: Text("No threads yet"))
                              : ListView.builder(
                                  itemCount: threadsOnly.length,
                                  itemBuilder: (context, i) => ListTile(
                                    title: Text(threadsOnly[i].caption),
                                    subtitle: const Text('Thread'),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String count) => Column(children: [Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(label)]);
}
