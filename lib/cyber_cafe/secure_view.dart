// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class SecureViewer extends StatelessWidget {
//   final String url;
//   final bool isPdf;

//   const SecureViewer({super.key, required this.url, required this.isPdf});

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // 1. The Document Content
//         Positioned.fill(
//           child: isPdf
//               ? SfPdfViewer.network(url)
//               : InteractiveViewer(
//                   child: Image.network(url, fit: BoxFit.contain),
//                 ),
//         ),

//         // 2. Visual Security: Semi-transparent Watermark
//         // This prevents clean screenshots/photos on PC
//         IgnorePointer(
//           child: Center(
//             child: Opacity(
//               opacity: 0.5,
//               child: RotationTransition(
//                 turns: const AlwaysStoppedAnimation(-30 / 360),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: List.generate(3, (index) => const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 40),
//                     child: Text(
//                       "CONFIDENTIAL - CYBER VIEW ONLY",
//                       style: TextStyle(
//                         fontSize: 40,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                   )),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:typed_data';
import 'package:cpp/utils/encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class SecureViewer extends StatelessWidget {
  final String url;
  final bool isPdf;
  final String displayName; // Added for key lookup
  final String studentEmail; // Added for key lookup

  const SecureViewer({
    super.key, 
    required this.url, 
    required this.isPdf, 
    required this.displayName, 
    required this.studentEmail
  });

  // Decryption helper internal to this widget
  Future<Uint8List?> _getDecryptedData() async {
    try {
      final keyDoc = await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(studentEmail)
          .collection('keys')
          .doc(displayName)
          .get();

      if (!keyDoc.exists) return null;
      String fileKey = keyDoc.data()!['key'];

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      // Using your existing EncryptionService
      return EncryptionService.decryptData(response.bodyBytes, fileKey);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Document Content (UPDATED TO HANDLE DECRYPTION)
        Positioned.fill(
          child: FutureBuilder<Uint8List?>(
            future: _getDecryptedData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orange));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("Error: Could not decrypt file"));
              }

              final bytes = snapshot.data!;
              return isPdf
                  ? SfPdfViewer.memory(bytes) // Use memory for PDF
                  : InteractiveViewer(
                      child: Image.memory(bytes, fit: BoxFit.contain), // Use memory for Image
                    );
            },
          ),
        ),

        // 2. Visual Security: Semi-transparent Watermark (NOT TOUCHED)
        IgnorePointer(
          child: Center(
            child: Opacity(
              opacity: 0.5,
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(-30 / 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      "CONFIDENTIAL - CYBER VIEW ONLY",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}