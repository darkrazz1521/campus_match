import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_detail_screen.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/matchmaking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';

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

  List<UserModel> profiles = [];
  bool isLoading = true;
  bool canSwipe = true; // 🆕 Track swipe capability
  bool isPremium = false; // 🆕 Track premium status
  final UserService _userService = UserService.instance;
  final MatchmakingService _matchmakingService = MatchmakingService.instance;

  final int _undosUsedToday = 0;
  final int _maxFreeUndos = 1;
  final bool _isMatchFound = false;

  @override
  void initState() {
    super.initState();
    // 🆕 Initialize Animation Controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProfiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String currentUid = currentUser.uid;
      final UserModel? userData = await _userService.getUserById(currentUid);

      if (userData == null) return;

      // 🆕 Check swipe limit
      final isNewDay = !UserService.isSameDay(
        DateTime.now(),
        userData.lastSwipeDate ?? DateTime(2000),
      );
      final hasLimit =
          !userData.isPremium && userData.dailySwipeCount >= 50 && !isNewDay;

      if (isNewDay && mounted) {
        // notify user that swipes reset
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your swipes have been reset for today!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // ✅ 1. Fetch all users
final fetchedUsers = await _userService.getAllUsers(currentUid);

// ✅ 2. Load user’s saved filter preferences
final filterPrefs = await _userService.getFilterPreferences(currentUid);

// ✅ 3. Apply filters only for premium users
List<UserModel> processedUsers;
if (userData.isPremium && filterPrefs != null) {
  processedUsers = await _matchmakingService.processMatches(
    users: fetchedUsers,
    filters: filterPrefs, // apply saved filters here
  );
} else {
  processedUsers = await _matchmakingService.processMatches(
    users: fetchedUsers,
  );
}



      setState(() {
        profiles = processedUsers;
        isLoading = false;
        isPremium = userData.isPremium;
        canSwipe = userData.isPremium || !hasLimit;
      });
    } catch (e) {
      print("Error loading profiles: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load profiles: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showMatchDialog(UserModel matched) {
    showGeneralDialog(
      context: context,
      barrierLabel: "match",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
            child: Container(
              width: 300,
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
                  const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "It's a Match!",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matched.name,
                    style: GoogleFonts.beVietnamPro(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                    child: const Text("Say Hi"),
                  ),
                ],
              ),
            ),
          ),
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
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 🌌 Animated Background
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(gradient: bgGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _HeartParticlePainter()),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),

        // 🃏 Card Swiper
        isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
            : profiles.isEmpty
            ? _buildEmptyState()
            : Padding(
                padding: const EdgeInsets.only(top: 80, bottom: 100),
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: profiles.length,
                  numberOfCardsDisplayed: 2,
                  backCardOffset: const Offset(0, 25),
                  padding: const EdgeInsets.all(8),
                  onSwipe: (previousIndex, currentIndex, direction) async {
                    _currentCardIndex = currentIndex ?? 0;

                    if (!canSwipe) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Daily swipe limit reached! Go Premium for unlimited swipes.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return false;
                    }

                    final swipedUser = profiles[previousIndex];
                    final currentUid = FirebaseAuth.instance.currentUser!.uid;

                    final res = await _userService.updateSwipe(
                      currentUid: currentUid,
                      targetUid: swipedUser.uid,
                      liked: direction == CardSwiperDirection.right,
                      superLike: false,
                    );

                    // If a match occurred -> show animation
                    if (res['success'] == true && res['isMatch'] == true) {
                      _showMatchDialog(swipedUser);
                    }

                    // Reload profiles if close to limit
                    if (!isPremium &&
                        (profiles.length - (currentIndex ?? 0)) <= 5) {
                      _loadProfiles();
                    }

                    return res['success'] == true;
                  },

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
        // ❤️ Swipe Buttons (replaced)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _glowButton(
                Icons.close,
                Colors.redAccent,
                () => _swiperController.swipe(CardSwiperDirection.left),
              ),
              _glowButton(
                Icons.favorite,
                primaryColor,
                () => _swiperController.swipe(CardSwiperDirection.right),
              ),

              // Third button: undo for free / super-like for premium
              FutureBuilder<UserModel?>(
                future: _userService.getUserById(
                  FirebaseAuth.instance.currentUser!.uid,
                ),
                builder: (context, snap) {
                  final isPremiumLocal = snap.data?.isPremium ?? isPremium;
                  final icon = isPremiumLocal ? Icons.star : Icons.undo;
                  final color = isPremiumLocal
                      ? Colors.blueAccent
                      : Colors.grey;
                  return _glowButton(icon, color, () async {
                    if (isPremiumLocal) {
                      // Super like flow
                      final currentUid = FirebaseAuth.instance.currentUser!.uid;
                      final currentUser = await _userService.getUserById(
                        currentUid,
                      );
                      final index = _currentCardIndex;
                      if (index < 0 || index >= profiles.length) return;
                      final target = profiles[index];
                      final res = await _userService.updateSwipe(
                        currentUid: currentUid,
                        targetUid: target.uid,
                        liked: true,
                        superLike: true,
                      );
                      if (res['success'] == true) {
                        // force swipe right visually
                        _swiperController.swipe(CardSwiperDirection.right);
                        if (res['isMatch'] == true) {
                          _showMatchDialog(target);
                        }
                      } else {
                        final msg = res['message'] ?? 'Super Like failed';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } else {
                      // Undo for free user - check / consume
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final allowed = await _userService.consumeUndo(
                        uid,
                        maxFreeUndos: _maxFreeUndos,
                      );
                      if (!allowed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No undos left today. Upgrade to Premium for more.",
                            ),
                          ),
                        );
                        return;
                      }
                      _swiperController.undo();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
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

  Widget _glowButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.mediumImpact(),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(1.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white.withOpacity(0.95),
          child: Icon(icon, size: 32, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            onPressed: _loadProfiles,
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
