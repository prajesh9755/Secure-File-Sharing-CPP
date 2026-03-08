import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpp/utils/encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class GalleryToPdfScreen extends StatefulWidget {
  const GalleryToPdfScreen({super.key});

  @override
  State<GalleryToPdfScreen> createState() => _GalleryToPdfScreenState();
}

class _GalleryToPdfScreenState extends State<GalleryToPdfScreen> {
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/spdy.png', 
                  height: 28, 
                  width: 28, 
                  fit: BoxFit.cover
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gallery to PDF', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ],
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            TextButton(
              onPressed: _createPdf,
              child: const Text(
                'Create PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Curved decoration
          Container(
            height: 120, 
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Instructions card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_library, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Create PDF from Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap the + button to add images from your gallery. Selected images will appear below.',
                          style: TextStyle(
                            color: Colors.white70, 
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Selected images section
                  if (_selectedImages.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Images (${_selectedImages.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2A3A),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAll,
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // Images grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return _buildImageCard(_selectedImages[index], index);
                      },
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    // Empty state
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No images selected yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button below to add images',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Creating PDF...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Floating action button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _pickImage,
          backgroundColor: const Color(0xFF4CA1AF),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Image'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImageCard(String imagePath, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Bottom section with remove button
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Image ${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2A3A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 16,
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

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    
    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _createPdf() async {
    if (_selectedImages.isEmpty) return;

    // Ask for PDF name
    final TextEditingController nameController = TextEditingController();
    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter PDF Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "e.g. My_Gallery_Images"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CA1AF),
              foregroundColor: Colors.white,
            ),
            child: const Text("Create PDF"),
          ),
        ],
      ),
    );

    if (fileName == null || fileName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert images to PDF
      final pdfFile = await _convertToPdf(_selectedImages, fileName);
      
      // Upload to Firebase
      final result = await _uploadToFirebase(pdfFile, fileName);
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> _convertToPdf(List<String> images, String name) async {
    final pdf = pw.Document();

    for (var path in images) {
      // Compress the image
      final targetPath = path.replaceAll(".jpg", "_compressed.jpg").replaceAll(".png", "_compressed.png");
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 25,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedXFile == null) continue;

      // Add to PDF
      final image = pw.MemoryImage(File(compressedXFile.path).readAsBytesSync());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$name.pdf");
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  Future<Map<String, dynamic>> _uploadToFirebase(File file, String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'message': 'Auth failed'};

    try {
      // Generate encryption key
      String fileKey = EncryptionService.generateRandomKey();

      // Encrypt file
      Uint8List fileBytes = await file.readAsBytes();
      Uint8List encryptedBytes = EncryptionService.encryptData(fileBytes, fileKey);

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref("user_data")
          .child(user.email!)
          .child("$name.pdf");
      
      await ref.putData(encryptedBytes);
      String downloadUrl = await ref.getDownloadURL();

      // Save encryption key
      await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(user.email)
          .collection('keys')
          .doc("$name.pdf")
          .set({
        'key': fileKey,
        'name': "$name.pdf",
        'uploadedAt': FieldValue.serverTimestamp(),
        'source': 'gallery',
      });

      return {
        'success': true, 
        'message': '$name uploaded and encrypted!',
        'url': downloadUrl
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
