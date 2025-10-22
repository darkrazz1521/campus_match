// /screens/swiping_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_detail_screen.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../providers/swipe_provider.dart';
import 'dart:math' as math;

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentCardIndex = 0;

  late AnimationController _animationController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Profiles are now loaded automatically by the SwipeProvider
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showMatchDialog(UserModel matched) {
    _confettiController.play(); // 🎉 Trigger confetti

    showGeneralDialog(
      context: context,
      barrierLabel: "match",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 🎊 Confetti burst behind the dialog
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 15,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.3,
            ),

            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🌟 Add Lottie animation on match
                      Lottie.asset(
                        'assets/animations/love.json', // 👈 add your animation
                        width: 160,
                        repeat: false,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "It's a Match!",
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        matched.name,
                        style: GoogleFonts.beVietnamPro(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Say Hi 💬"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage(String photoData) {
    if (photoData.startsWith('http')) {
      // It's a normal URL
      return Image.network(
        photoData,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        },
      );
    } else {
      // Assume it's Base64
      try {
        final bytes = const Base64Decoder().convert(photoData);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return Image.network(
          'https://via.placeholder.com/400x600.png?text=Invalid+Image',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
  }

  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);

  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDEE9), Color(0xFFFFC3A0)],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<SwipeProvider>(
      builder: (context, swipeProvider, child) {
        // --- ADD THIS LOGIC (THE LISTENER) ---
        // Check if the provider has a match to show
        if (swipeProvider.matchToShow != null) {
          // Show the dialog *after* the build frame is complete
          // This is the safe way to show a dialog from a build method
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check again in case it was cleared by a rapid rebuild
            if (swipeProvider.matchToShow != null && mounted) {
              print("🎉 Match detected by Consumer! Showing dialog.");
              _showMatchDialog(swipeProvider.matchToShow!);
              swipeProvider.clearMatchToShow(); // Clear the state
            }
          });
        }
        // --- END OF LISTENER LOGIC ---

        // The rest of your build method returns the Stack
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background (no change)
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(gradient: bgGradient),
              child: Stack(
                /* ... */
              ),
            ),

            // Card Swiper
            swipeProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                : swipeProvider.profiles.isEmpty
                ? _buildEmptyState(swipeProvider) // Pass provider
                : Padding(
                    padding: const EdgeInsets.only(top: 80, bottom: 100),
                    child: CardSwiper(
                      key: ValueKey(swipeProvider.currentUser?.uid ?? 'logged_out'),
                      controller: _swiperController,
                      cardsCount: swipeProvider.profiles.length,
                      numberOfCardsDisplayed: math.min(
                        2,
                        swipeProvider.profiles.length,
                      ),
                      backCardOffset: const Offset(0, 25),
                      padding: const EdgeInsets.all(8),
                      // --- MODIFY 'onSwipe' ---
                      onSwipe: (previousIndex, currentIndex, direction) async {
                        if (previousIndex < 0 ||
                            previousIndex >= swipeProvider.profiles.length) {
                          print(
                            "Swipe blocked: Invalid previousIndex $previousIndex",
                          );
                          return false;
                        }

                        _currentCardIndex = currentIndex ?? 0;

                        if (!swipeProvider.canSwipe) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "🚀 You’re out of likes! Get Unlimited Swipes with Premium.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        print("Swipe blocked: Daily limit reached.");
                        return false;
                      }

                        final swipedUser =
                            swipeProvider.profiles[previousIndex];
                        final bool liked =
                            direction == CardSwiperDirection.right;

                        // --- THIS IS THE FIX ---
                        // DO NOT AWAIT. Call it and forget.
                        swipeProvider.swipe(
                          swipedUser, // Pass the full user object
                          liked,
                          false, // Not a super like
                        );

                        // Return true IMMEDIATELY to unblock the UI
                        return true;
                        // --- END FIX ---
                      },
                      // In swiping_screen.dart -> build method -> CardSwiper
                      cardBuilder: (context, index, percentX, percentY) {
                        final profiles =
                            swipeProvider.profiles; // Get a local reference
                        final profileCount = profiles.length;
                        final currentUid =
                            swipeProvider.currentUser?.uid ?? "UNKNOWN_UID";

                        // Boundary check
                        if (index < 0 || index >= profileCount) {
                          print(
                            "‼️ cardBuilder: Invalid index $index (Count: $profileCount). Current user: $currentUid",
                          );
                          return Container(
                            color: Colors.red.withOpacity(0.5),
                          ); // VISIBLE ERROR
                        }

                        final profile = profiles[index];
                        print(
                          "  cardBuilder: Index $index -> UID ${profile.uid} (Current: $currentUid)",
                        ); // Log before check

                        // Self-profile check
                        if (profile.uid == currentUid) {
                          print(
                            "‼️ CRITICAL ERROR in cardBuilder: Trying to build self-profile (UID: ${profile.uid}) at index $index!",
                          );
                          return Container(
                            // Return a distinct placeholder for self-profile
                            color: Colors.orange.withOpacity(0.5),
                            child: Center(
                              child: Text(
                                "ERROR\nSelf Profile\nUID: ${profile.uid}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        // If checks pass, build the actual card
                        return _profileCard(profile, percentX.toDouble());
                      },
                    ),
                  ),

            // Swipe Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _glowButton(
                    Icons.close,
                    Colors.redAccent,
                    (swipeProvider.isSwiping || swipeProvider.profiles.isEmpty)
                        ? null
                        : () =>
                              _swiperController.swipe(CardSwiperDirection.left),
                  ),
                  _glowButton(
                    Icons.favorite,
                    primaryColor,
                    (swipeProvider.isSwiping || swipeProvider.profiles.isEmpty)
                        ? null
                        : () => _swiperController.swipe(
                            CardSwiperDirection.right,
                          ),
                  ),

                  // Third button: undo / super-like
                  Builder(
                    builder: (context) {
                      // We get user data from swipeProvider's currentUser
                      final currentUserData = swipeProvider.currentUser;
                      if (currentUserData == null) {
                        return Container(); // User not loaded yet
                      }

                      final isPremiumLocal = currentUserData.isPremium;
                      final superLikesUsed =
                          currentUserData.superLikesUsedToday ?? 0;

                      // Use constants for clarity
                      final int maxPremiumSuperLikes = 10;

                      final bool isSuperLikeMode =
                          isPremiumLocal &&
                          superLikesUsed < maxPremiumSuperLikes;
                      final bool isUndoAvailable =
                          swipeProvider.lastSwipedUserId != null;

                      final icon = isSuperLikeMode ? Icons.star : Icons.undo;
                      final color = isSuperLikeMode
                          ? Colors.blueAccent
                          : (isUndoAvailable ? Colors.amber : Colors.grey);

                      final onPressed =
                          (swipeProvider.isSwiping ||
                              swipeProvider.profiles.isEmpty)
                          ? null
                          : () async {
                              // This can stay async for the undo logic
                              if (isSuperLikeMode) {
                                // Super like flow
                                final index = _currentCardIndex;
                                if (index < 0 ||
                                    index >= swipeProvider.profiles.length) {
                                  return;
                                }

                                final target = swipeProvider.profiles[index];

                                // --- MODIFY THE SUPER-LIKE CALL ---
                                // DO NOT AWAIT
                                swipeProvider.swipe(
                                  target, // Pass the full user object
                                  true,
                                  true, // Super Like
                                );

                                // Just animate the card
                                _swiperController.swipe(
                                  CardSwiperDirection.right,
                                );

                                // We NO LONGER check for match here.
                                // The Consumer logic will handle it.
                                // --- END FIX ---
                              } else {
                                // Undo flow (this logic is fine)
                                if (!isUndoAvailable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No swipe recorded to undo.",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final res = await swipeProvider
                                    .revertLastSwipe();

                                if (res['success'] == true) {
                                  _swiperController.undo();
                                  // Provider handles reloading profiles
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? "Undo failed.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            };
                      return _glowButton(icon, color, onPressed);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileCard(UserModel profile, double percentX) {
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
          scale: scale + (percentX.abs() * 0.03),
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
                Hero(
                  tag: profile.name,
                  child: AnimatedScale(
                    scale: 1 + (percentX.abs() * 0.05),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: profile.photos.isNotEmpty
                        ? _buildProfileImage(profile.photos.first)
                        : Image.network(
                            'https://via.placeholder.com/400x600.png?text=No+Image',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
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
                Positioned(
                  top: 40,
                  left: 30,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
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
                Positioned(
                  top: 40,
                  right: 30,
                  child: Opacity(
                    opacity: nopeOpacity,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
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
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${profile.collegeYear} • ${profile.distance}",
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Match: ${(profile.matchScore * 100).toStringAsFixed(0)}%",
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.pinkAccent.shade100,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: profile.matchScore,
                                  color: Colors.pinkAccent,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: profile.interests.map<Widget>((like) {
                              final icon = _interestIcon(like);
                              return Chip(
                                avatar: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                label: Text(like),
                                backgroundColor: Colors.white.withOpacity(0.2),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
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

  Widget _glowButton(IconData icon, Color color, VoidCallback? onPressed) {
    final bool isDisabled = onPressed == null;
    final Color displayColor = isDisabled ? Colors.grey.shade400 : color;
    final double elevation = isDisabled ? 0 : 20;

    return GestureDetector(
      // Only execute handlers if not disabled
      onTapDown: isDisabled ? null : (_) => HapticFeedback.mediumImpact(),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(1.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.transparent
                  : displayColor.withOpacity(0.45), // Use displayColor
              blurRadius: elevation,
              spreadRadius: isDisabled ? 0 : 3,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: isDisabled
              ? Colors.grey.shade200
              : Colors.white.withOpacity(0.95),
          child: Icon(icon, size: 32, color: displayColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SwipeProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, color: Colors.pinkAccent, size: 80),
          const SizedBox(height: 16),
          Text(
            "No more profiles nearby 💞",
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            // Call provider's loadProfiles method
            onPressed: () => provider.loadProfiles(),
            child: const Text(
              "Refresh Profiles",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartParticlePainter extends CustomPainter {
  final List<Offset> positions = List.generate(
    12,
    (i) => Offset((100 + i * 50) % 400 + i * 5, (i * 80) % 600 + i * 10),
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
