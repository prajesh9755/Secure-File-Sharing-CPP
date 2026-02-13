import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpp/utils/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';
import 'package:path/path.dart' as p;

class MySmartBrowser extends StatefulWidget {
  final List documents;
  final Map<String, dynamic>? requestData;
  const MySmartBrowser({super.key, required this.documents, this.requestData});

  @override
  State<MySmartBrowser> createState() => _MySmartBrowserState();
}

class _MySmartBrowserState extends State<MySmartBrowser> {
  final _winController = WinWebViewController();
  String? _downloadingDocName; 
  bool _isLoading = true;
  late Map<String, dynamic>? selectedRequest;
  final semail = FirebaseAuth.instance.currentUser!.email;
  String? _lastCopiedFile; // Stores the name of the file that was just copied

  @override
  void initState() {
    super.initState();
    selectedRequest = widget.requestData;
    _initBrowser();
  }

  void _initBrowser() {
    _winController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _winController.loadRequest(Uri.parse('https://mahadbt.maharashtra.gov.in/login/login'));
    
    _winController.setNavigationDelegate(WinNavigationDelegate(
      onPageStarted: (url) => setState(() => _isLoading = true),
      onPageFinished: (url) => setState(() => _isLoading = false),
    ));
  }

  // CORE LOGIC: Downloads file and copies path to clipboard (Required for Windows upload bridge)
  // Future<void> _prepareSecureFileDirectly(String url, String fileName) async {
  //   setState(() => _downloadingDocName = fileName);

  //   try {
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final dir = await getTemporaryDirectory();
  //       String fullPath = "${dir.path}\\$fileName"; 

  //       final file = File(fullPath);
  //       await file.writeAsBytes(response.bodyBytes, flush: true);

  //       // Copy physical path to clipboard so user can Paste (Ctrl+V) in the portal
  //       await Clipboard.setData(ClipboardData(text: file.absolute.path));
  //     }
  //   } catch (e) {
  //     debugPrint("Download Error: $e");
  //   } finally {
  //     setState(() => _downloadingDocName = null);
  //   }
  // }

  // Ensure you are passing the STUDENT'S email here, not the Cyber's!
  Future<void> _prepareSecureFileDirectly(String url, String fileName, String studentEmail) async {
    setState(() => _downloadingDocName = fileName);

    try {
      final String studentEmail = selectedRequest?['sender_email'];
      // FIX 1: Explicitly use studentEmail to find the key
      final keyDoc = await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(studentEmail) // This MUST be the student who uploaded the file
          .collection('keys')
          .doc(fileName)
          .get();

      if (!keyDoc.exists) {
        print("FAILED: No key at file_keys/$studentEmail/keys/$fileName");
        throw "Encryption key missing for this file.";
      }
      
      String fileKey = keyDoc.data()!['key'];

      // FIX 2: Standard HTTP download is usually fine, 
      // but the decryption math should be awaited correctly
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // If EncryptionService.decryptData is very heavy, 
        // make sure it's not blocking the platform thread.
        Uint8List decryptedPdf = EncryptionService.decryptData(
          response.bodyBytes, 
          fileKey
        );

        final dir = await getTemporaryDirectory();
        String fullPath = p.join(dir.path, fileName);
        final file = File(fullPath);
        await file.writeAsBytes(decryptedPdf, flush: true);

        await Clipboard.setData(ClipboardData(text: file.path));
       
        setState(() {
          _lastCopiedFile = fileName; 
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Ready! Path copied for $fileName")),
        // );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _downloadingDocName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cyber Secure Browser"),
        backgroundColor: Colors.blue[900],
      ),
      body: Row(
        children: [
          // 1. THE BROWSER
          Expanded(
            flex: 4,
            child: Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(color: Colors.orange),
                Expanded(child: WinWebViewWidget(controller: _winController)),
              ],
            ),
          ),

          // 2. THE SECURE SIDEBAR
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(left: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              children: [
                // Profile Section
                Expanded(
                  flex: 2,
                  child: _buildStudentProfilePanel(),
                ),
                
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("STUDENT DOCUMENTS", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const Divider(height: 1),

                // Documents List
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.documents.length,
                    itemBuilder: (context, i) {
                      final doc = widget.documents[i];
                      final url = doc is Map ? doc['url'] : doc;
                      
                      String decodedUrl = Uri.decodeFull(url);
                      String displayName = decodedUrl.split('/').last.split('?').first;
                      if (displayName.isEmpty) displayName = "Doc_${i+1}.pdf";

                      bool isThisDownloading = _downloadingDocName == displayName;

                      return ListTile(
                        dense: true,
                        leading: isThisDownloading 
                          ? const SizedBox(width: 20, height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                          : Icon(
                              _lastCopiedFile == displayName ? Icons.check_circle : Icons.file_present, 
                              color: _lastCopiedFile == displayName ? Colors.green : Colors.blue
                            ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // --- UPDATED SUBTITLE LOGIC ---
                        subtitle: isThisDownloading 
                          ? const Text("Preparing Path...", style: TextStyle(color: Colors.orange, fontSize: 10)) 
                          : (_lastCopiedFile == displayName 
                              ? const Text("Path Copied!", style: TextStyle(color: Colors.green, fontSize: 10)) 
                              : null),
                        onTap: isThisDownloading ? null : () => _prepareSecureFileDirectly(url, displayName, semail ?? "unknown")
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStudentProfilePanel() {
  //   final info = selectedRequest?['student_info'];
  //   if (info == null) return const Center(child: Text("No profile data sent"));

  //   return SingleChildScrollView(
  //     primary: false,
  //     padding: const EdgeInsets.all(20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text("STUDENT DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
  //         const SizedBox(height: 20),
  //         _profileItem(Icons.person, "Name", info['student_name']),
  //         _profileItem(Icons.email, "Email", info['myemail']),
  //          _profileItem(Icons.cake, "Gender", info['gender']),
  //         _profileItem(Icons.cake, "DOB", info['dob']),
  //         _profileItem(Icons.school, "Qualification", info['Qualification']),
  //          _profileItem(Icons.cake, "Admission Type", info['admission_type']),
  //         _profileItem(Icons.group, "Caste", info['caste']),
  //         _profileItem(Icons.accessibility, "Disability", info['disability']),
  //         _profileItem(Icons.family_restroom, "Father", info['father_name']),
  //         _profileItem(Icons.family_restroom, "Father Occupation", info['father_occupation']),
  //         _profileItem(Icons.family_restroom, "Mother", info['mother_name']),
  //         _profileItem(Icons.family_restroom, "Mother Occupation", info['mother_occupation']),
  //         // _profileItem(Icons.phone, "Phone", (info['phones'] as List?)?.join("")),
  //         _profileItem(Icons.home, "Address", info['address']),
  //         _profileItem(Icons.home, "Address 2", info['address2']),
  //         _profileItem(Icons.cake, "Stay", info['stay']),
  //         _profileItem(Icons.cake, "Parent Phone", info['parent_phone']),
  //         _profileItem(Icons.cake, "Self Phone", info['self_phone']), 
  //         _profileItem(Icons.badge, "Aadhar", info['aadhar']),
  //         _profileItem(Icons.calendar_today, "Academic Year", info['current_year']),
  //         const Divider(height: 40),
  //         const Text("BANK INFO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
  //         const SizedBox(height: 15),
  //         _profileItem(Icons.account_balance, "Bank", info['bank_details']?['bank_name']),
  //         _profileItem(Icons.numbers, "Account", info['bank_details']?['acc_no']),
  //         _profileItem(Icons.code, "IFSC", info['bank_details']?['ifsc']),
  //         const Divider(height: 40),
  //         const Text("USER NOTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
  //         Padding(
  //           padding: const EdgeInsets.only(top: 10),
  //           child: Text(selectedRequest?['note'] ?? "No note provided", style: const TextStyle(fontStyle: FontStyle.italic)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStudentProfilePanel() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getDecryptedProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Could not decrypt student profile"));
        }

        final info = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("STUDENT DETAILS (DECRYPTED)", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 20),
            _profileItem(Icons.person, "Name", info['student_name']),
            _profileItem(Icons.email, "Email", info['myemail']),
            _profileItem(Icons.cake, "Gender", info['gender']),
            _profileItem(Icons.cake, "DOB", info['dob']),
            _profileItem(Icons.school, "Qualification", info['Qualification']),
            _profileItem(Icons.family_restroom, "Admission Type", info['admission_type']),
            _profileItem(Icons.cake, "Caste", info['caste']),
            _profileItem(Icons.cake, "Disability", info['disability']),
            _profileItem(Icons.family_restroom, "Father", info['father_name']),
            _profileItem(Icons.family_restroom, "Father Occupation", info['father_occupation']),
            _profileItem(Icons.family_restroom, "Mother", info['mother_name']),
            _profileItem(Icons.family_restroom, "Mother Occupation", info['mother_occupation']),
            _profileItem(Icons.home, "Address", info['address']),
            _profileItem(Icons.home, "Address 2", info['address2']),
            _profileItem(Icons.cake, "Stay", info['stay']),
            _profileItem(Icons.cake, "Parent Phone", info['parent_phone']),
            _profileItem(Icons.cake, "Self Phone", info['self_phone']),
            _profileItem(Icons.badge, "Aadhar", info['aadhar']),
            _profileItem(Icons.calendar_today, "Academic Year", info['current_year']),
            const Divider(height: 40),
            const Text("BANK INFO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 15),
            _profileItem(Icons.account_balance, "Bank", info['bank_details']?['bank_name']),
            _profileItem(Icons.numbers, "Account", info['bank_details']?['acc_no']),
            _profileItem(Icons.code, "IFSC", info['bank_details']?['ifsc']),
            const Divider(height: 40),
            const Text("USER NOTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(selectedRequest?['note'] ?? "No note provided", style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getDecryptedProfile() async {
    try {
      // 1. Safely extract IDs from the selected request
      final String? studentEmail = selectedRequest?['sender_email'];
      final String? studentUid = selectedRequest?['senderUid'];

      if (studentEmail == null || studentUid == null) {
        debugPrint("##########🔐 Attempting to decrypt profile for email: $studentEmail, UID: $studentUid");
      }
      

      // 2. Fetch the Master Key (Must be on main thread)
      final keyDoc = await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(studentEmail)
          .collection('keys')
          .doc('profile_data')
          .get();

      if (!keyDoc.exists) {
        debugPrint("❌ Error: No key found at file_keys/$studentEmail/keys/profile_data");
        return null;
      }
      
      String masterKey = keyDoc.data()!['key'];

      // 3. Fetch the Encrypted Payload
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentUid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('secure_payload')) {
        debugPrint("❌ Error: No encrypted payload found for UID: $studentUid");
        return null;
      }
      
      String encryptedPayload = userDoc.data()!['secure_payload'];

      // 4. Decrypt and return
      String decryptedJson = EncryptionService.decryptString(encryptedPayload, masterKey);
      return jsonDecode(decryptedJson);

    } catch (e) {
      debugPrint("❌ Decryption Exception: $e");
      return null;
    }
  }

  Widget _profileItem(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value?.toString() ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _winController.dispose();
    super.dispose();
  }
}