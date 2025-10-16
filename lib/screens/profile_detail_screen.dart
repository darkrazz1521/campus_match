import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';

class ProfileDetailScreen extends StatelessWidget {
  final UserModel profile;

  const ProfileDetailScreen({Key? key, required this.profile}) : super(key: key);

  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);
  final Color bgColor = const Color(0xFFFCF8FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Image with Hero
            Stack(
              children: [
                Hero(
                  tag: profile.uid, // Unique tag for hero animation
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    child: Image.network(
                      profile.photos.isNotEmpty
                          ? profile.photos.first
                          : 'https://via.placeholder.com/400x600.png?text=No+Image',
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: GoogleFonts.beVietnamPro(
                                    fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${profile.collegeYear} Year • ${profile.branch}",
                                style: GoogleFonts.notoSans(fontSize: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top match badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor, accentColor]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${(profile.matchScore * 100).toStringAsFixed(0)}% Match",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Expanded Info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio
                    Text(
                      "About Me",
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.bio.isNotEmpty ? profile.bio : "No bio available",
                      style: GoogleFonts.notoSans(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    // Interests
                    Text(
                      "Interests",
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: const Color(0xFFF3E7ED),
                          labelStyle: const TextStyle(color: Colors.black87),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Buttons
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _animatedCircleButton(Icons.close, Colors.redAccent, 28, () => Navigator.pop(context)),
          _animatedCircleButton(Icons.favorite, primaryColor, 32, () => Navigator.pop(context), radius: 40),
        ],
      ),
    );
  }

  Widget _animatedCircleButton(IconData icon, Color color, double iconSize, VoidCallback onTap,
      {double radius = 30}) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 1, end: 1.1),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: CircleAvatar(
              backgroundColor: color == primaryColor ? primaryColor : Colors.white,
              radius: radius,
              child: Icon(icon, color: color == primaryColor ? Colors.white : color, size: iconSize),
            ),
          );
        },
      ),
    );
  }
}
