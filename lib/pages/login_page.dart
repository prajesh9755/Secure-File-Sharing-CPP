// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signIn() async {
  setState(() => _loading = true);
  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    print("LOGIN OK uid=${cred.user?.uid}");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on FirebaseAuthException catch (e) {
    print("LOGIN ERROR code=${e.code}, msg=${e.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login failed: ${e.message}")),
    );
  } catch (e) {
    print("LOGIN EX ${e.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unexpected error: $e")),
    );
  } finally {
    setState(() => _loading = false);
  }
}

// Future<void> _handleLogin() async {
//   try {
//     // 1. Sign in with Firebase
//     UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: _emailCtrl.text.trim(),
//       password: _passCtrl.text.trim(),
//     );

//     // 2. Fetch the user's role from Firestore
//     var userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
//     String role = userDoc.data()?['role'] ?? 'user';

//     // 3. CHECK: If this is the USER APP, but the account is an ADMIN
//     if (role == 'admin') {
//       await FirebaseAuth.instance.signOut(); // Log them out immediately
      
//       // 4. Show the "Access Denied" Popup
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Access Denied"),
//           content: const Text("Admin accounts cannot login through the Student app. Please use the Admin Desktop portal."),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
//           ],
//         ),
//       );
//     } else {
//       // Allow Student or Cyber login
//       print("Login Successful");
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
//   }
// }


  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Login')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
  //           TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
  //           const SizedBox(height: 16),
  //           ElevatedButton(onPressed: _loading ? null : _signIn, child: _loading ? const CircularProgressIndicator() : const Text('Login')),
  //           TextButton(onPressed: ()=> Navigator.pushNamed(context, '/register'), child: const Text('Register'))
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    body: SingleChildScrollView( // Prevents overflow when keyboard appears
      child: Column(
        children: [
          // Navy Blue Header
          _buildAuthHeader("Login", "Welcome back! Please sign in"),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTextField(_emailCtrl, "Email", Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField(_passCtrl, "Password", Icons.lock_outline, isPassword: true),
                const SizedBox(height: 30),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2A3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    onPressed: _loading ? null : _signIn,
                    child: _loading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF1A2A3A))),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAuthHeader(String title, String sub) {
  return Container(
    height: 250,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Color(0xFF1A2A3A),
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_circle, size: 80, color: Colors.white),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ],
    ),
  );
}

Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: TextField(
      controller: ctrl,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A2A3A)),
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
  );
}
}