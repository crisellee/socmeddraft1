import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ai_service.dart';
import 'dart:typed_data';

class ChatDetailScreen extends StatefulWidget {
  final String contactName;
  final String contactImage;
  final String contactUid;
  final String? chatId;

  const ChatDetailScreen({
    super.key, 
    required this.contactName, 
    required this.contactImage,
    required this.contactUid,
    this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  Color _bubbleColor = Colors.blue;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AiService _aiService = AiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isAiTyping = false;

  String get _effectiveChatId {
    if (widget.chatId != null) return widget.chatId!;
    List<String> ids = [_auth.currentUser?.uid ?? 'guest', widget.contactUid];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _saveMessage(String text, {String? type}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageData = {
      'senderId': user.uid,
      'senderName': user.displayName ?? 'User',
      'text': text,
      'type': type ?? 'text',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chats')
        .doc(_effectiveChatId)
        .collection('messages')
        .add(messageData);
    
    await _firestore.collection('chats').doc(_effectiveChatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': [user.uid, widget.contactUid],
      'names': {
        user.uid: user.displayName ?? 'User',
        widget.contactUid: widget.contactName,
      },
      'images': {
        user.uid: user.photoURL ?? '',
        widget.contactUid: widget.contactImage,
      }
    }, SetOptions(merge: true));
  }

  Future<void> _handleAiResponse(String userMessage, {Uint8List? imageBytes, Uint8List? audioBytes}) async {
    if (widget.contactUid != 'ai_buddy') return;

    setState(() => _isAiTyping = true);

    String response;
    if (imageBytes != null) {
      response = await _aiService.getAiResponseWithImage(userMessage, imageBytes);
    } else if (audioBytes != null) {
      response = await _aiService.getAiResponseWithAudio(userMessage, audioBytes);
    } else {
      response = await _aiService.getAiResponse(userMessage);
    }

    if (mounted) {
      await _firestore
          .collection('chats')
          .doc(_effectiveChatId)
          .collection('messages')
          .add({
        'senderId': 'ai_buddy',
        'text': response,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _isAiTyping = false);
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Change Bubble Color'),
              onTap: () {
                Navigator.pop(context);
                _showColorPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Chat Profile'),
              onTap: () {
                Navigator.pop(context);
                Share.share("Chat with ${widget.contactName} on SnapTalk Buddy!");
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred, color: Colors.red),
              title: const Text('Report User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User reported.")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              title: const Text('Clear Conversation', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final batch = _firestore.batch();
                var snapshots = await _firestore.collection('chats').doc(_effectiveChatId).collection('messages').get();
                for (var doc in snapshots.docs) { batch.delete(doc.reference); }
                await batch.commit();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conversation cleared.")));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Color"),
        content: Wrap(
          spacing: 10,
          children: [Colors.blue, Colors.purple, Colors.pink, Colors.green, Colors.orange].map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _bubbleColor = color);
                Navigator.pop(context);
              },
              child: CircleAvatar(backgroundColor: color, radius: 20),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleImagePick() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      await _saveMessage("IMG:${image.path}", type: 'image');
      if (widget.contactUid == 'ai_buddy') _handleAiResponse("", imageBytes: bytes);
    }
  }

  void _handleSendMessage() {
    final String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _saveMessage(text);
      _messageController.clear();
      if (widget.contactUid == 'ai_buddy') _handleAiResponse(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.contactImage)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contactName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                if (_isAiTyping) const Text("Thinking...", style: TextStyle(color: Colors.purple, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _showMoreOptions),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_effectiveChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == user?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? _bubbleColor : (data['senderId'] == 'ai_buddy' ? Colors.purple.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[200])),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(data['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, 
              border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!))
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: _handleImagePick),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(hintText: "Message...", border: InputBorder.none),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _handleSendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
