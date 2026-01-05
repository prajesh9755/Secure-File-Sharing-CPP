// file_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class FileViewerScreen extends StatefulWidget {
  final String folderName; // 'user_data' or 'applications'
  const FileViewerScreen({super.key, required this.folderName});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  // --- STATE (UNCHANGED) ---
  List<Reference> _uploadedItems = [];
  bool _isLoadingList = false;
  String _status = 'Loading files...';
  List<Reference> _selectedFiles = [];
  bool get _isSelectionMode => _selectedFiles.isNotEmpty;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // --- LOGIC FUNCTIONS (UNCHANGED) ---

  Future<void> _loadFiles() async {
    final userEmail = currentUser?.email;
    if (userEmail == null) {
      setState(() => _status = 'Error: User not logged in.');
      return;
    }
    setState(() => _isLoadingList = true);
    try {
      final storage = FirebaseStorage.instance;
      final userFolderRef = storage.ref().child('${widget.folderName}/$userEmail');
      final ListResult result = await userFolderRef.listAll();
      setState(() {
        _uploadedItems = result.items;
        _status = 'Found ${_uploadedItems.length} documents';
      });
    } on FirebaseException catch (e) {
      setState(() => _status = 'Error listing files: ${e.code}');
    } finally {
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _downloadAndOpen(Reference fileRef) async {
    final fileName = fileRef.name;
    final tempDir = await getTemporaryDirectory();
    final localFile = File(p.join(tempDir.path, fileName));
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading to view...')));

    if (!await localFile.exists()) {
      try {
        await fileRef.writeToFile(localFile);
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ${e.code}')));
        return;
      }
    }
    final result = await OpenFile.open(localFile.path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open: ${result.message}')));
    }
  }

  Future<void> _deleteSelectedFiles() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete ${_selectedFiles.length} items?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoadingList = true);
      try {
        for (var ref in _selectedFiles) { await ref.delete(); }
        _selectedFiles.clear();
        _loadFiles();
      } finally {
        setState(() => _isLoadingList = false);
      }
    }
  }

  // --- UI HELPERS ---

  Widget _buildThumbnailWidget(Reference fileRef) {
    final fileName = fileRef.name;
    final extension = p.extension(fileName).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      return const Icon(Icons.image_outlined, size: 40, color: Colors.blueGrey);
    } else if (extension == '.pdf') {
      return const Icon(Icons.picture_as_pdf_outlined, size: 40, color: Colors.redAccent);
    }
    return const Icon(Icons.description_outlined, size: 40, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isSelectionMode ? '${_selectedFiles.length} Selected' : 'My Documents',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedFiles.clear()))
          : IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadFiles),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ElevatedButton.icon(
                onPressed: _deleteSelectedFiles,
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: const Text("DELETE SELECTED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Navy Header Background
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
          ),
          
          Column(
            children: [
              // Status Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_status, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),

              if (_isLoadingList) 
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.orange),
                ),

              Expanded(
                child: _uploadedItems.isEmpty && !_isLoadingList
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _uploadedItems.length,
                        itemBuilder: (context, index) {
                          final fileRef = _uploadedItems[index];
                          final isSelected = _selectedFiles.contains(fileRef);

                          return GestureDetector(
                            onLongPress: () {
                              if (!isSelected) setState(() => _selectedFiles.add(fileRef));
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                setState(() => isSelected ? _selectedFiles.remove(fileRef) : _selectedFiles.add(fileRef));
                              } else {
                                _downloadAndOpen(fileRef);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(child: _buildThumbnailWidget(fileRef)),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          fileRef.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No documents found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}