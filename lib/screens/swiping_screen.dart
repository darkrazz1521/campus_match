import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_detail_screen.dart';
import 'package:flutter/services.dart';


class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();

  final List<Map<String, dynamic>> profiles = [
    {
      "name": "Sophia",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuB5bmoZVGZTgzmzMLDHj9Hl-XkxvfD6-7QFEuDuu4KPfV-shBVpIer3Nx5pcOK1ek4qFZV7vartI4b3N3YUmjVFMou7pij2pYTQDLgWPJGmxo62LJrUMyT19eiYlPpdKFv2Nds0WdoJVvCkEar63qrFRWOnVkkqE7DaBLZaBsdmKtt-tL9QCwFo_zhHN4BbfQ00RiRI-klc8NpYa4IqNRFo49qAaBqP72t1JYVvKKhnzoSFH2wDRPyWvNkXLhyPFD3GdY5S4WMfyVo",
      "likes": ["Hiking", "Photography", "Music"],
      "year": "Senior",
      "match": 0.82,
      "bio": "Loves nature walks, capturing moments, and exploring new cafes.",
      "distance": "3 km away",
    },
    {
      "name": "Aarav",
      "image":
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80",
      "likes": ["Reading", "Movies", "Tech"],
      "year": "Junior",
      "match": 0.67,
      "bio": "A tech enthusiast, avid reader, and weekend movie buff.",
      "distance": "2 km away",
    },
  ];

  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);

  // 🌈 Romantic gradient background
  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDEE9),
      Color(0xFFFFC3A0),
    ],
  );

  @override
Widget build(BuildContext context) {
  return Stack(
    alignment: Alignment.bottomCenter,
    children: [
      // 🌌 Animated Background with floating hearts
      AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            // Floating heart particles
            Positioned.fill(
              child: CustomPaint(
                painter: _HeartParticlePainter(),
              ),
            ),
            // Blur overlay for softness
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
          ],
        ),
      ),

      // 🃏 Card Swiper with slight parallax
      profiles.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 100),
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: profiles.length,
                numberOfCardsDisplayed: 2,
                backCardOffset: const Offset(0, 25),
                padding: const EdgeInsets.all(8),
                onSwipe: (previousIndex, currentIndex, direction) => true,
                cardBuilder: (context, index, percentX, percentY) {
                  final profile = profiles[index];
                  return Transform.translate(
                    offset: Offset(percentX * 10, percentY * 5),
                    child: Transform.scale(
                      scale: 1 - (percentY.abs() * 0.05),
                      child: _profileCard(profile, percentX.toDouble()),
                    ),
                  );
                },
              ),
            ),

      // ❤️ Swipe Buttons
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _glowButton(Icons.close, Colors.redAccent,
                () => _swiperController.swipe(CardSwiperDirection.left)),
            _glowButton(Icons.favorite, primaryColor,
                () => _swiperController.swipe(CardSwiperDirection.right)),
            _glowButton(Icons.undo, Colors.orangeAccent, () {}),
          ],
        ),
      ),
    ],
  );
}


  // 🌸 Profile Card UI
  Widget _profileCard(Map<String, dynamic> profile, double percentX) {
  final double likeOpacity = percentX > 0 ? percentX.clamp(0, 1) : 0;
  final double nopeOpacity = percentX < 0 ? (-percentX).clamp(0, 1) : 0;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => ProfileDetailScreen(profile: profile),
        ),
      );
    },
    child: TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.95, end: 1),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale + (percentX.abs() * 0.03), // slight zoom on drag
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 1.5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 🖼 Profile Image with smooth zoom on swipe
              Hero(
                tag: profile["name"],
                child: AnimatedScale(
                  scale: 1 + (percentX.abs() * 0.05),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Image.network(
                    profile["image"],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🌘 Gradient overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 💚 LIKE label
              Positioned(
                top: 40,
                left: 30,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.favorite, color: Colors.green, size: 24),
                          SizedBox(width: 4),
                          Text(
                            "LIKE",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 💔 NOPE label
              Positioned(
                top: 40,
                right: 30,
                child: Opacity(
                  opacity: nopeOpacity,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.close, color: Colors.red, size: 24),
                          SizedBox(width: 4),
                          Text(
                            "NOPE",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 🧠 Info Section (fade-in)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile["name"],
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${profile["year"]} • ${profile["distance"]}",
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile["bio"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 💕 Match % Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Match: ${(profile["match"] * 100).toStringAsFixed(0)}%",
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.pinkAccent.shade100,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: profile["match"],
                                color: Colors.pinkAccent,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 🎯 Interests Chips with icons
                        Wrap(
                          spacing: 6,
                          children: profile["likes"].map<Widget>((like) {
                            final icon = _interestIcon(like);
                            return Chip(
                              avatar: Text(icon, style: const TextStyle(fontSize: 16)),
                              label: Text(like),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _interestIcon(String like) {
  switch (like.toLowerCase()) {
    case "music":
      return "🎵";
    case "hiking":
      return "🏔️";
    case "reading":
      return "📚";
    case "movies":
      return "🎬";
    case "tech":
      return "💻";
    case "photography":
      return "📸";
    default:
      return "💖";
  }
}


  // ✨ Neumorphic-style glowing buttons
  Widget _glowButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.mediumImpact(),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white.withOpacity(0.9),
          child: Icon(icon, size: 32, color: color),
        ),
      ),
    );
  }

  // 💔 Empty state with illustration
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border,
              color: Colors.pinkAccent, size: 80),
          const SizedBox(height: 16),
          Text("No more profiles nearby 💞",
              style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {},
            child: const Text("Refresh Profiles",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}

// 🌸 Floating Heart Particle Painter
class _HeartParticlePainter extends CustomPainter {
  final List<Offset> positions = List.generate(
    12,
    (i) => Offset(
      (100 + i * 50) % 400 + i * 5,
      (i * 80) % 600 + i * 10,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.pinkAccent.withOpacity(0.15);
    for (var i = 0; i < positions.length; i++) {
      final dx = (positions[i].dx + (i * 10)) % size.width;
      final dy = (positions[i].dy + (i * 15)) % size.height;
      canvas.drawCircle(Offset(dx, dy), 10 + (i % 5).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

