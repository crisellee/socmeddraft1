import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _recentSearches = [
    {
      'username': 'blythe',
      'fullName': 'Andrea Brillantes • Following',
      'imageUrl': 'https://i.pravatar.cc/150?img=11',
      'isVerified': true,
      'isUser': true,
    },
    {
      'username': 'shaina_gorgeous',
      'fullName': 'Shaina L. Bautista',
      'imageUrl': 'https://i.pravatar.cc/150?img=5',
      'isUser': true,
    },
  ];

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
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
        _searchResults = results.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error searching users: $e');
    }
  }

  void _removeSearchItem(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                'Search',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                            child: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_searchController.text.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_recentSearches.isNotEmpty)
                      TextButton(
                        onPressed: _clearAll,
                        child: const Text('Clear all',
                            style: TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    final item = _recentSearches[index];
                    return _buildUserListTile(item, index, isRecent: true);
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return _buildUserListTile(user, index, isRecent: false);
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTile(Map<String, dynamic> item, int index, {required bool isRecent}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(item['profileImageUrl'] ?? item['imageUrl'] ?? 'https://i.pravatar.cc/150'),
      ),
      title: Row(
        children: [
          Text(
            item['username'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (item['isVerified'] == true) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 15),
          ]
        ],
      ),
      subtitle: Text(item['fullName'] ?? ''),
      trailing: isRecent
          ? GestureDetector(
              onTap: () => _removeSearchItem(index),
              child: const Icon(Icons.close, color: Colors.grey),
            )
          : null,
      onTap: () {
        // Add to recent searches if not already there
        if (!isRecent) {
          setState(() {
            _recentSearches.insert(0, {
              'username': item['username'],
              'fullName': item['fullName'],
              'imageUrl': item['profileImageUrl'],
              'isVerified': item['isVerified'] ?? false,
              'isUser': true,
            });
            // Keep only last 10
            if (_recentSearches.length > 10) _recentSearches.removeLast();
          });
        }
      },
    );
  }
}
