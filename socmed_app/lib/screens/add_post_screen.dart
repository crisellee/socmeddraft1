import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddPostScreen extends StatefulWidget {
  final Function(String, List<String>, String) onPost; // Supports multiple images
  final VoidCallback onClose;

  const AddPostScreen({super.key, required this.onPost, required this.onClose});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _pickedImages = []; // List for multiple images
  String _location = '';
  String _music = 'None';

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages = images;
      });
    }
  }

  void _addLocation() {
    TextEditingController locController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: locController,
          decoration: const InputDecoration(hintText: 'Enter city or place'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _location = locController.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addMusic() {
    List<String> songs = ['Lo-fi Beats', 'Summer Vibes', 'Morning Coffee', 'Chill Mix'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Music', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...songs.map((song) => ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(song),
              onTap: () {
                setState(() => _music = song);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              if (_captionController.text.isNotEmpty && _pickedImages.isNotEmpty) {
                widget.onPost(
                  _captionController.text, 
                  _pickedImages.map((img) => img.path).toList(), 
                  _location
                );
                _captionController.clear();
              } else if (_pickedImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one image')),
                );
              }
            },
            child: const Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: _pickedImages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Tap to select photos', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : PageView.builder(
                        itemCount: _pickedImages.length,
                        itemBuilder: (context, index) {
                          String path = _pickedImages[index].path;
                          return kIsWeb 
                              ? Image.network(path, fit: BoxFit.cover)
                              : Image.file(File(path), fit: BoxFit.cover);
                        },
                      ),
              ),
            ),
            if (_pickedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${_pickedImages.length} photos selected. Swipe to preview.'),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                ),
                maxLines: 4,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Add Location'),
              subtitle: _location.isNotEmpty ? Text(_location, style: const TextStyle(color: Colors.blue)) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: _addLocation,
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Tag People'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.purple),
              title: const Text('Add Music'),
              subtitle: _music != 'None' ? Text(_music, style: const TextStyle(color: Colors.blue)) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: _addMusic,
            ),
          ],
        ),
      ),
    );
  }
}
