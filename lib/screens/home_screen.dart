import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'swiping_screen.dart';
import 'chat_screen.dart';
import 'confessions_screen.dart';
import 'profile_screen.dart'; // This is ProfileSetupScreen
import 'settings_screen.dart';
import 'notifications_screen.dart';
// REMOVE these imports, they are in the provider
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);

  @override
  void initState() {
    super.initState();
    // The UserProvider is already handling auth state and token saving
    // We don't need to do anything here.
  }

  // REMOVE THE ENTIRE _saveFcmToken() METHOD
  // Future<void> _saveFcmToken() async { ... }

  final List<Widget> _pages = const [
    SwipingScreen(),
    ChatScreen(),
    ConfessionsScreen(),
    ProfileSetupScreen(),
  ];

  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "CampusMatch",
                style: GoogleFonts.beVietnamPro(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications, color: Colors.black87),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.black87),
                ),
              ],
            )
          : null,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          // Use IndexedStack to keep the state of each page
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.white.withOpacity(0.8),
        selectedItemColor: primaryColor,
        unselectedItemColor: accentColor.withOpacity(0.7),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: "Confessions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}