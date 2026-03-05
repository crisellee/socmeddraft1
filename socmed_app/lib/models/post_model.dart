class Post {
  final String name;
  final String profile;
  final String time;
  final String postImage;
  final String text;
  bool liked;
  List<String> comments;

  Post({
    required this.name,
    required this.profile,
    required this.time,
    required this.postImage,
    required this.text,
    this.liked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}
