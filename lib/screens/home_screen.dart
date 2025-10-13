import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final Color primaryColor = const Color(0xFFF04299);
  final Color bgColor = const Color(0xFFFCF8FA);
  final Color textColor = const Color(0xFF1B0D14);
  final Color accentColor = const Color(0xFF9A4C73);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "CampusMatch",
          style: GoogleFonts.beVietnamPro(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.black87),
          )
        ],
      ),

      // -------- MAIN CONTENT ----------
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Profile Card ---
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        "https://lh3.googleusercontent.com/aida-public/AB6AXuB5bmoZVGZTgzmzMLDHj9Hl-XkxvfD6-7QFEuDuu4KPfV-shBVpIer3Nx5pcOK1ek4qFZV7vartI4b3N3YUmjVFMou7pij2pYTQDLgWPJGmxo62LJrUMyT19eiYlPpdKFv2Nds0WdoJVvCkEar63qrFRWOnVkkqE7DaBLZaBsdmKtt-tL9QCwFo_zhHN4BbfQ00RiRI-klc8NpYa4IqNRFo49qAaBqP72t1JYVvKKhnzoSFH2wDRPyWvNkXLhyPFD3GdY5S4WMfyVo",
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sophia",
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Likes: Hiking, Photography, Music",
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      "Senior",
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Match Percentage ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Match Percentage",
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: const Color(0xFFE7CFDB),
                        color: primaryColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Like / Dislike Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3E7ED),
                              foregroundColor: textColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: const Text("Dislike"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: bgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: const Text("Like"),
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

      // -------- BOTTOM NAVIGATION ----------
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: bgColor,
        selectedItemColor: textColor,
        unselectedItemColor: accentColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Confessions"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
