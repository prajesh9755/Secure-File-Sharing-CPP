// // minimal_home_screen.dart

// import 'package:cpp/firebase/auth_service.dart';
// import 'package:cpp/firebase/file_viewer_screen.dart';
// import 'package:cpp/pages/upload_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; 


// // --- Minimal Home Screen ---

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Get the current user's email for a personalized welcome message
//     final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome, ${userEmail.split('@')[0]}'),
//         actions: [
//           // Logout button remains for functionality
//           IconButton(
//             icon: const Icon(Icons.logout), 
//             onPressed: () async => await AuthService().signOut()
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const SizedBox(height: 20),

//             // --- The Single Upload Button ---
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute<void>(
//                     builder: (context) => const UploadPage(),
//                   ),
//                 );
//               },
//               child: const Text('UPLOAD'),
//             ),

//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute<void>(
//                     builder: (context) => const FileViewerScreen(),
//                   ),
//                 );
//               },
//               child: const Text('VIEW FILES'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }