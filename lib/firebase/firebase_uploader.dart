// firebase_uploader.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To ensure user is logged in

/// Uploads a list of files to Firebase Storage under the user's email path.
///
/// The path structure is: user_data/{email}/{file_name}
///
/// @param files The list of PlatformFile objects to upload (from your selectedFiles list).
/// @param userEmail The authenticated user's email address (must include @ and .).
/// @param onFileCompleted A callback function to report the number of files finished.
/// @returns A map indicating success status and any error messages.
Future<Map<String, dynamic>> uploadUserFiles(
    List<PlatformFile> files,
    String userEmail,
    {required Function(int count) onFileCompleted} // <--- NEW CALLBACK HERE
) async {
    if (files.isEmpty) {
        return {'success': false, 'message': 'No files provided for upload.'};
    }

    final storage = FirebaseStorage.instance;
    int uploadedCount = 0;

    // Use Future.wait to upload files concurrently for better performance
    await Future.wait(files.map((file) async {
        if (file.path == null) {
            print('Skipping file with null path: ${file.name}');
            return;
        }

        try {
            // Define the exact path: user_data/{email}/{file_name}
            final ref = storage.ref().child('user_data/$userEmail/${file.name}');

            // Upload the file
            final File fileToUpload = File(file.path!);
            await ref.putFile(fileToUpload);

            uploadedCount++;
            // <--- NEW: CALL THE CALLBACK AFTER EACH SUCCESSFUL UPLOAD ---
            onFileCompleted(uploadedCount);
            print('Successfully uploaded: ${file.name}');
        } on FirebaseException catch (e) {
            print('Firebase Error uploading ${file.name}: ${e.code}');
        } catch (e) {
            print('Unknown Error uploading ${file.name}: $e');
        }
    }));

    if (uploadedCount > 0) {
        return {'success': true, 'message': 'Successfully uploaded $uploadedCount of ${files.length} file(s).'};
    } else {
        return {'success': false, 'message': 'Failed to upload any files.'};
    }
}