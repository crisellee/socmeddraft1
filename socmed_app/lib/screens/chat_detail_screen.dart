import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ai_service.dart';
import 'dart:typed_data';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  Color _bubbleColor = Colors.blue;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AiService _aiService = AiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isAiTyping = false;

  // ✅ FIRESTORE: SAVE MESSAGE
  Future<void> _saveMessage(String text, {String? type}) async {
    final messageData = {
      'senderId': 'currentUser',
      'text': text,
      'type': type ?? 'text',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chats')
        .doc(widget.conversation.id)
        .collection('messages')
        .add(messageData);
  }

  // ✅ AI RESPONSE LOGIC
  Future<void> _handleAiResponse(String userMessage, {Uint8List? imageBytes, Uint8List? audioBytes}) async {
    if (widget.conversation.id != 'ai_buddy') return;

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
          .doc(widget.conversation.id)
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
                Share.share("Chat with ${widget.conversation.username} on SocMed App!");
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
                var snapshots = await _firestore.collection('chats').doc(widget.conversation.id).collection('messages').get();
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
      if (widget.conversation.id == 'ai_buddy') _handleAiResponse("", imageBytes: bytes);
    }
  }

  void _handleSendMessage() {
    final String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _saveMessage(text);
      _messageController.clear();
      if (widget.conversation.id == 'ai_buddy') _handleAiResponse(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.conversation.userProfileImage)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.username, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                if (_isAiTyping) const Text("AI is thinking...", style: TextStyle(color: Colors.purple, fontSize: 11)),
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
                  .doc(widget.conversation.id)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _isAiTyping ? docs.length + 1 : docs.length,
                  itemBuilder: (context, index) {
                    if (_isAiTyping && index == 0) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text("Typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                        ),
                      );
                    }

                    final data = docs[_isAiTyping ? index - 1 : index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == 'currentUser';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? _bubbleColor : (data['senderId'] == 'ai_buddy' ? Colors.purple.withOpacity(0.1) : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(data['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: _handleImagePick),
                Expanded(
                  child: TextField(
                    controller: _messageController,
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
