import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpp/browser/browser.dart';
import 'package:cpp/camera/camera.dart';
import 'package:cpp/firebase/file_viewer_screen.dart';
import 'package:cpp/pages/form_history.dart';
import 'package:cpp/pages/user_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'upload_page.dart';
import 'menubutton.dart';
import 'applyform.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Home'),
      leading: Builder(
      builder: (context) => IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Scaffold.of(context).openDrawer();
        
      },
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.notification_add_sharp),
      onPressed: () {
        // Notification button action
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new notifications'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    ),
  ],
),


      drawer: const MenuPage(),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search forms...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Quick Actions
const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Quick Actions',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 10),

Row(
  children: [
    Expanded(
    child: ElevatedButton.icon(
  icon: const Icon(Icons.assignment),
  label: const Text('Apply for Form'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, 
    foregroundColor: Colors.white, // text & icon color(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {

          Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
          );

          // Add this to your User Side UI to see the status
          },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
    child: OutlinedButton.icon(
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Scan / Upload'),
        style: OutlinedButton.styleFrom(
           backgroundColor: Colors.green, // 🎨 Button color
    foregroundColor: Colors.white, // text & icon color
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () { 
          // sendToCyber(context); 
          Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApplyFormPage(),
                    ),
                  );
          },
      ),
    ),
  ],
),

const SizedBox(height: 20),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload File'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadPage(),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Uploaded files'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileViewerScreen(folderName: 'user_data'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

     
// Dashboard section
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      SizedBox(
        width: 160,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Submitted'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileViewerScreen(folderName: 'applications'),
                    ),
                  );
                },
        ),
      ),

      const SizedBox(width: 10),

      SizedBox(
        width: 160,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text('History'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
             
          },
        ),
      ),

      const SizedBox(width: 10),

      SizedBox(
        width: 160,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera Scan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => CustomScanner.startScan(context),
        ),
      ),
    ],
  ),
),

          ],
        ),
      ),
    );
  }


Future<void> sendToCyber(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  
  var _uploadedFileUrl;
  await FirebaseFirestore.instance.collection('cyber_requests').add({
    'sender_email': user?.email,
    'note': "User has submitted documents", // Change to your text controller
    'file_url': _uploadedFileUrl, // Use the URL from your upload
    'status': 'Pending',
    'timestamp': FieldValue.serverTimestamp(),
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sent to Cyber Side!'))
  );
}
}


