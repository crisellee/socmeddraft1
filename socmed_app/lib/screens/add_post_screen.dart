import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddPostScreen extends StatefulWidget {
  final Function(String, List<String>, String) onPost;
  final Function(String) onAddStory;
  final VoidCallback onClose;

  const AddPostScreen({
    super.key,
    required this.onPost,
    required this.onAddStory,
    required this.onClose,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<XFile> _pickedImages = [];
  String _location = '';
  String _selectedMusic = 'None';
  List<String> _taggedPeople = [];
  bool _isLoading = false;
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages = images.take(10).toList();
        _currentImageIndex = 0;
      });
    }
  }

  Future<void> _handleShare() async {
    final String text = _captionController.text.trim();
    
    // Allow posting if there is either text OR images
    if (text.isEmpty && _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something or select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Pass the data to main.dart logic
      // If _pickedImages is empty, it will be handled as a "Thread" in main.dart
      widget.onPost(
        text,
        _pickedImages.map((img) => img.path).toList(),
        _location,
      );

      _captionController.clear();
      setState(() {
        _pickedImages = [];
        _selectedMusic = 'None';
        _taggedPeople = [];
      });
      widget.onClose();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted successfully!')),
      );
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTagPeopleDialog() {
    TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag People'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: _taggedPeople.map((p) => Chip(
                label: Text(p),
                onDeleted: () => setState(() => _taggedPeople.remove(p)),
              )).toList(),
            ),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(hintText: 'Enter username'),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  setState(() => _taggedPeople.add(val));
                  Navigator.pop(context);
                  _showTagPeopleDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showMusicPicker() {
    final List<String> tracks = ['Happy Vibes', 'Chill Lofi', 'Summer Hits', 'Energetic Rock', 'Piano Solo'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Music', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...tracks.map((track) => ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(track),
              onTap: () {
                setState(() => _selectedMusic = track);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _handleShare,
                child: const Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _captionController,
                decoration: const InputDecoration(hintText: 'What\'s on your mind?', border: InputBorder.none),
                maxLines: 5,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Add Location'),
              subtitle: _location.isNotEmpty ? Text(_location, style: const TextStyle(color: Colors.blue)) : null,
              onTap: () {
                String tempLoc = '';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Location'),
                    content: TextField(onChanged: (v) => tempLoc = v),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(onPressed: () {
                        setState(() => _location = tempLoc);
                        Navigator.pop(context);
                      }, child: const Text('Add')),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Tag People'),
              subtitle: _taggedPeople.isNotEmpty ? Text('${_taggedPeople.length} people tagged') : null,
              onTap: _showTagPeopleDialog,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('Add Music'),
              subtitle: Text(_selectedMusic, style: TextStyle(color: _selectedMusic != 'None' ? Colors.blue : Colors.grey)),
              onTap: _showMusicPicker,
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 250, // Reduced height to focus more on text
      width: double.infinity,
      color: Colors.grey[100],
      child: Stack(
        children: [
          _pickedImages.isEmpty
              ? GestureDetector(
                  onTap: _pickImages,
                  child: const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Add photos (Optional)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )),
                )
              : PageView.builder(
                  itemCount: _pickedImages.length,
                  onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                  itemBuilder: (context, index) {
                    String path = _pickedImages[index].path;
                    return kIsWeb ? Image.network(path, fit: BoxFit.cover) : Image.file(File(path), fit: BoxFit.cover);
                  },
                ),
          if (_pickedImages.length > 1) ...[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                child: Text('${_currentImageIndex + 1}/${_pickedImages.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
          if (_pickedImages.isNotEmpty)
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton.small(
                onPressed: _pickImages,
                backgroundColor: Colors.white,
                child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}