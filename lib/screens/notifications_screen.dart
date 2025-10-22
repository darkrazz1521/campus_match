// /screens/notifications_screen.dart

import 'dart:convert'; // 👈 For Base64 decoding
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color accentColor = const Color(0xFF9A4C73);
  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
  );

  int _selectedTab = 0;
  final List<String> tabs = ["Matches", "Messages", "Boosts", "Confessions"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Tabs (Matches, Messages, Boosts, Confessions)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.pink.shade100, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(tabs.length, (index) {
                    final isSelected = _selectedTab == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  isSelected ? accentColor : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.beVietnamPro(
                            color: isSelected ? Colors.black : accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 🔹 Firestore notifications list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('toUid',
                          isEqualTo:
                              FirebaseAuth.instance.currentUser?.uid ?? '')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(color: accentColor));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading notifications.",
                          style:
                              GoogleFonts.beVietnamPro(color: Colors.redAccent),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No notifications yet. Start swiping!",
                          style: GoogleFonts.beVietnamPro(
                              color: Colors.grey[700], fontSize: 15),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>? ?? {};
                        final String fromUid = data['fromUid'] ?? '';
                        final String fromName =
                            data['fromName'] ?? 'CampusMatch';
                        final String body =
                            data['body'] ?? 'New notification!';
                        final String fromImageBase64 =
                            data['fromImage'] ?? ''; // Base64 image
                        final bool isRead = data['read'] ?? false;
                        final String docId = docs[index].id;

                        // 🔸 Decode Base64 safely
                        ImageProvider<Object>? backgroundImage;
                        Widget? fallbackChild;

                        if (fromImageBase64.isNotEmpty) {
                          try {
                            final imageBytes = base64Decode(fromImageBase64);
                            backgroundImage = MemoryImage(imageBytes);
                          } catch (e) {
                            debugPrint(
                                "❌ Error decoding Base64 image for notification: $e");
                            backgroundImage = null;
                            fallbackChild = Icon(Icons.broken_image,
                                size: 28,
                                color: accentColor.withOpacity(0.6));
                          }
                        } else {
                          fallbackChild = Icon(Icons.favorite,
                              size: 28, color: accentColor.withOpacity(0.8));
                        }

                        return InkWell(
                          onTap: () {
                            if (!isRead) {
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(docId)
                                  .update({'read': true});
                            }
                            debugPrint("📩 Tapped notification: $docId");
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.pink.shade50,
                                  backgroundImage: backgroundImage,
                                  child: fallbackChild,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fromName,
                                        style: GoogleFonts.beVietnamPro(
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          color: isRead
                                              ? Colors.grey[700]
                                              : accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: CircleAvatar(
                                      radius: 5,
                                      backgroundColor: Colors.pinkAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
