import 'package:cpp/cyber_cafe/cyber_home_page.dart';
import 'package:cpp/pages/home_page_new.dart';
import 'package:cpp/pages/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:async';

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

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
  // OTP related variables
  String? _generatedOtp; 
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cafeNameController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final cafeName = _cafeNameController.text.trim();

      // 1. Email Validation (basic check, already validated before OTP)
      if (!_isValidEmail(email)) {
        throw "Please enter a valid email address";
      }

      // 2. Password Validation (basic check, already validated before OTP)
      if (_isRegistering && password.length < 8) {
        throw "Password must be at least 8 characters long";
      }

      // 3. Cyber-specific Validation (basic check, already validated before OTP)
      if (_isRegistering && widget.role == 'cyber' && cafeName.isEmpty) {
        throw "Please enter a cafe name.";
      }

      // 4. Perform Authentication
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

      // 5. Handle Registration Data (Save to Firestore)
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
      
      // 6. Handle Login Validation (Prevent wrong-side login)
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

      // 7. Success - Close Login Screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Firebase error message handler
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your internet connection';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email';
      case 'invalid-credential':
        return 'The credentials provided are invalid';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }

  // Error message display
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Success message display
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- THE OTP GENERATION LOGIC ---
  void _handleRegistration() {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String cafeName = _cafeNameController.text.trim();
    
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter an email address");
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar("Please enter a valid email address");
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter a password");
      return;
    }

    // Check password requirements before OTP
    if (password.length < 8) {
      _showErrorSnackBar("Password must be at least 8 characters long");
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showErrorSnackBar("Password must contain at least one uppercase letter");
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showErrorSnackBar("Password must contain at least one lowercase letter");
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showErrorSnackBar("Password must contain at least one number");
      return;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showErrorSnackBar("Password must contain at least one special character");
      return;
    }

    // Check cafe name for cyber users
    if (widget.role == 'cyber' && cafeName.isEmpty) {
      _showErrorSnackBar("Please enter a cafe name");
      return;
    }
    if (widget.role == 'cyber' && cafeName.length < 3) {
      _showErrorSnackBar("Cafe name must be at least 3 characters long");
      return;
    }

    // Check if email already exists before generating OTP
    _checkEmailAndGenerateOtp();
  }

  Future<void> _checkEmailAndGenerateOtp() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = AuthService();
      final emailExists = await auth.checkEmailExists(_emailController.text.trim());
      
      if (emailExists) {
        _showErrorSnackBar('This email is already registered. Please use a different email or login.');
        setState(() => _isLoading = false);
        return;
      }

      // Check if cafe name already exists for cyber users
      if (widget.role == 'cyber') {
        final existing = await FirebaseFirestore.instance
            .collection('cafes')
            .where('name', isEqualTo: _cafeNameController.text.trim().toLowerCase())
            .get();

        if (existing.docs.isNotEmpty) {
          _showErrorSnackBar('Cafe name already taken! Please choose a different name.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // ✅ Secure random OTP
      final random = Random.secure();
      String otp = (random.nextInt(900000) + 100000).toString();
      _generatedOtp = otp;

      // ✅ Now check if email actually sent before showing dialog
      final bool emailSent = await sendOtpEmail(_emailController.text.trim(), otp);

      if (!emailSent) {
        _showErrorSnackBar('Failed to send OTP. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // Show the popup only if email was sent successfully
      _showOtpDialog();

    } catch (e) {
      _showErrorSnackBar('Error checking email: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // --- THE OTP DIALOG METHOD ---
  void _showOtpDialog() {
    TextEditingController otpController = TextEditingController();
    bool isOtpVerified = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                enabled: !isOtpVerified,
              ),
              const SizedBox(height: 15),
              if (_resendTimer > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Resend OTP in $_resendTimer seconds',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    String email = _emailController.text.trim();
                    String otp = (Random().nextInt(900000) + 100000).toString();
                    _generatedOtp = otp;
                    sendOtpEmail(email, otp);
                    _startResendTimer();
                    _showSuccessSnackBar("OTP resent successfully");
                  },
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(color: Color(0xFF4CA1AF), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2A3A)),
              onPressed: isOtpVerified ? null : () {
                if (otpController.text == _generatedOtp) {
                  setState(() {
                    isOtpVerified = true;
                  });
                  _timer?.cancel();
                  Navigator.pop(context);
                  _submitAuth(); // Your actual Firebase registration call
                } else {
                  // Show error for wrong OTP
                  _showErrorSnackBar("Invalid OTP, please try again");
                }
              },
              child: isOtpVerified
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Verify", 
                      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    ),
            ),
          ],
        ),
      ),
    );
    
    // Start timer when dialog opens
    _startResendTimer();
  }

  Future<bool> sendOtpEmail(String email, String otp) async {
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
          // ✅ 'origin' header REMOVED — was blocking on Android
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'email': email,       // must match your EmailJS template variable
            'to_email': email,    // added as backup
            'passcode': otp,
          },
        }),
      );

      print('✅ EmailJS Status: ${response.statusCode}');
      print('✅ EmailJS Body: ${response.body}');

      return response.statusCode == 200; // ✅ returns true/false

    } catch (e) {
      print('❌ EmailJS Error: $e');
      return false;
    }
  }

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

                  // --- FORGOT PASSWORD LINK (Only show during login) ---
                  if (!_isRegistering)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF4CA1AF),
                            fontWeight: FontWeight.w600,
                          ),
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
              
              // 4. ✅ FIXED: Add timeout and error handling for missing document
              return FutureBuilder(
                future: Future.delayed(const Duration(seconds: 10)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // Show error dialog and navigate back
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('Profile Setup Required'),
                          content: const Text(
                            'Your account was created but profile data is missing. '
                            'Please contact support or try logging in again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                FirebaseAuth.instance.signOut();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const StartSelectionScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text('Back to Login'),
                            ),
                          ],
                        ),
                      );
                    });
                    
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 15),
                            Text("Setting up profile...", style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 15),
                          Text("Synchronizing profile...", style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        } 
        
        // 5. If logged out, show start screen
        return const StartSelectionScreen();
      },
    );
  }
}

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
