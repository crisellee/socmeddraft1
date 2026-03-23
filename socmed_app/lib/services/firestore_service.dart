import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload images to Firebase Storage
  Future<List<String>> uploadPostImages(List<Uint8List> imagesBytes) async {
    List<String> downloadUrls = [];
    for (Uint8List bytes in imagesBytes) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('posts/$fileName');
      
      UploadTask uploadTask = ref.putData(bytes);

      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  // Save Post to Firestore with safety checks
  Future<DocumentReference> createPost({
    required String username,
    required String userProfileImage,
    required String caption,
    required List<String> imageUrls,
    String location = '',
  }) async {
    return await _db.collection('posts').add({
      'username': username,
      'userProfileImage': userProfileImage,
      'caption': caption,
      'postImageUrls': imageUrls,
      'location': location,
      'timestamp': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'isSaved': false,
      'comments': [],
    });
  }

  // Toggle Save Post
  Future<void> toggleSavePost(String postId, bool isSaved) async {
    await _db.collection('posts').doc(postId).update({
      'isSaved': isSaved,
    });
  }

  // Stream of Posts with data validation to prevent TypeErrors
  Stream<List<Post>> getPosts() {
    return _db.collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Safety check: ensure all fields are the correct type
        return Post(
          id: doc.id,
          username: data['username']?.toString() ?? '',
          userProfileImage: data['userProfileImage']?.toString() ?? '',
          location: data['location']?.toString() ?? '',
          postImageUrls: (data['postImageUrls'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
          caption: data['caption']?.toString() ?? '',
          timeAgo: 'Just now', // You can add logic to format the timestamp
          likesCount: int.tryParse(data['likesCount']?.toString() ?? '0') ?? 0,
          isSaved: data['isSaved'] == true,
          comments: (data['comments'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
      }).toList();
    });
  }
}
