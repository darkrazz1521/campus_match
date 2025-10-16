import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(notif["image"]!),
                      ),
                      const SizedBox(width: 12),
                      // Name & message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif["name"]!,
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              notif["message"]!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 🔹 Bottom Navigation
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: bgColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(Icons.home_filled, "Home", true),
                _navItem(Icons.chat_bubble_outline, "Chat", false),
                _navItem(Icons.people_outline, "Confessions", false),
                _navItem(Icons.person_outline, "Profile", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: isActive ? Colors.black : accentColor.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.black : accentColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
