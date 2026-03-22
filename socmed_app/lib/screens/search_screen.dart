import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<Map<String, dynamic>> _recentSearches = [
    {
      'username': 'blythe',
      'fullName': 'Andrea Brillantes • Following',
      'imageUrl': 'https://i.pravatar.cc/150?img=11',
      'isVerified': true,
      'isUser': true,
    },
    {
      'username': 'blythe',
      'isUser': false,
    },
    {
      'username': 'shaina_gorgeous',
      'fullName': 'Shaina L. Bautista',
      'imageUrl': 'https://i.pravatar.cc/150?img=5',
      'isUser': true,
    },
    {
      'username': 'shaina_gorgeous',
      'isUser': false,
    },
    {
      'username': 'joven',
      'fullName': 'joven • Following',
      'imageUrl': 'https://i.pravatar.cc/150?img=8',
      'isUser': true,
    },
    {
      'username': 'kailaestrada',
      'fullName': 'Kaila Estrada • 1M followers',
      'imageUrl': 'https://i.pravatar.cc/150?img=9',
      'isVerified': true,
      'isUser': true,
    },
    {
      'username': 'supremo_dp',
      'fullName': 'Daniel Padilla • 6.4M followers',
      'imageUrl': 'https://i.pravatar.cc/150?img=10',
      'isVerified': true,
      'isUser': true,
    },
    {
      'username': 'rei ',
      'isUser': false,
    },
    {
      'username': 'raine',
      'isUser': false,
    },
  ];

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
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.cancel, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
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
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: item['isUser']
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: item['username'] == 'blythe'
                                ? const LinearGradient(colors: [Colors.yellow, Colors.red, Colors.purple])
                                : null,
                            ),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(item['imageUrl']),
                            ),
                          )
                        : const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFF5F5F5),
                            child: Icon(Icons.search, color: Colors.black, size: 25),
                          ),
                    title: Row(
                      children: [
                        Text(
                          item['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (item['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 15),
                        ]
                      ],
                    ),
                    subtitle: item['fullName'] != null ? Text(item['fullName']) : null,
                    trailing: const Icon(Icons.close, color: Colors.grey),
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
