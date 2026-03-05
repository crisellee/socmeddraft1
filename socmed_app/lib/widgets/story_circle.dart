import 'package:flutter/material.dart';

class StoryCircle extends StatefulWidget {
  final String username;
  final String imageUrl;
  final bool isMe;

  const StoryCircle({
    super.key,
    required this.username,
    required this.imageUrl,
    this.isMe = false,
  });

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Sinisiguro na sakto lang ang height
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: _isHovered ? 1.05 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.isMe 
                    ? null 
                    : const LinearGradient(
                        colors: [
                          Color(0xFFFBAA47),
                          Color(0xFFD91A46),
                          Color(0xFFA60F93),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                  color: widget.isMe ? Colors.grey[300] : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28, // Binawasan ko ng konti para safe sa overflow
                    backgroundImage: NetworkImage(widget.imageUrl),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                widget.isMe ? 'Your Story' : widget.username,
                style: TextStyle(
                  fontSize: 11, // Binawasan ang size para magkasya
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1, // Sinisiguro na isang line lang
              ),
            ),
          ],
        ),
      ),
    );
  }
}
