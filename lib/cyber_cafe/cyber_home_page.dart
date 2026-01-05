import 'dart:io';

import 'package:cpp/browser/browser.dart';
import 'package:cpp/cyber_cafe/secure_view.dart'; // Ensure this path is correct
import 'package:cpp/firebase/auth_ui_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CyberHomePage extends StatefulWidget {
  const CyberHomePage({super.key});

  @override
  State<CyberHomePage> createState() => _CyberHomePageState();
}

class _CyberHomePageState extends State<CyberHomePage> {
  Map<String, dynamic>? selectedRequest;
  String? selectedDocUrl;
  bool isPdf = false;
  String _currentTab = "Applications";

  // String getFileName(String url) {
  //   try {
  //     // 1. Decode URL (%2F becomes /)
  //     String decodedUrl = Uri.decodeFull(url);
  //     // 2. Get the part after the last '/' and before '?'
  //     String fileName = decodedUrl.split('/').last.split('?').first;
  //     return fileName;
  //   } catch (e) {
  //     return "Document";
  //   }
  // }

  // void _handleRequestSelect(Map<String, dynamic> data, String id) {
  //   setState(() {
  //     selectedRequest = data;
  //     selectedRequest!['id'] = id; // Store the Firestore ID

  //     // Automatically load the first document so the preview isn't blank
  //     List docs = data['documents'] ?? [];
  //     if (docs.isNotEmpty) {
  //       var firstDoc = docs[0];
  //       // Handle if document is a Map (new) or a String (old)
  //       selectedDocUrl = firstDoc is Map ? firstDoc['url'] : firstDoc;
  //       isPdf = firstDoc is Map 
  //           ? (firstDoc['isPdf'] ?? false) 
  //           : selectedDocUrl!.toLowerCase().contains('.pdf');
  //     } else {
  //       selectedDocUrl = null;
  //       isPdf = false;
  //     }
  //   });
  // }

  Future<void> _testDownload(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildDocHeader() {
    final List docs = selectedRequest?['documents'] ?? [];
    final String id = selectedRequest?['id'] ?? "";

    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Document Selection Chips
          ...docs.map((doc) {
            String url = doc is Map ? doc['url'] : doc;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(getFileName(url)),
                onPressed: () => setState(() {
                  selectedDocUrl = url;
                  isPdf = doc is Map ? (doc['isPdf'] ?? false) : url.contains('.pdf');
                }),
              ),
            );
          }).toList(),

          const Spacer(),

          // --- TEST DOWNLOAD BUTTON ---
          // if (selectedDocUrl != null)
          //   IconButton(
          //     icon: const Icon(Icons.download, color: Colors.blue),
          //     tooltip: "TEST ONLY: Download",
          //     onPressed: () => _testDownload(selectedDocUrl!),
          //   ),

          const SizedBox(width: 20),

          ElevatedButton(
            onPressed: () => _updateStatus(id, "Processing"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Processing"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _updateStatus(id, "Completed"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Completed"),
          ),
        ],
      ),
    );
  }

//   @override
//   Widget build(BuildContext context) {
//     print("Current selected URL**************************************************************************************: $selectedDocUrl");
//     final String uid = FirebaseAuth.instance.currentUser!.uid;

//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
//       builder: (context, userSnapshot) {
//         if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
//         final String myCafe = userSnapshot.data?['assigned_cafe'] ?? "";

//         return Scaffold(
//           body: Row(
//             children: [
//               // --- LEFT SIDE: Request List ---
//               Container(
//                 width: 400,
//                 color: Colors.grey[100],
//                 child: _buildSidebar(myCafe),
//               ),

//               // --- RIGHT SIDE: Secure Workspace ---
//               // --- RIGHT SIDE: Secure Workspace ---
//               // --- RIGHT WORKSPACE ---
//               Expanded(
//                 child: selectedRequest == null
//                     ? const Center(child: Text("Select a request from the sidebar"))
//                     : Column(
//                         children: [
//                           // 1. PLACE IT HERE (Top of the right side)
//                           _buildDocHeader(), 

//                           // 2. The viewer takes the remaining space below the header
//                           Expanded(
//                             child: selectedDocUrl == null
//                                 ? const Center(child: CircularProgressIndicator())
//                                 : SecureViewer(url: selectedDocUrl!, isPdf: isPdf),
//                           ),
//                         ],
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

// Widget _buildSidebar(String cafe) {
//   return Container(
//     width: 300,
//     color: Colors.white,
//     child: Column(
//       children: [
//         // TOP: Cafe Name & Requests
//         Container(
//           padding: const EdgeInsets.all(20),
//           width: double.infinity,
//           color: Colors.blue[800],
//           child: Text(
//             cafe.toUpperCase(),
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
//           ),
//         ),

//         // MIDDLE: Request List
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('cyber_requests')
//                 .where('selected_cafe', isEqualTo: cafe)
//                 .orderBy('timestamp', descending: true)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
//               return ListView.builder(
//                 itemCount: snapshot.data!.docs.length,
//                 itemBuilder: (context, i) {
//                   var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
//                   var id = snapshot.data!.docs[i].id;
//                   return ListTile(
//                     selected: selectedRequest?['id'] == id,
//                     title: Text(data['sender_email']),
//                     subtitle: Text(data['scholarship_type']),
//                     onTap: () => _handleRequestSelect(data, id),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//         // BOTTOM: Logout Button
//         const Divider(),
//         ListTile(
//           leading: const Icon(Icons.logout, color: Colors.red),
//           title: const Text("Logout", style: TextStyle(color: Colors.red)),
//           onTap: () async {
//             await FirebaseAuth.instance.signOut();
//             Navigator.pushReplacementNamed(context, '/login');
//           },
//         ),
//         const SizedBox(height: 10),
//       ],
//     ),
//   );
// }

Future<void> uploadApplication(String studentEmail) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'png'],
  );

  if (result == null) return;

  String originalName = result.files.single.name;
  File file = File(result.files.single.path!);
  final storageRef = FirebaseStorage.instance.ref();

  // This structure creates: applications -> user@email.com -> filename.pdf
  final fileRef = storageRef
      .child("applications")
      .child(studentEmail.trim()) // .trim() removes hidden spaces
      .child(originalName);

  UploadTask uploadTask = fileRef.putFile(file);

  // 2. Show Progress Dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StreamBuilder<TaskSnapshot>(
      stream: uploadTask.snapshotEvents,
      builder: (context, snapshot) {
        double progress = 0;
        if (snapshot.hasData) {
          progress = snapshot.data!.bytesTransferred / snapshot.data!.totalBytes;
        }

        return AlertDialog(
          title: const Text("Uploading File"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 10),
              Text("${(progress * 100).toStringAsFixed(0)}%"),
            ],
          ),
        );
      },
    ),
  );

  try {
    // 3. Wait for finish and update Firestore
    await uploadTask;
    Navigator.pop(context); // Close dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Upload Complete!")),
    );
  } catch (e) {
    Navigator.pop(context);
    print("Upload failed: $e");
  }
}

Widget _buildSidebar(String cafe) {
  return Column(
    children: [
      // --- SIDEBAR HEADER (Matching Navy Theme) ---
      Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        width: double.infinity,
        color: const Color(0xFF1A2A3A),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.account_balance, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              cafe.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),

      const SizedBox(height: 15),

      // --- NAVIGATION BUTTONS (Applications / Completed) ---
      _sidebarNavButton(Icons.description_rounded, "Applications", _currentTab == "Applications"),
      _sidebarNavButton(Icons.check_circle_rounded, "Completed", _currentTab == "Completed"),

      const Divider(indent: 20, endIndent: 20, height: 30),

      // --- DYNAMIC LIST AREA ---
      Expanded(
        child: _currentTab == "Completed" 
          ? const Center(child: Text("No completed tasks yet", style: TextStyle(color: Colors.grey)))
          : _buildEmailList(cafe), // Shows list of unique emails
      ),

      // --- LOGOUT BUTTON (Bottom) ---
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      const SizedBox(height: 10),
    ],
  );
}

// --- HELPER: NAVIGATION BUTTON UI ---
Widget _sidebarNavButton(IconData icon, String label, bool isActive) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: InkWell(
      onTap: () => setState(() => _currentTab = label),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A2A3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : const Color(0xFF1A2A3A), size: 22),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1A2A3A),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- HELPER: UNIQUE EMAIL LIST ---
Widget _buildEmailList(String cafe) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('cyber_requests')
        .where('selected_cafe', isEqualTo: cafe)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      // Logic to get unique sender emails
      final docs = snapshot.data!.docs;
      final uniqueEmails = docs.map((d) => d['sender_email'] as String).toSet().toList();

      return ListView.builder(
        itemCount: uniqueEmails.length,
        itemBuilder: (context, index) {
          String email = uniqueEmails[index];
          // Check if this email is currently "selected" based on the selectedRequest
          bool isSelected = selectedRequest?['sender_email'] == email;

          return ExpansionTile(
            leading: Icon(Icons.alternate_email, color: isSelected ? Colors.blue : Colors.grey),
            title: Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            children: docs
                .where((d) => d['sender_email'] == email)
                .map((d) {
                  var data = d.data() as Map<String, dynamic>;
                  var id = d.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 50),
                    title: Text(data['scholarship_type'], style: const TextStyle(fontSize: 12)),
                    subtitle: Text(data['status'], style: TextStyle(fontSize: 10, color: _getStatusColor(data['status']))),
                    onTap: () => _handleRequestSelect(data, id),
                  );
                }).toList(),
          );
        },
      );
    },
  );
}
@override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final String myCafe = userSnapshot.data?['assigned_cafe'] ?? "My Cafe";

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA), // Matches HomePage bgColor
          body: Row(
            children: [
              // --- 1. SIDEBAR (Integrated Logic) ---
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                ),
                child: _buildSidebar(myCafe),
              ),

              // --- 2. MAIN WORKSPACE ---
              Expanded(
                child: Column(
                  children: [
                    // TOP CURVED HEADER (Matches HomePage Style)
                    Container(
                      height: 120,
                      padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A2A3A), // Navy Blue
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedRequest == null ? "Cyber Dashboard" : (selectedRequest!['scholarship_type'] ?? "Request"),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                              if (selectedRequest != null)
                                Text("Status: ${selectedRequest!['status']}", 
                                  style: TextStyle(color: _getStatusColor(selectedRequest!['status']).withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const Spacer(),
                          // Toolbar Actions from your original logic
                          if (selectedRequest != null) ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text("Browser"),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MySmartBrowser(documents: selectedRequest!['documents'] ?? [], requestData: selectedRequest))),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A2A3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => uploadApplication(selectedRequest?['sender_email'] ?? ""),
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text("Upload"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const SizedBox(width: 15),
                            _actionBtn("Processing", Colors.orange, Icons.sync),
                            const SizedBox(width: 10),
                            _actionBtn("Completed", Colors.green, Icons.check_circle),
                          ]
                        ],
                      ),
                    ),

                    // WORKSPACE CONTENT
                    Expanded(
                      child: selectedRequest == null
                          ? _buildEmptyState()
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // Left side: Document Viewer Card
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: _buildViewerSection(), // Your viewer logic
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Right side: Student Details Panel
                                  Container(
                                    width: 360,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                                    ),
                                    child: _buildStudentProfilePanel(), // Your profile logic
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// --- 1. THE TOP TOOLBAR ---
  Widget _buildTopToolbar() {
    // Return empty if nothing is selected to avoid null errors
    if (selectedRequest == null) return const SizedBox(); 

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selectedRequest!['scholarship_type'] ?? "Request", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Status: ${selectedRequest!['status']}", 
                  style: TextStyle(color: _getStatusColor(selectedRequest!['status']), fontSize: 12)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text("Open Browser"),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MySmartBrowser(documents: selectedRequest!['documents'] ?? [], requestData: selectedRequest,))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
          ),
          const SizedBox(width: 10),
          
          ElevatedButton.icon(
            onPressed: () {
              // print("Selected Email: ${selectedRequest?['student_email']}");
              uploadApplication(selectedRequest?['sender_email'] ?? "") ;
              },
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Form"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 15),
          _actionBtn("Processing", Colors.orange, Icons.sync),
          const SizedBox(width: 10),
          _actionBtn("Completed", Colors.green, Icons.check_circle),
        ],
      ),
    );
  }
  // --- 2. STUDENT PROFILE PANEL (The New Part) ---
  Widget _buildStudentProfilePanel() {
    final info = selectedRequest?['student_info'];
    if (info == null) return const Center(child: Text("No profile data sent"));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("STUDENT DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
        // _profileItem(Icons.phone, "Phone", (info['phones'] as List?)?.join(" / ")),
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
  }

  

  // --- HELPER WIDGETS ---
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

  

  Widget _actionBtn(String label, Color color, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _updateStatus(selectedRequest?['id'], label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == "Completed") return Colors.green;
    if (status == "Processing") return Colors.orange;
    return Colors.blue;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Select a student request to begin", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

Widget _buildControlHeader() {
  final List docs = selectedRequest?['documents'] ?? [];
  final String note = selectedRequest?['note'] ?? "No Description";
  final String id = selectedRequest?['id'] ?? "";

  return Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description: $note", style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 15),
        Row(
          children: [
            ...docs.map((doc) {
              String url = doc is Map ? doc['url'] : doc;
              String fileName = getFileName(url); // REAL NAME
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(fileName),
                  onPressed: () => setState(() {
                    selectedDocUrl = url;
                    isPdf = doc is Map ? doc['isPdf'] : url.contains('.pdf');
                  }),
                ),
              );
            }).toList(),
            const Spacer(),
            
            // STATUS BUTTONS
            ElevatedButton(
              onPressed: () => _updateStatus(id, "Processing"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Processing"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _updateStatus(id, "Completed"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Completed"),
            ),
          ],
        ),
      ],
    ),
  );
}

  // Future<void> _updateStatus(String? id, String status) async {
  //   if (id == null) return;
  //   await FirebaseFirestore.instance.collection('cyber_requests').doc(id).update({'status': status});
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status")));
  // }

  // --- HELPER: FILE NAME EXTRACTOR ---
  String getFileName(String url) {
    try {
      String decodedUrl = Uri.decodeFull(url);
      return decodedUrl.split('/').last.split('?').first;
    } catch (e) {
      return "Document";
    }
  }

  // --- HELPER: HANDLE SELECTION ---
  void _handleRequestSelect(Map<String, dynamic> data, String id) {
    setState(() {
      selectedRequest = data;
      selectedRequest!['id'] = id;
      List docs = data['documents'] ?? [];
      if (docs.isNotEmpty) {
        var firstDoc = docs[0];
        selectedDocUrl = firstDoc is Map ? firstDoc['url'] : firstDoc;
        isPdf = firstDoc is Map ? (firstDoc['isPdf'] ?? false) : selectedDocUrl!.toLowerCase().contains('.pdf');
      }
    });
  }

  // --- NEW: THE VIEWER SECTION (Fixes your error) ---
  Widget _buildViewerSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildDocTabs(), // Document chips
          Expanded(
            child: selectedDocUrl == null
                ? const Center(child: Text("No document selected"))
                : SecureViewer(url: selectedDocUrl!, isPdf: isPdf),
          ),
        ],
      ),
    );
  }

  // --- NEW: DOCUMENT TABS ---
  Widget _buildDocTabs() {
    final List docs = selectedRequest?['documents'] ?? [];
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: docs.map((doc) {
            String url = doc is Map ? doc['url'] : doc;
            return Padding(
              padding: const EdgeInsets.only(right: 8), // FIXED EdgeInsets here
              child: ActionChip(
                backgroundColor: selectedDocUrl == url ? Colors.blue[50] : Colors.white,
                label: Text(getFileName(url)),
                onPressed: () => setState(() {
                  selectedDocUrl = url;
                  isPdf = doc is Map ? (doc['isPdf'] ?? false) : url.contains('.pdf');
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- UPDATED: STATUS UPDATER ---
  Future<void> _updateStatus(String? id, String status) async {
    if (id == null) return;
    await FirebaseFirestore.instance.collection('cyber_requests').doc(id).update({'status': status});
    setState(() => selectedRequest?['status'] = status);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Marked as $status")));
  }

  // (Include the rest of your build method and profile panel here...)
}