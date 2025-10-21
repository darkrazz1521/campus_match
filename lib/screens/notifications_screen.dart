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
  final Color bgColor = const Color(0xFFFCF8FA);

  final List<Map<String, String>> notifications = [
    {
      "name": "Sarah",
      "message": "You matched with Sarah!",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuA5cTtO1HqnIrrdzdSfeEVzQCW06jak0SDZhSHBDd-nQWyoZleOOTlqQaZklArZ0CT0kkD7au6S_qWm4vxA_F-DsVp9pd0bCyhlo0ScEz0dx9NrPobyGAagIxi1nXOb-tseRjK5ZvxdL1jcT8iD9f0z6Bs8r4gcMF2FClBbKkwG1LmHtLLTPyTrx41bgUpDAW38xlfHKmVo3P0JcroXu9Py9mkr-c49_AkKrHMyMxeJwUqm6Pj90liY63as9RCoxVS1azStewSUVEo"
    },
    {
      "name": "Alex",
      "message": "You matched with Alex!",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuAjtKsg6-kMyk0sEi7yar_8_hT0PsgwB8usMgDtbs5Y4pYszvs9UIj8ORkwHjBTqcwzYXE6OQwqA9EvX8_IyIgeOC7yHL-shkvPEtyUyjBE9-ZyzeLTB61WtGvqPI-Iy8N6VWGqoMAfEFbY0-xaBKj-Pj8YcutyghFYChy4NlC3fNfL5BIYlo5z2Sg1vL1Bfe7tQS7m-Bwh5hZy8d6-Sr-oo2JozAFrJ0mlQ2_9fVzGV2MCdQW0ZKcavZQr8PyHiLC-cUu9jEiukCQ"
    },
    {
      "name": "Emily",
      "message": "You matched with Emily!",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuDldAF7uTCBSZJPcGvM98hpC3gt6bDR3fz_T5DA_urBgAVMA2VFFRiASIjdKAVMojMeYIoIwH9etkQPUY_coNAeJzYYyVCLwHMhynrXTKmnArCgyxtCAzoKac9QylYd1rXi4oyb2v8YktpdY5k8U8U-0eyYOtH55onUcgdvaCIrXvU7SRjX7_EL1t6tO6YbSaxU60RSkGkMUmajrSTiWi6oRCNYUBz6rtfiP3cUbn8QrYW3Ik-GBe9GSzbDKhVqzbhN_RUsagFyl6s"
    },
    {
      "name": "David",
      "message": "You matched with David!",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuDqCGKUiU4Gz5B6NpPbhozywVG3oWalj0Ca2jeFoeJQn2Od1sOV4yZDGkY0cfhjRSt-ttV-_xeTRcVdHIKYhBv4VQn-D7h5fsptjKIz8Qj__bgnlGGhf1pNGPgniRIoEkPJLWfd3blVzMTBZBqsV-fTvyiHS9ly5SsSBFksYHNqxHsSDCviR8zdEwAA49lq_b4XxJHijNsV2C1hVriNztOjRXOuh6PS_AvA2z_R_sjddd34WvFIxzNlYy0nTKACzYkdsqXSJxH4VcU"
    },
  ];

  int _selectedTab = 0;
  final List<String> tabs = ["Matches", "Messages", "Boosts", "Confessions"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
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
      body: Column(
        children: [
          // 🔹 Tabs (Matches, Messages, etc.)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? accentColor : Colors.transparent,
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

          // 🔹 Notification list
          // -----------------------------------------------------------------
// ✅ REPLACE IT WITH THIS NEW WIDGET
// -----------------------------------------------------------------
// Replace the original Expanded(...) that contained the static list
Expanded(
  child: StreamBuilder<QuerySnapshot>(
    // 1. Query the 'notifications' collection for the current user
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '') // Handle null user briefly
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      // 2. Handle loading state
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      // Handle error state
       if (snapshot.hasError) {
         print("Error loading notifications: ${snapshot.error}");
         return Center(
           child: Text(
             "Error loading notifications.",
             style: GoogleFonts.beVietnamPro(color: Colors.red),
           ),
         );
       }
       // Handle no data state
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Text(
            "No notifications yet. Start swiping!",
            style: GoogleFonts.beVietnamPro(color: Colors.grey[600]),
          ),
        );
      }


      // 3. Get the list of notification documents
      final docs = snapshot.data!.docs;

      // 4. Use ListView.builder with the live data
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 8), // Add some padding
        itemCount: docs.length,
        itemBuilder: (context, index) {
          // Get the data from the Firestore document
          final data = docs[index].data() as Map<String, dynamic>?; // Make data nullable

           // Safely access data with null checks and defaults
           final String fromName = data?['fromName'] as String? ?? 'CampusMatch';
           final String body = data?['body'] as String? ?? 'New notification!';
           final String fromImage = data?['fromImage'] as String? ?? ''; // Default empty image URL
           final String docId = docs[index].id; // Get document ID for potential actions
           final bool isRead = data?['read'] as bool? ?? false; // Check read status


          // Use your existing UI container - AnimatedContainer for item appearance
          return InkWell( // Wrap with InkWell for tap interaction
            onTap: () {
              // Optional: Mark as read when tapped
              if (!isRead) {
                 FirebaseFirestore.instance.collection('notifications').doc(docId).update({'read': true});
              }
              // Optional: Navigate somewhere, e.g., to the chat with this user
              // String? matchId = data?['matchId'] as String?;
              // if (matchId != null) { /* Navigate to chat screen */ }
              print("Tapped notification ID: $docId");
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                // Slightly dim read notifications
                color: isRead ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Softer shadow
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.pink.shade50, // Placeholder bg
                    backgroundImage: (fromImage.isNotEmpty && Uri.tryParse(fromImage)?.hasAbsolutePath == true)
                        ? NetworkImage(fromImage)
                        : null,
                    child: (fromImage.isEmpty || Uri.tryParse(fromImage)?.hasAbsolutePath != true)
                        ? Icon(Icons.favorite, size: 28, color: accentColor.withOpacity(0.8)) // Default icon
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name & message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromName, // Live data
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600, // Bold if unread
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                         const SizedBox(height: 2), // Small gap
                        Text(
                          body, // Live data
                          maxLines: 2, // Allow wrapping
                          overflow: TextOverflow.ellipsis, // Add ellipsis if too long
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: isRead ? Colors.grey[600] : accentColor, // Different color if read
                          ),
                        ),
                      ],
                    ),
                  ),
                   // Optional: Unread indicator
                   if (!isRead) ...[
                       const SizedBox(width: 8),
                       CircleAvatar(radius: 5, backgroundColor: Colors.pinkAccent),
                   ]
                ],
              ),
            ),
          );
        },
      );
    },
  ),
),

          // 🔹 Bottom Navigation
          
        ],
      ),
    );
  }

  
}
