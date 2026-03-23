import 'package:flutter/material.dart';

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
  final TextEditingController _imageUrlController = TextEditingController();
  
  String _location = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    final String text = _captionController.text.trim();
    final String url = _imageUrlController.text.trim();
    
    if (text.isEmpty && url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something or provide an image link')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      if (url.isNotEmpty) {
        imageUrls = [url];
      }

      widget.onPost(
        text,
        imageUrls,
        _location,
      );

      _captionController.clear();
      _imageUrlController.clear();
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
            // IMAGE LINK INPUT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      hintText: 'Paste Image Link here...',
                      prefixIcon: const Icon(Icons.link),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                  const SizedBox(height: 15),
                  if (_imageUrlController.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrlController.text,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(child: Text('Invalid image link', style: TextStyle(color: Colors.red))),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image preview will appear here', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _captionController,
                decoration: const InputDecoration(hintText: 'Write a caption...', border: InputBorder.none),
                maxLines: 4,
              ),
            ),
            
            const Divider(),
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
            const Divider(),
          ],
        ),
      ),
    );
  }
}
