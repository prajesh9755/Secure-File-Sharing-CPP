import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class CustomScanner {
  // --- MAIN FUNCTION ---
  static Future<void> startScan(BuildContext context) async {
    try {
      // 1. Open Camera for Multi-page Scan
      List<String>? images = await CunningDocumentScanner.getPictures();
      
      if (images != null && images.isNotEmpty) {
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
          const SnackBar(content: Text("PDF Uploaded Successfully!")),
        );
      }
    } catch (e) {
      print("Scanner Error: $e");
    }
  }

  // --- CONVERT IMAGES TO PDF ---
  static Future<File> _convertToPdf(List<String> images, String name) async {
  final pdf = pw.Document();

  for (var path in images) {
    // 1. COMPRESS THE IMAGE FIRST (Deep Compression)
    final targetPath = path.replaceAll(".jpg", "_compressed.jpg");
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
  static Future<void> _uploadToFirebase(File file, String name) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    final ref = FirebaseStorage.instance
        .ref("user_data")
        .child(email)
        .child("$name.pdf");

    await ref.putFile(file);
  }

  // --- UI DIALOGS ---
  static Future<String?> _showNameDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter PDF Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "e.g. My_Documents")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Create PDF")),
        ],
      ),
    );
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}