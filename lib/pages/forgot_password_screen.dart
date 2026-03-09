import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cpp/firebase/auth_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isOtpVerified = false;
  String? _generatedOtp;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
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

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email exists using a different approach
      final auth = AuthService();
      final emailExists = await auth.checkEmailExists(_emailController.text.trim());
      
      if (!emailExists) {
        _showErrorSnackBar('No account found with this email address');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Secure random OTP
      final random = Random.secure();
      final String otp = (random.nextInt(900000) + 100000).toString();
      _generatedOtp = otp;

      // ✅ Now check if email actually sent before showing success
      final bool emailSent = await _sendOtpEmail(
        _emailController.text.trim(), 
        otp
      );

      if (!emailSent) {
        _showErrorSnackBar('Failed to send OTP. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
      
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
      
      _startResendTimer();
      _showSuccessSnackBar('OTP sent to your email address');

    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the OTP');
      return;
    }

    if (_otpController.text.trim() != _generatedOtp) {
      _showErrorSnackBar('Invalid OTP. Please check and try again');
      return;
    }

    setState(() {
      _isOtpVerified = true;
      _isLoading = true;
    });

    try {
      print('Attempting to send Firebase password reset email to: ${_emailController.text.trim()}');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      print('Firebase password reset email sent successfully');
      _showSuccessSnackBar('Password reset email sent! Check your inbox (including spam folder).');
      
      // Navigate back to login after successful OTP verification
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } on FirebaseAuthException catch (e) {
      print('Firebase password reset error: ${e.code} - ${e.message}');
      String errorMessage = _getErrorMessage(e);
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      print('Unexpected error during password reset: $e');
      _showErrorSnackBar('Failed to send reset email: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'auth/invalid-email':
        return 'Invalid email format';
      case 'auth/user-not-found':
        return 'User not found. Please check the email';
      case 'auth/too-many-requests':
        return 'Too many password reset attempts. Try again later';
      case 'auth/operation-not-allowed':
        return 'Password reset is disabled. Contact support';
      default:
        return 'Failed to send reset email: ${e.message ?? 'Unknown error'}';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<bool> _sendOtpEmail(String email, String otp) async {
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
      ),
    );
  }

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    size: 60,
                    color: Color(0xFF1A2A3A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpVerified 
                        ? 'Password reset email has been sent to your email'
                        : 'Enter your email to receive OTP verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            if (!_isOtpVerified) ...[
              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1A2A3A)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_isOtpSent) ...[
                // OTP Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otpController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter 6-digit OTP',
                      prefixIcon: const Icon(Icons.security, color: Color(0xFF1A2A3A)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Resend OTP button with timer
                if (_resendTimer > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Resend OTP in $_resendTimer seconds',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A2A3A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: Color(0xFF1A2A3A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              
              const SizedBox(height: 20),
            ],
            
            // Action Buttons
            if (!_isOtpSent)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2A3A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            else if (!_isOtpVerified)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA1AF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'OTP Verified Successfully',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
