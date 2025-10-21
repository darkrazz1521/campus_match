import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'swiping_screen.dart';
import 'chat_screen.dart';
import 'confessions_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    // Call the function as soon as HomeScreen loads
    _saveFcmToken();
  }

  /// Saves the user's FCM token to Firestore
  Future<void> _saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Not logged in

    try {
      // 1. Get the token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // 2. Save it to the user's document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM Token saved: $token');
      }

      // 3. Listen for token refreshes and save again
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        if (mounted) { // Check if the widget is still in the tree
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

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
                    // 👇 Navigate to settings page
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
