import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'dart:async';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password; // added password
  const VerifyEmailScreen({super.key, required this.email, required this.password});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _auth = AuthService();
  bool _isResending = false;
  bool _isChecking = false;

  // ✅ Check if user verified email
  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(seconds: 2)); // smooth UX

    // Login temporarily with known password
    String? error = await _auth.loginUser(
      email: widget.email,
      password: widget.password, // use password
    );

    setState(() => _isChecking = false);

    if (error == 'Please verify your email before logging in.') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still not verified. Try again later.')),
      );
    } else {
      // Update Firestore emailVerified status
      await _auth.updateEmailVerifiedStatus();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ✅ Resend verification email
  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    final error = await _auth.resendVerificationEmail(
      email: widget.email, 
      password: widget.password, // pass password
    );

    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Verification email sent again!'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF04299);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_rounded, size: 100, color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  "Verify your email",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "A verification link has been sent to:",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkVerification,
                  icon: _isChecking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.verified_outlined, color: Colors.white),
                  label: Text(
                    _isChecking ? "Checking..." : "I’ve Verified",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: Text(
                    _isResending
                        ? "Resending..."
                        : "Didn’t get the email? Resend",
                    style: TextStyle(
                        color: primaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
