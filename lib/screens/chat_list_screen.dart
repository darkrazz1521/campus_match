import 'dart:typed_data'; // Point 8: For Uint8List
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'package:shimmer/shimmer.dart'; // Point 3: Import Shimmer

import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'package:lottie/lottie.dart';

// Point 15: Extract background shapes into a stateless widget
class GlassBackgroundBubbles extends StatelessWidget {
  final Color accentColor;
  const GlassBackgroundBubbles({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.5),
                    Colors.orangeAccent.withOpacity(0.5)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.4),
                    Colors.purpleAccent.withOpacity(0.4)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Point 3 & 15: Extract skeleton loader into a stateless widget with Shimmer
class ChatSkeletonItem extends StatelessWidget {
  final bool isDarkMode;
  const ChatSkeletonItem({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4);
    final highlightColor =
        isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration:
                  BoxDecoration(color: highlightColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 16, width: 120, color: highlightColor),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 200, color: baseColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  final Color accentColor = const Color(0xFF9A4C73);
  final UserService _userService = UserService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Point 9: Helper function for Dismissible action
  void _unmatchUser(String otherUid) {
    // TODO: Implement your unmatch logic here
    // e.g., call a service: _matchService.unmatch(currentUid, otherUid);
    debugPrint("Unmatching user: $otherUid");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unmatched user $otherUid")),
    );
  }

  // Point 9: Helper widget for Dismissible background
  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      child: const Icon(Icons.delete_sweep, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<UserProvider>().currentUser?.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Gradient dynamicBgGradient = isDarkMode
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF230342), Color(0xFF001F3F)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
          );

    final Color dynamicTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color dynamicIconColor = isDarkMode ? Colors.white70 : Colors.black87;

    if (currentUid == null) {
      return const Center(child: Text("Please log in."));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.local_fire_department, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Matches 💬",
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dynamicTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: dynamicIconColor),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: dynamicTextColor,
          unselectedLabelColor: dynamicTextColor.withOpacity(0.6),
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'New Matches'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: dynamicBgGradient),
          ),
          // Point 15: Use the extracted widget
          GlassBackgroundBubbles(accentColor: accentColor),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(
                  currentUid: currentUid,
                  isNewMatches: false,
                  isDarkMode: isDarkMode,
                ),
                _buildMatchList(
                  currentUid: currentUid,
                  isNewMatches: true,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList({
    required String currentUid,
    required bool isNewMatches,
    required bool isDarkMode,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: currentUid);

    if (isNewMatches) {
      query = query.where('lastMessage', isEqualTo: null);
    } else {
      query = query
          .where('lastMessage', isNotEqualTo: null)
          .orderBy('lastMessageTimestamp', descending: true);
    }

    // Point 10: Add pagination limit (full pagination is a larger task)
    query = query.limit(20);

    // Point 12: Add RefreshIndicator
    return RefreshIndicator(
      onRefresh: () async {
        // This setState will force the StreamBuilder to rebuild,
        // effectively "refreshing" the live data.
        setState(() {});
      },
      color: accentColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Use a list of shimmer skeletons for initial load
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) =>
                  ChatSkeletonItem(isDarkMode: isDarkMode),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading matches."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Point 14: Pass context to empty state
            return _buildEmptyState(isNewMatches: isNewMatches);
          }

          final matches = snapshot.data!.docs;

          return AnimationLimiter(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()), // For RefreshIndicator
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final matchData = matches[index].data() as Map<String, dynamic>;
                final List<dynamic> users = matchData['users'];
                final String otherUid = users.firstWhere(
                    (uid) => uid != currentUid,
                    orElse: () => '');

                if (otherUid.isEmpty) return const SizedBox.shrink();

                // Point 13: Null-safe data extraction
                final String lastMessage =
                    (matchData['lastMessage'] ?? "Say hi!").toString();
                final Timestamp? timestamp =
                    matchData['lastMessageTimestamp'] as Timestamp?;
                final String lastSenderId =
                    (matchData['lastMessageSenderId'] ?? '').toString();

                final bool isUnread =
                    (isNewMatches) || (lastSenderId != currentUid);

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: FutureBuilder<UserModel?>(
                        future: _userService.getUserById(otherUid),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            // Point 3: Use the Shimmer skeleton
                            return ChatSkeletonItem(isDarkMode: isDarkMode);
                          }

                          final otherUser = userSnapshot.data!;
                          final String imageUrl =
                              (otherUser.photos.isNotEmpty)
                                  ? otherUser.photos[0]
                                  : '';
                          // Point 5: Get real online status (assuming UserModel has `isOnline`)
                          final bool isOnline = otherUser.isOnline ?? false;

                          // Point 9: Add Dismissible
                          return Dismissible(
                            key: Key(otherUser.uid), // Unique key
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _unmatchUser(otherUser.uid);
                            },
                            background: _buildDismissibleBackground(),
                            child: ChatListItem(
                              name: otherUser.name,
                              message: lastMessage,
                              imageUrl: imageUrl,
                              timestamp: timestamp, // Pass nullable timestamp
                              isUnread: isUnread,
                              isDarkMode: isDarkMode,
                              accentColor: accentColor,
                              // Point 1 & 11: Pass unique UID for Hero tag
                              otherUid: otherUser.uid,
                              // Point 5: Pass real online status
                              isOnline: isOnline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      matchName: otherUser.name,
                                      matchImage: imageUrl,
                                      matchUid: otherUser.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Point 14: Better Empty State UX
  Widget _buildEmptyState({required bool isNewMatches}) {
    final String lottieAsset = isNewMatches
        ? 'assets/empty_matches.json' // TODO: Add this Lottie file
        : 'assets/empty_chat.json'; // TODO: Add this Lottie file
    final String title =
        isNewMatches ? "No new matches 💔" : "No messages yet 🤫";
    final String subtitle = isNewMatches
        ? "Start swiping to find your match 💕"
        : "Say hi to one of your new matches!";

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()), // For RefreshIndicator
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a fallback if the specific asset doesn't exist
              Lottie.asset(lottieAsset,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                      Lottie.asset('assets/empty_state.json', height: 180)),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.beVietnamPro(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (isNewMatches)
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_fire_department, size: 20),
                  label: Text("Start Swiping", style: GoogleFonts.beVietnamPro()),
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ChatListItem Widget ---
// Now includes Points 1, 2, 4, 5, 7, 8

class ChatListItem extends StatefulWidget {
  final String name;
  final String message;
  final String imageUrl;
  final Timestamp? timestamp;
  final bool isUnread;
  final bool isDarkMode;
  final VoidCallback onTap;
  final Color accentColor;
  final String otherUid; // Point 1: For unique Hero tag
  final bool isOnline; // Point 5: For online status

  const ChatListItem({
    super.key,
    required this.name,
    required this.message,
    required this.imageUrl,
    required this.timestamp,
    required this.isUnread,
    required this.isDarkMode,
    required this.onTap,
    required this.accentColor,
    required this.otherUid,
    required this.isOnline,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  double _scale = 1.0;

  // Point 8: Cache for decoded base64 image
  Uint8List? _decodedImageBytes;

  @override
  void initState() {
    super.initState();
    _cacheDecodedImage();
  }

  // Point 8: Update cache if image URL changes
  @override
  void didUpdateWidget(covariant ChatListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _cacheDecodedImage();
    }
  }

  // Point 8: Logic to decode and cache the image
  void _cacheDecodedImage() {
    if (widget.imageUrl.isNotEmpty) {
      try {
        setState(() {
          _decodedImageBytes = base64Decode(widget.imageUrl);
        });
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
        setState(() {
          _decodedImageBytes = null;
        });
      }
    } else {
      setState(() {
        _decodedImageBytes = null;
      });
    }
  }

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.97);
  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  // Point 4: Long-press context menu
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text("View Profile",
                          style: GoogleFonts.beVietnamPro()),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to profile page
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.volume_off_outlined),
                      title:
                          Text("Mute", style: GoogleFonts.beVietnamPro()),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement mute logic
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: const Icon(Icons.block, color: Colors.redAccent),
                  title: Text("Unmatch & Block",
                      style: GoogleFonts.beVietnamPro(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    // This can trigger the same logic as the swipe
                    //_unmatchUser(widget.otherUid);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color glassColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.7);
    final Color glassBorder = widget.isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.3);
    final Color textColor =
        widget.isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor =
        widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;

    // Point 8: Use cached image bytes
    ImageProvider? backgroundImage;
    Widget? fallbackChild;

    if (_decodedImageBytes != null) {
      backgroundImage = MemoryImage(_decodedImageBytes!);
    } else if (widget.imageUrl.isNotEmpty) {
      // Show broken image if bytes are null but URL wasn't empty
      fallbackChild = Icon(Icons.broken_image,
          color: widget.accentColor.withOpacity(0.6), size: 30);
    } else {
      // Show person icon if URL was empty
      fallbackChild =
          Icon(Icons.person, color: widget.accentColor.withOpacity(0.8), size: 30);
    }

    // Point 2: Handle timestamp edge case
    final String formattedTime = widget.timestamp != null
        ? timeago.format(widget.timestamp!.toDate(), locale: 'en_short')
        : 'Just now'; // Fallback for new matches

    // Point 7: Responsive padding
    final horizontalPadding = MediaQuery.of(context).size.width * 0.04;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: _showChatOptions, // Point 4: Add long press
      child: Transform.scale(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          // Point 7: Use responsive margin
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.accentColor, Colors.pinkAccent],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Hero(
                            // Point 1 & 11: Use unique Hero tag
                            tag: 'avatar_${widget.otherUid}',
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: backgroundImage, // Point 8
                              backgroundColor: Colors.pink.shade50,
                              child: fallbackChild,
                            ),
                          ),
                        ),
                        // Point 5: Real online status
                        if (widget.isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Point 2: Hide timestamp if no message yet
                              if (widget.timestamp != null)
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    color: widget.isUnread
                                        ? textColor
                                        : subTextColor,
                                    fontWeight: widget.isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (widget.isUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: widget.accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "New",
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}