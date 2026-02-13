import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyFormPage extends StatefulWidget {
  const ApplyFormPage({super.key});

  @override
  State<ApplyFormPage> createState() => _ApplyFormPageState();
}

class _ApplyFormPageState extends State<ApplyFormPage> {
  final _noteController = TextEditingController();
  String? selectedCafe;
  String? selectedScholarship;
  List<String> selectedDocPaths = []; 
  Set<String> selectedFiles = {};
  // This list will store the names of the files the user selects

  // 2. The Text Controller (for the Scholarship input field)
  final TextEditingController _scholarshipController = TextEditingController();

  // Don't forget to dispose controllers to save memory
  @override
  void dispose() {
    _scholarshipController.dispose();
    super.dispose();
  }

  final Map<String, List<String>> scholarshipRequirements = {
    'DTE': ['Aadhar Card', 'Income Certificate', 'Ration Card'],
    'EBC': ['Aadhar Card', 'College ID', 'Income Certificate'],
    'Postmetric': ['Caste Certificate', 'Aadhar Card', 'Marklist'],
  };

  // --- SAME FIREBASE LOGIC ---
  Future<void> _finalSubmit() async {
  if (selectedCafe == null || selectedScholarship == null || selectedDocPaths.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please complete all steps first!")),
    );
    return;
  }

  try {
    // 1. Fetch current user ID and their profile info
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userDoc.exists) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill your profile first!")),
      );
      return;
    }

    // 2. Extract profile data
    final Map<String, dynamic> studentInfo = userDoc.data() as Map<String, dynamic>;

    // 3. Process documents
    final List<Map<String, dynamic>> processedDocs = selectedDocPaths.map((url) {
      return {
        'url': url,
        'isPdf': url.toLowerCase().contains('.pdf') || url.contains('type=pdf'),
      };
    }).toList();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // 4. Submit to Firestore
    await FirebaseFirestore.instance.collection('cyber_requests').add({
      'sender_email': FirebaseAuth.instance.currentUser!.email,
      'senderUid': user.uid,
      'scholarship_type': selectedScholarship,
      'note': _noteController.text.trim(),
      'selected_cafe': selectedCafe,
      'documents': processedDocs, 
      'status': 'Pending',
      'student_info': studentInfo, // SENDS FULL PROFILE AUTOMATICALLY
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Reset UI
    setState(() {
      _noteController.clear();
      selectedScholarship = null;
      selectedDocPaths = [];
      selectedFiles = {};
      selectedCafe = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Package sent successfully!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Consistent Light Grey
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A), // Consistent Navy
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Application Form", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 1. THE NAVY BLUE HEADER (Exactly like Profile/Home)
          Container(
            height: 180, 
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            // child: const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            //   child: Row(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       CircleAvatar(
            //         radius: 25,
            //         backgroundColor: Colors.white24,
            //         child: Icon(Icons.assignment, color: Colors.white, size: 28),
            //       ),
            //       SizedBox(width: 15),
            //       // Column(
            //       //   crossAxisAlignment: CrossAxisAlignment.start,
            //       //   children: [
            //       //     Text("Fill Your Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            //       //     Text("Secure Submission", style: TextStyle(color: Colors.white70, fontSize: 13)),
            //       //   ],
            //       // )
            //     ],
            //   ),
            // ),
          ),

          // 2. THE SCROLLABLE CARDS (Floating effect)
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 40),
            child: Column(
              children: [
                // CARD 1: Scholarship Selection
                _buildProfileStyleCard(
                  icon: Icons.school,
                  iconColor: Colors.blue,
                  title: "Scholarship Type",
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    isExpanded: true,
                    hint: const Text("Select Scholarship"),
                    value: selectedScholarship,
                    onChanged: (val) => setState(() => selectedScholarship = val),
                    items: scholarshipRequirements.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  ),
                ),

                // Requirement List (Only shows if selected)
                if (selectedScholarship != null) _buildRequirementList(),

                // CARD 2: Document Attachment
                _buildProfileStyleCard(
                  icon: Icons.attach_file,
                  iconColor: Colors.green,
                  title: "Documents",
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedDocPaths.isEmpty 
                        ? "No files attached" 
                        : "${selectedDocPaths.length} Files selected"),
                    trailing: const Icon(Icons.add_circle, color: Color(0xFF1A2A3A), size: 30),
                    onTap: () => _triggerFilePicker(), // Logic below
                  ),
                ),

                // CARD 3: Cafe Selection
                _buildProfileStyleCard(
                  icon: Icons.store,
                  iconColor: Colors.orange,
                  title: "Select Cyber Cafe",
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('cafes').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                         decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        hint: const Text("Choose Cafe"),
                        value: selectedCafe,
                        onChanged: (val) => setState(() => selectedCafe = val),
                        items: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: data['name'].toString(), child: Text(data['display_name'] ?? data['name']));
                        }).toList(),
                      );
                    },
                  ),
                ),

                // CARD 4: Additional Notes
                _buildProfileStyleCard(
                  icon: Icons.edit_note,
                  iconColor: Colors.purple,
                  title: "Additional Notes",
                  child: TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Enter instructions...",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // FINAL SUBMIT BUTTON (Matches Home Page Gradient)
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2A3A),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      // 1. Show a loading spinner
                      _showLoadingDialog(context);
                      _finalSubmit();
                      // try {
                      //   final userEmail = FirebaseAuth.instance.currentUser?.email;

                      //   // 2. THE FIREBASE CODE GOES HERE
                      //   await FirebaseFirestore.instance.collection('cyber_requests').add({
                      //     'sender_email': userEmail,
                      //     'scholarship_type': _scholarshipController.text, // Example field
                      //     'selected_cafe': _selectedCafe,                // Example field
                      //     'attached_files': selectedDocPaths,            // YOUR SELECTED FILES
                      //     'status': 'Pending',
                      //     'timestamp': FieldValue.serverTimestamp(),
                      //   });

                      //   // 3. Success!
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request submitted successfully!")),
                        );
                        Navigator.pop(context); // Go back to Home Page
                        
                      // } catch (e) {
                      //   Navigator.pop(context); // Close loading dialog
                      //   print("Error submitting: $e");
                      // }
                    },
                    child: const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents user from clicking away
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A2A3A)),
    ),
  );
}

  // --- HELPER TO BUILD PROFILE-STYLE CARDS ---
  Widget _buildProfileStyleCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2A3A))),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildRequirementList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(1), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: scholarshipRequirements[selectedScholarship]!
            .map((doc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [const Icon(Icons.check_circle, size: 16, color: Colors.green), const SizedBox(width: 8), Text(doc, style: const TextStyle(fontSize: 13))]),
                ))
            .toList(),
      ),
    );
  }
  
  void _showFilePickerSheet(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.email;

    final storageFuture = FirebaseStorage.instance.ref('user_data/$email').listAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<ListResult>(
              future: storageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final files = snapshot.data!.items;
                if (files.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No files found.")));

                return Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Select from Storage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, i) {
                            String fileName = files[i].name;
                            String filePath = files[i].fullPath;

                            return CheckboxListTile(
                              title: Text(fileName),
                              value: selectedFiles.contains(filePath),
                              onChanged: (bool? checked) {
                                // Update the bottom sheet UI
                                setSheetState(() {
                                  // setState(() {});
                                  if (checked == true) {
                                    selectedFiles.add(filePath);
                                  } else {
                                    selectedFiles.remove(filePath);
                                  }
                                });
                                // Update the main dashboard UI
                                
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () => _handleConfirmSelection(),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          child: Text("Confirm Selection (${selectedFiles.length})"),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

    // --- NEW: Convert Paths to URLs for Cyber Side ---
  Future<void> _handleConfirmSelection() async {
    Navigator.pop(context); // Close the sheet
    
    // Show loading because we need to get download URLs from Storage
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing selected files...")));

    List<String> urls = [];
    for (String path in selectedFiles) {
      String downloadUrl = await FirebaseStorage.instance.ref(path).getDownloadURL();
      urls.add(downloadUrl);
    }

    setState(() {
      selectedDocPaths = urls; // This activates the FINAL SUBMIT button
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${urls.length} files attached!")));
  }

void _triggerFilePicker() {
    _showFilePickerSheet(context);
  }

void _handleUpload() {
  if (selectedFiles.isEmpty) return;
  
  // Logic to pass selectedFiles back to the main form
  print("Selected files: ${selectedFiles.length}");
  Navigator.pop(context, selectedFiles.toList()); 
}
  // (Include your _showFilePickerSheet logic here)
}
  // --- KEEP YOUR EXISTING _showFilePickerSheet AND _handleConfirmSelection HERE ---
  // (Copied from your previous code for functionality)

