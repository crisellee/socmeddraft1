import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // I-update ang function para tumanggap ng bytes sa halip na path lang
  Future<List<String>> uploadPostImages(List<Uint8List> imagesBytes) async {
    List<String> downloadUrls = [];
    for (Uint8List bytes in imagesBytes) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('posts/$fileName');
      
      // putData ay gumagana sa parehong Web at Mobile
      UploadTask uploadTask = ref.putData(bytes);

      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  // Save Post to Firestore
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

  // Stream of Posts
  Stream<List<Post>> getPosts() {
    return _db.collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Post(
          id: doc.id,
          username: data['username'] ?? '',
          userProfileImage: data['userProfileImage'] ?? '',
          location: data['location'] ?? '',
          postImageUrls: List<String>.from(data['postImageUrls'] ?? []),
          caption: data['caption'] ?? '',
          timeAgo: 'Just now',
          likesCount: data['likesCount'] ?? 0,
          isSaved: data['isSaved'] ?? false,
          comments: List<String>.from(data['comments'] ?? []),
        );
      }).toList();
    });
  }
}
