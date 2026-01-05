// s3_replacement_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Core Storage
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Required for the File object in putFile()

// Initialize Storage Reference
final _storage = FirebaseStorage.instance;
// Get the current user's UID (must be called after login)
// final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

// Reference to the user's specific folder (secure)
// The path structure will be: user_films/<user_uid>/<file_name>
// NOTE: This definition MUST be moved inside the State class if the user logs out and logs back in.
final _userStorageRef = _storage.ref().child('user_films/$currentUserEmail'); 

// Placeholder for safePrint if it's not defined globally
void safePrint(String message) {
  debugPrint(message);
}

class S3ReplacementScreen extends StatefulWidget {
  const S3ReplacementScreen({super.key});

  @override
  State<S3ReplacementScreen> createState() => _S3ReplacementScreenState();
}

class _S3ReplacementScreenState extends State<S3ReplacementScreen> {
  String _status = 'Select files to upload...';
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  
  // State for listing uploaded files (Firebase only lists Reference items)
  List<Reference> _uploadedItems = []; 
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    // Start listing files when the screen loads
    _loadFiles(); 
  }

  // --- Utility Function: Get Download URL ---
  Future<String> _getDownloadUrl(Reference fileRef) async {
    try {
      final String url = await fileRef.getDownloadURL(); 
      return url;
    } on FirebaseException catch (e) {
      return 'Error generating URL: ${e.code}';
    }
  }

  // --- Step 1: Select Files ---
  Future<void> _pickFiles() async {
    _selectedFiles.clear();
    setState(() => _status = 'Selecting files...');

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      _selectedFiles = result.files;
    }
    setState(() => _status = '${_selectedFiles.length} files selected.');
  }

  // --- Step 2: Upload Files ---
  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty || currentUserEmail == null) {
      setState(() => _status = 'No files selected or user ID missing.');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Uploading 0 of ${_selectedFiles.length} files...';
    });
    int uploadedCount = 0;

    await Future.wait(_selectedFiles.map((file) async {
      try {
        final filePath = file.path!;
        // Create a reference to the specific file path inside the user's folder
        final fileRef = _userStorageRef.child(file.name); 
        
        // Start the upload task
        final uploadTask = fileRef.putFile(File(filePath)); 
        
        // Wait for the upload to complete
        await uploadTask.whenComplete(() {
          uploadedCount++;
          // safePrint('File ${file.name} uploaded.');
        });

      } on FirebaseException catch (e) {
        safePrint('Upload failed for ${file.name}: ${e.code}');
      }
    }));
    
    // Refresh the list after uploads are done
    await _loadFiles(); 
    
    setState(() {
      _isLoading = false;
      _selectedFiles = [];
      _status = '✅ Upload Complete! Total: $uploadedCount.';
    });
  }

  // --- Step 3: List Files ---
  Future<void> _loadFiles() async {
    if (currentUserEmail == null) return;
    setState(() => _isLoadingList = true);
    
    try {
      // listAll() returns a ListResult object for the user's folder
      final ListResult result = await _userStorageRef.listAll();
      
      setState(() {
        _uploadedItems = result.items; // items contains a list of Reference objects
        _status = 'Found ${_uploadedItems.length} uploaded files.';
      });
      
    } on FirebaseException catch (e) {
      safePrint('Error listing files: ${e.code}');
      setState(() => _status = 'Error listing files: ${e.code}');
    } finally {
      setState(() => _isLoadingList = false);
    }
  }


  // --- Step 4: Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Add a refresh button for the list
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadFiles,
        ),
        title: const Text('Firebase Film Uploader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Status Display ---
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),

              // --- Pick Files Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.movie),
                label: const Text('SELECT FILMS'),
                onPressed: _pickFiles,
              ),
              const SizedBox(height: 10),
              
              // --- Upload Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: Text(_isLoading ? 'Uploading...' : 'UPLOAD (${_selectedFiles.length})'),
                onPressed: _selectedFiles.isNotEmpty && !_isLoading ? _uploadFiles : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              
              const SizedBox(height: 30),
             // --- Uploaded Files List ---
              Text(
                'Uploaded Films:', 
                style: Theme.of(context).textTheme.titleLarge,
              ),

              if (_isLoadingList)
                const LinearProgressIndicator(),

              Expanded(
                child: ListView.builder(
                  itemCount: _uploadedItems.length,
                  itemBuilder: (context, index) {
                    final fileRef = _uploadedItems[index];
                    final fileName = fileRef.name;
                    
                    return ListTile(
                      title: Text(fileName),
                      subtitle: const Text('Tap to copy permanent URL'),
                      trailing: const Icon(Icons.share),
                      onTap: () async {
                        // Get the public download URL
                        final shareUrl = await _getDownloadUrl(fileRef);

                        // Copy to clipboard
                        await Clipboard.setData(ClipboardData(text: shareUrl));

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ URL copied: $shareUrl'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            ],
          ),
        ),
    );
  }
}