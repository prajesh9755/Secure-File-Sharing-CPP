import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
  setState(()=> _loading = true);
  try {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    print('REGISTER OK uid=${cred.user?.uid}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created')),
      );
      Navigator.pop(context); // back to login
    }
  } on FirebaseAuthException catch (e) {
    print('REGISTER ERROR code=${e.code} message=${e.message}');
    final msg = e.message ?? e.code;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: $msg')),
      );
    }
  } catch (e) {
    print('REGISTER EX ${e.toString()}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register error: ${e.toString()}')),
      );
    }
  } finally {
    setState(()=> _loading = false);
  }
}


  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Register')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
  //           TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
  //           const SizedBox(height: 16),
  //           ElevatedButton(onPressed: _loading ? null : _register, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
  //         ],
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
          _buildAuthHeader("Register", "Create a new account to begin"),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTextField(_emailCtrl, "Email", Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField(_passCtrl, "Password", Icons.lock_outline, isPassword: true),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2A3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
