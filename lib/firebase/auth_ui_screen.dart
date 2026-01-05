// // auth_ui_screens.dart

// import 'package:cpp/pages/home_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // NOTE: Make sure to import your AuthService file here!
// import 'auth_service.dart'; 

// // --- Auth Screen (Login/Register UI) ---

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final AuthService _authService = AuthService(); 
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController(); 

//   bool _isRegistering = false;
//   bool _isLoading = false;
//   // NEW: State for toggling password visibility
//   bool _isPasswordVisible = false; 

//   Future<void> _submitAuth() async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Check if passwords match during registration
//     if (_isRegistering && _passwordController.text != _confirmPasswordController.text) {
//         if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content: Text('Error: Passwords do not match.'),
//                     backgroundColor: Colors.red,
//                 ),
//             );
//             setState(() {
//                 _isLoading = false;
//             });
//             return;
//         }
//     }
    
//     // Call the single function
//     String resultMessage = await _authService.handleAuth(
//       _emailController.text.trim(),
//       _passwordController.text,
//       isRegister: _isRegistering,
//     );
    
//     bool success = resultMessage.contains('successful');
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(resultMessage),
//           backgroundColor: success ? Colors.green : Colors.red,
//         ),
//       );
      
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isRegistering ? 'Create Account' : 'Sign In'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             // --- Email Field ---
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 15),

//             // --- Password Field ---
//             TextField(
//               controller: _passwordController,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 // NEW: Eye button as suffix icon
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _isPasswordVisible = !_isPasswordVisible;
//                     });
//                   },
//                 ),
//               ),
//               // NEW: Obscure text based on state
//               obscureText: !_isPasswordVisible,
//             ),
//             const SizedBox(height: 15),

//             // --- Confirm Password Field (Visible only during registration) ---
//             if (_isRegistering)
//               Column(
//                 children: [
//                   TextField(
//                     controller: _confirmPasswordController,
//                     decoration: InputDecoration(
//                       labelText: 'Confirm Password',
//                       // NEW: Eye button for confirm password
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     // NEW: Obscure text based on state
//                     obscureText: !_isPasswordVisible,
//                   ),
//                   const SizedBox(height: 15),
//                 ],
//               ),
            
//             const SizedBox(height: 15),

//             ElevatedButton(
//               onPressed: _isLoading ? null : _submitAuth,
//               child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : Text(_isRegistering ? 'REGISTER' : 'LOG IN'),
//             ),
            
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _isRegistering = !_isRegistering;
//                   _confirmPasswordController.clear();
//                 });
//               },
//               child: Text(
//                 _isRegistering
//                     ? 'Already have an account? Log In'
//                     : 'Need an account? Register',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// // --- Auth Wrapper (Decides which screen to show) ---

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: AuthService().userStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         }
        
//         // If snapshot.data is NOT null, user is logged in -> Go to Home
//         if (snapshot.data != null) {
//           return const HomePage();
//         } else {
//           // If snapshot.data is null, user is NOT logged in -> Go to AuthScreen
//           return const AuthScreen();
//         }
//       },
//     );
//   }
// }

// auth_ui_screens.dart

import 'package:cpp/cyber_cafe/cyber_home_page.dart';
import 'package:cpp/pages/home_page_new.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Step 2
import 'auth_service.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class AuthScreen extends StatefulWidget {
  final String role; 
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _cafeNameController = TextEditingController();
  String? _selectedCafe; 

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false; 

  Future<void> _submitAuth() async {
  setState(() => _isLoading = true);
  
  try {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final cafeName = _cafeNameController.text.trim();

    // 1. Cyber-specific Validation (Before creating Auth account)
    if (_isRegistering && widget.role == 'cyber') {
      if (cafeName.isEmpty) throw "Please enter a cafe name.";

      final existing = await FirebaseFirestore.instance
          .collection('cafes')
          .where('name', isEqualTo: cafeName.toLowerCase())
          .get();

      if (existing.docs.isNotEmpty) {
        throw "Cafe name already taken!";
      }
    }

    // 2. Perform Authentication
    String resultMessage = await _authService.handleAuth(
      email,
      password,
      isRegister: _isRegistering,
    );

    if (!resultMessage.contains('successful')) {
      throw resultMessage;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 3. Handle Registration Data (Save to Firestore)
    if (_isRegistering) {
      // Save User Profile
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': widget.role,
        'assigned_cafe': widget.role == 'cyber' ? cafeName.toLowerCase() : null,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Save to Global Cafe List (if Cyber)
      if (widget.role == 'cyber') {
        await FirebaseFirestore.instance.collection('cafes').add({
          'name': cafeName.toLowerCase(),
          'email': user.email,
          'display_name': cafeName,
          'owner_uid': user.uid,
        });
      }
    } 
    
    // 4. Handle Login Validation (Prevent wrong-side login)
    else {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        String actualRole = doc.data()?['role'] ?? 'user';
        if (actualRole != widget.role) {
          await FirebaseAuth.instance.signOut();
          throw "Access Denied: Use the $actualRole side to login.";
        }
      }
    }

    // 5. Success - Close Login Screen
    if (mounted) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// --- DECLARE THIS VARIABLE AT THE TOP ---
  String? _generatedOtp; 

  // --- THE OTP GENERATION LOGIC ---
void _handleRegistration() {
  String email = _emailController.text.trim();
  print("DEBUG: Email in controller is: '${_emailController.text}'"); // Check your console!
  
  if (_emailController.text.trim().isEmpty) {
    print("ERROR: Email is empty!");
    return;
  }

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter an email address")),
    );
    return;
  }

  // Generate OTP
  String otp = (Random().nextInt(900000) + 100000).toString();
  _generatedOtp = otp;

  // Trigger Email
  sendOtpEmail(email, otp);

  // Show the popup
  _showOtpDialog();
}

  // --- THE MISSING DIALOG METHOD ---
  void _showOtpDialog() {
    TextEditingController otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Verify Email", 
          style: TextStyle(color: Color(0xFF1A2A3A), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the 6-digit code sent to your email."),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2A3A)),
            onPressed: () {
              if (otpController.text == _generatedOtp) {
                Navigator.pop(context);
                _submitAuth(); // Your actual Firebase registration call
              } else {
                // You could show a snackbar here for "Wrong OTP"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid OTP, please try again.")),
                );
              }
            },
            child: const Text(
              "Verify", 
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
          ),
        ],
      ),
    );
  }

Future<void> sendOtpEmail(String email, String otp) async {
  // Use your real IDs from EmailJS dashboard
  const serviceId = 'service_y3lb3fh';
  const templateId = 'template_s7877lv';
  const userId = 'sXnJE-iOPbEndiZax';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost', 
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email, 
          'passcode': otp,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent successfully to: $email');
    } else {
      // This is where you saw "recipients address is empty"
      print('Failed to send email: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// THIS REPLACES YOUR BUTTON CLICK LOGIC FOR REGISTRATION


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text(_isRegistering ? 'Create Account' : 'Sign In')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(20.0),
  //       child: SingleChildScrollView( // Added to prevent overflow
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: <Widget>[
  //             TextField(
  //               controller: _emailController,
  //               decoration: const InputDecoration(labelText: 'Email'),
  //               keyboardType: TextInputType.emailAddress,
  //             ),
  //             const SizedBox(height: 15),
  //             TextField(
  //               controller: _passwordController,
  //               decoration: InputDecoration(
  //                 labelText: 'Password',
  //                 suffixIcon: IconButton(
  //                   icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
  //                   onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
  //                 ),
  //               ),
  //               obscureText: !_isPasswordVisible,
  //             ),
  //             const SizedBox(height: 15),
  //             if (_isRegistering)
  //               TextField(
  //                 controller: _confirmPasswordController,
  //                 decoration: InputDecoration(
  //                   labelText: 'Confirm Password',
  //                   suffixIcon: IconButton(
  //                     icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
  //                     onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
  //                   ),
  //                 ),
  //                 obscureText: !_isPasswordVisible,
  //               ),

  //               //CYBER CAFE NAME:
  //               if (_isRegistering && widget.role == 'cyber')
  //                 TextField(
  //                   controller: _cafeNameController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Enter Your Cafe Name',
  //                     hintText: 'e.g. Yash Cyber Station',
  //                   ),
  //                 ),
  //             const SizedBox(height: 30),
  //             ElevatedButton(
  //               onPressed: _isLoading ? null : _submitAuth,
  //               child: _isLoading
  //                   ? const CircularProgressIndicator(color: Colors.white)
  //                   : Text(_isRegistering ? 'REGISTER' : 'LOG IN'),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 setState(() {
  //                   _isRegistering = !_isRegistering;
  //                   _confirmPasswordController.clear();
  //                 });
  //               },
  //               child: Text(_isRegistering ? 'Already have an account? Log In' : 'Need an account? Register'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA), 
    body: SingleChildScrollView(
      child: Column(
        children: [
          _buildAuthHeader(
            _isRegistering ? 'Create Account' : 'Welcome Back',
            _isRegistering ? 'Join our community today' : 'Sign in to continue',
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTextField(_emailController, "Email Address", Icons.email_outlined),
                const SizedBox(height: 15),

                _buildTextField(
                  _passwordController, 
                  "Password", 
                  Icons.lock_outline, 
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),

                if (_isRegistering) ...[
                  const SizedBox(height: 15),
                  _buildTextField(
                    _confirmPasswordController, 
                    "Confirm Password", 
                    Icons.lock_reset_rounded, 
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  
                  if (widget.role == 'cyber') ...[
                    const SizedBox(height: 15),
                    _buildTextField(_cafeNameController, "Cafe Name", Icons.storefront_outlined, hint: "e.g. Yash Cyber Station"),
                  ],
                ],

                const SizedBox(height: 30),

                // --- SUBMIT BUTTON (This is where OTP is triggered) ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2A3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : () {
                      if (_isRegistering) {
                        // Triggers OTP popup for new users
                        _handleRegistration(); 
                      } else {
                        // Direct login for existing users
                        _submitAuth(); 
                      }
                    },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isRegistering ? 'REGISTER' : 'LOG IN',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // --- TOGGLE BUTTON (Switching between Login/Register) ---
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _confirmPasswordController.clear();
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _isRegistering 
                      ? 'Already have an account? Log In' 
                      : 'Need an account? Register',
                    style: const TextStyle(color: Color(0xFF1A2A3A), fontWeight: FontWeight.w600),
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

// --- REUSABLE COMPONENTS ---

Widget _buildAuthHeader(String title, String sub) {
  return Container(
    height: 240,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Color(0xFF1A2A3A),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(50),
        bottomRight: Radius.circular(50),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 70, color: Colors.white),
        const SizedBox(height: 15),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ],
    ),
  );
}

Widget _buildTextField(
  TextEditingController ctrl, 
  String label, 
  IconData icon, 
  {String? hint, bool isPassword = false, bool? isPasswordVisible, VoidCallback? toggleVisibility}
) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: TextField(
      controller: ctrl,
      obscureText: isPassword ? !(isPasswordVisible ?? false) : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A2A3A), size: 22),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(isPasswordVisible! ? Icons.visibility : Icons.visibility_off, size: 20),
              onPressed: toggleVisibility,
            ) 
          : null,
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
  );
}
}

// --- FIXED AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to Login/Logout status
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. If user is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          return StreamBuilder<DocumentSnapshot>(
            // Use .snapshots() instead of .get() for real-time response
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // 3. If Firestore document exists
              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                final userData = roleSnapshot.data!.data() as Map<String, dynamic>;
                final role = userData['role'] ?? 'user';

                return role == 'cyber' ? const CyberHomePage() : const HomePage();
              }
              
              // 4. While the database is still creating the document
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text("Synchronizing profile...", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          );
        } 
        
        // 5. If logged out, show the start screen
        return const StartSelectionScreen();
      },
    );
  }
}


// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, authSnapshot) {
//         if (authSnapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         // 1. If user is logged in
//         if (authSnapshot.hasData && authSnapshot.data != null) {
//           return StreamBuilder<DocumentSnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(authSnapshot.data!.uid)
//                 .snapshots(),
//             builder: (context, roleSnapshot) {
//               if (roleSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Scaffold(body: Center(child: CircularProgressIndicator()));
//               }

//               // 2. Check Role from Firestore
//               if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
//                 final userData = roleSnapshot.data!.data() as Map<String, dynamic>;
//                 final role = userData['role'] ?? 'user';

//                 // --- ROLE BASED NAVIGATION ---
//                 if (role == 'admin') {
//                   return const AdminPanel(); // Show Admin Panel
//                 } else if (role == 'cyber') {
//                   return const CyberHomePage(); // Show Cyber Cafe Panel
//                 } else {
//                   return const HomePage(); // Show Student Panel
//                 }
//               }
              
//               // 3. Syncing state
//               return const Scaffold(
//                 body: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(),
//                       SizedBox(height: 15),
//                       Text("Assigning Role...", style: TextStyle(fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         } 
        
//         // 4. If logged out
//         return const StartSelectionScreen();
//       },
//     );
//   }
// }

class StartSelectionScreen extends StatelessWidget {
  const StartSelectionScreen({super.key});

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA), // Matches Homepage BG
    body: Column(
      children: [
        // --- TOP CURVED HEADER ---
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2A3A), // Your Navy Blue
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 60, color: Colors.white),
              const SizedBox(height: 15),
              const Text(
                "WELCOME",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "Select your access portal",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // --- BUTTON SECTION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              _buildRoleCard(
                context,
                title: "USER SIDE",
                subtitle: "Apply for services & track status",
                icon: Icons.person_rounded,
                color: Colors.blue.shade700,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(role: 'user'))),
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                context,
                title: "CYBER SIDE",
                subtitle: "Manage requests & workspace",
                icon: Icons.computer_rounded,
                color: const Color(0xFF1A2A3A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(role: 'cyber'))),
              ),
            ],
          ),
        ),

        const Spacer(flex: 2),
      ],
    ),
  );
}

// --- HELPER: MODERN ROLE CARD ---
Widget _buildRoleCard(BuildContext context, {
  required String title, 
  required String subtitle, 
  required IconData icon, 
  required Color color, 
  required VoidCallback onTap
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2A3A)),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
        ],
      ),
    ),
  );
}
}


class RequestDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const RequestDetailScreen({super.key, required this.docId, required this.data});

  // Function to update status in Firebase
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('cyber_requests')
        .doc(docId)
        .update({'status': newStatus});
        
    Navigator.pop(context); // Go back after updating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Details"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User: ${data['sender_email']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Note: ${data['note']}"),
            const Divider(height: 30),
            
            const Text("UPDATE STATUS:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _updateStatus(context, "Processing"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Processing"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _updateStatus(context, "Completed"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Completed"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}