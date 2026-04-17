import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPhotoEvidenceScreen extends StatefulWidget {
  final String evidenceId;
  final Function(List<String>) onPhotosAdded;

  const AddPhotoEvidenceScreen({
    super.key,
    required this.evidenceId,
    required this.onPhotosAdded,
  });

  @override
  State<AddPhotoEvidenceScreen> createState() => _AddPhotoEvidenceScreenState();
}

class _AddPhotoEvidenceScreenState extends State<AddPhotoEvidenceScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Photo Evidence'),
        backgroundColor: Colors.blue[700],
        actions: [
          if (_photos.isNotEmpty)
            TextButton.icon(
              onPressed: _savePhotos,
              icon: Icon(Icons.save, color: Colors.white),
              label: Text('Save (${_photos.length})', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Photo Evidence Tips:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Take clear, well-lit photos', style: TextStyle(fontSize: 13, color: Colors.blue[800])),
                Text('• Include context (location, date)', style: TextStyle(fontSize: 13, color: Colors.blue[800])),
                Text('• Photos are timestamped automatically', style: TextStyle(fontSize: 13, color: Colors.blue[800])),
                Text('• All photos are encrypted', style: TextStyle(fontSize: 13, color: Colors.blue[800])),
              ],
            ),
          ),
          Expanded(
            child: _photos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No photos added yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text('Use the buttons below to add photos', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photos[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.close, size: 18, color: Colors.white),
                                onPressed: () => _removePhoto(index),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                DateTime.now().toString().substring(0, 16),
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Choose from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _photos.add(photo));
    }
  }

  Future<void> _pickFromGallery() async {
    final photos = await _picker.pickMultiImage();
    if (photos.isNotEmpty) {
      setState(() => _photos.addAll(photos));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _savePhotos() {
    final paths = _photos.map((p) => p.path).toList();
    widget.onPhotosAdded(paths);
    Navigator.pop(context);
  }
}
