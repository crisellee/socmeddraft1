class Post {
  final String id;
  final String username;
  final String userProfileImage;
  final String location;
  final List<String> postImageUrls; // Support multiple images
  final String caption;
  final String timeAgo;
  String reaction; 
  int likesCount;
  bool isSaved;
  final List<String> comments;

  Post({
    required this.id,
    required this.username,
    required this.userProfileImage,
    this.location = '',
    required this.postImageUrls,
    required this.caption,
    required this.timeAgo,
    this.reaction = 'None',
    this.likesCount = 0,
    this.isSaved = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}
