import 'package:flutter/material.dart';

class StoryItem extends StatelessWidget {
  final String name;
  final String image;
  final bool isMe;

  const StoryItem({
    required this.name,
    required this.image,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe 
                ? null 
                : LinearGradient(
                    colors: [
                      Color(0xFFFBAA47),
                      Color(0xFFD91A46),
                      Color(0xFFA60F93),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(image),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isMe ? 'Your Story' : name,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
