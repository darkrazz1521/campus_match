import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Section Title Widget
Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1b0d14),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFF04299),
          decorationThickness: 2,
        ),
      ),
    );

/// Label Text Style
TextStyle fieldLabelStyle() => GoogleFonts.beVietnamPro(
      fontSize: 14,
      color: Colors.black87,
      fontWeight: FontWeight.w600,
    );

/// Labeled TextField
Widget buildLabeledField({
  required String label,
  required IconData icon,
  required TextEditingController controller,
  required Color primaryColor,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: fieldLabelStyle()),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF9A4C73)),
              hintText: "Enter $label",
              filled: true,
              fillColor: Colors.white.withOpacity(0.7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );


/// Photo Card
Widget buildPhotoCard(String url) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(2, 4),
              )
            ],
          ),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );

/// Add Photo Card
Widget buildAddPhotoCard(BuildContext context, Color primaryColor,
    {required VoidCallback onTap}) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo, color: Colors.pinkAccent, size: 36),
        ),
      ),
    ),
  );
}


/// Personality Quiz Card
Widget buildPersonalityQuizCard() => Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Take the Quiz",
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Discover your personality type and find better matches.",
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
