import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class Dialogs {
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Login Failed",
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSans(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  static void showEmailNotVerifiedDialog(
    BuildContext context,
    String email,
    {String? password}) { // <-- added optional password
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Email Not Verified",
        style: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.bold,
          color: Colors.orangeAccent,
        ),
      ),
      content: Text(
        "Your email is not verified. Please check your inbox or resend the verification link.",
        style: GoogleFonts.notoSans(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final result = await AuthService().resendVerificationEmail(
              email: email,
              password: password, // 👈 pass password too
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result ?? "Verification email sent!"),
                backgroundColor: result == null ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text("Resend Email"),
        ),
      ],
    ),
  );
}



  static void showSuccessDialog(
      BuildContext context, String message, VoidCallback onContinue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Success 🎉",
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSans(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: onContinue,
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
