import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personality Quiz")),
      body: Center(
        child: Text(
          "Quiz coming soon!",
          style: GoogleFonts.beVietnamPro(fontSize: 18),
        ),
      ),
    );
  }
}
