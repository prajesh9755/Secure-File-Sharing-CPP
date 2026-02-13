import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpp/pages/logoutpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController address2Ctrl = TextEditingController();
  final TextEditingController phone2Ctrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  String studentName = "Loading...";
  String studentPhone = "Loading...";
  String studentAddress = "Loading...";
  String studentEmail = "Loading...";
  String? profileUrl;
  bool _isUploading = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft grey background
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
       
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2A3A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                // Wrap your top profile area in a SizedBox to ensure it can receive clicks
                SizedBox(
                  height: 200, // Important: Must be tall enough to cover the Avatar + Camera button
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center, // Centers children horizontally
                    children: [
                      // 1. YOUR BACKGROUND (e.g., the Navy Blue Header)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 120, // Your existing header height
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A2A3A),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                        ),
                      ),

                      // 2. THE AVATAR + CAMERA BUTTON
                      Positioned(
                        top: 40, // Distance from the top
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            children: [
                              // The Profile Pic
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // THE IMAGE
                                    CircleAvatar(
                                      radius: 56,
                                      backgroundColor: const Color(0xFF1A2A3A),
                                      backgroundImage: _imageFile != null 
                                          ? FileImage(_imageFile!) as ImageProvider
                                          : (profileUrl != null && profileUrl!.isNotEmpty)
                                              ? NetworkImage(profileUrl!)
                                              : const NetworkImage('https://via.placeholder.com/150'),
                                    ),

                                    // THE LOADING OVERLAY
                                    if (_isUploading)
                                      Container(
                                        width: 112, // Match the radius of the inner avatar (56 * 2)
                                        height: 112,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4), // Dim the image while loading
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // The Camera Button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    print("Click Detected!"); // Check your console for this
                                    _pickImage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade200, width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Color(0xFF1A2A3A), size: 20),
                                  ),
                                ),
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

            // const SizedBox(height: 50), // Space for the avatar

            // 2. User Name and Email
            Text(
              studentName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              studentEmail,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // 3. Info Section (Cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileTile(Icons.person_outline, 'Full Name', studentName),
                  _buildProfileTile(Icons.phone_android, 'Phone', studentPhone),
                  _buildProfileTile(Icons.location_on_outlined, 'Address', studentAddress, maxLines: 2),
                  const Divider(height: 40),
                  
                  // Action Buttons
                  _buildMenuTile(Icons.history, 'Form History', () {}),
                  _buildMenuTile(Icons.security, 'Privacy Settings', () {}),
                   _buildMenuTile(Icons.settings, 'Settings', () {}),
                   _buildMenuTile(
                      Icons.logout, 
                      'Logout', 
                      () {
                        // This is the navigation logic
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LogoutPage()),
                        );
                      }, 
                   isLogout: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

Future<void> _pickImage() async {
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery, 
    imageQuality: 50
  );

  if (pickedFile != null) {
    setState(() => _isUploading = true); // Start Loading

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      File file = File(pickedFile.path);

      // 1. Upload to Storage
      Reference ref = FirebaseStorage.instance.ref().child('profiles/$uid.jpg');
      await ref.putFile(file);

      // 2. Get URL & Update Firestore
      String downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profile_pic': downloadUrl,
      });

      // 3. Update local state and stop loading
      setState(() {
        profileUrl = downloadUrl;
        _imageFile = file;
        _isUploading = false; // Stop Loading
      });
    } catch (e) {
      setState(() => _isUploading = false);
      print("Upload failed: $e");
    }
  }
}

_loadExistingData() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final semail = FirebaseAuth.instance.currentUser!.email;
  var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  
  if (doc.exists) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    setState(() {
      // Extract as Strings and update class variables
      studentName = data['student_name']?.toString() ?? "Not Provided";
      studentPhone = data['self_phone']?.toString() ?? "Not Provided";
      studentAddress = data['address']?.toString() ?? "Not Provided";
      studentEmail = semail ?? "Not Provided";
      profileUrl = data['profile_pic'];

      // Also update your controllers if you still have them
      nameCtrl.text = studentName;
      phone2Ctrl.text = studentPhone;
      addressCtrl.text = studentAddress;
    });
  }
}

  // Widget for Displaying User Info (Non-clickable)
  Widget _buildProfileTile(IconData icon, String label, String value, {int maxLines = 1}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), 
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF1A2A3A)),
        const SizedBox(width: 15),
        // Expanded is REQUIRED here so the text can wrap instead of overflowing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis, // Adds "..." if text is still too long
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2A3A),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // Widget for Action Menu (Clickable)
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blueGrey),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}

