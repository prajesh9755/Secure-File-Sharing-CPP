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

class ImageToPdfConverter {
  // --- MAIN FUNCTION ---
  static Future<void> startImageSelection(BuildContext context) async {
    try {
      // 1. Pick Images from Gallery
      List<String> images = await _pickImagesFromGallery(context);
      
      if (images.isNotEmpty) {
        // 2. Ask for File Name
        String? fileName = await _showNameDialog(context);
        if (fileName == null || fileName.isEmpty) return;

        // 3. Show Loading
        _showLoading(context);

        // 4. Convert Images to one PDF
        File pdfFile = await _convertToPdf(images, fileName);

        // 5. Upload to Firebase
        await _uploadToFirebase(pdfFile, fileName);

        // 6. Finish
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Created and Uploaded Successfully!")),
        );
      }
    } catch (e) {
      print("Image to PDF Error: $e");
      Navigator.pop(context); // Close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // --- PICK IMAGES FROM GALLERY ---
  static Future<List<String>> _pickImagesFromGallery(BuildContext context) async {
    List<String> selectedImages = [];
    final ImagePicker picker = ImagePicker();
    
    // Allow user to pick multiple images
    while (true) {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Initial quality reduction
        maxWidth: 2048,   // Reduce resolution
        maxHeight: 2048,
      );
      
      if (image == null) break; // User canceled or finished
      
      selectedImages.add(image.path);
      
      // Ask if user wants to add more images
      bool shouldContinue = await _askForMoreImages(context);
      if (!shouldContinue) break;
    }
    
    return selectedImages;
  }

  // --- ASK USER IF THEY WANT TO ADD MORE IMAGES ---
  static Future<bool> _askForMoreImages(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add More Images?"),
        content: const Text("Would you like to add more images to this PDF?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No, Create PDF"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Add More"),
          ),
        ],
      ),
    ) ?? false;
  }

  // --- CONVERT IMAGES TO PDF ---
  static Future<File> _convertToPdf(List<String> images, String name) async {
    final pdf = pw.Document();

    for (var path in images) {
      // 1. COMPRESS THE IMAGE FIRST (Deep Compression)
      final targetPath = path.replaceAll(".jpg", "_compressed.jpg").replaceAll(".png", "_compressed.png");
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 25, // CRITICAL: Lower this (10-30) to hit that 256KB target
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedXFile == null) continue;

      // 2. ADD COMPRESSED BYTES TO PDF
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

    // 3. SAVE THE FINAL PDF
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$name.pdf");
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // --- UPLOAD LOGIC ---
  static Future<Map<String, dynamic>> _uploadToFirebase(File file, String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'message': 'Auth failed'};

    try {
      // 1. Generate a unique key for THIS specific file
      String fileKey = EncryptionService.generateRandomKey();

      // 2. Read and Encrypt the file bytes
      Uint8List fileBytes = await file.readAsBytes();
      Uint8List encryptedBytes = EncryptionService.encryptData(fileBytes, fileKey);

      // 3. Upload Encrypted Bytes to Storage
      final ref = FirebaseStorage.instance
          .ref("user_data")
          .child(user.email!)
          .child("$name.pdf");
      
      await ref.putData(encryptedBytes);
      String downloadUrl = await ref.getDownloadURL();

      // 4. Save the Key to your Vault (so Cyber Side can open it)
      await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(user.email)
          .collection('keys')
          .doc("$name.pdf")
          .set({
        'key': fileKey,
        'name': "$name.pdf",
        'uploadedAt': FieldValue.serverTimestamp(),
        'source': 'gallery', // Track that this came from gallery
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

  // --- UI DIALOGS ---
  static Future<String?> _showNameDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter PDF Name"),
        content: TextField(
          controller: controller, 
          decoration: const InputDecoration(hintText: "e.g. My_Gallery_Images")
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), 
            child: const Text("Create PDF")
          ),
        ],
      ),
    );
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Creating PDF and uploading..."),
          ],
        ),
      ),
    );
  }

  // --- CONVENIENCE METHOD FOR SINGLE IMAGE ---
  static Future<void> convertSingleImageToPdf(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    
    if (image != null) {
      await startImageSelection(context);
    }
  }
}
