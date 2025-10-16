import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final Color accentColor = const Color(0xFF9A4C73);

  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFDEE9),
      Color(0xFFB5FFFC),
    ],
  );

  late AnimationController _screenAnimController;

  @override
  void initState() {
    super.initState();
    _screenAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _screenAnimController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: Colors.grey.withOpacity(0.2), thickness: 1)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Divider(color: Colors.grey.withOpacity(0.2), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    String? badgeText,
  }) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return GestureDetector(
          onTapDown: (_) => setInnerState(() => isPressed = true),
          onTapUp: (_) {
            setInnerState(() => isPressed = false);
            onTap?.call();
          },
          onTapCancel: () => setInnerState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPressed
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.12 : 0.08),
                  blurRadius: isPressed ? 10 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.2),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    shadows: [
                      Shadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _logoutButton() {
    bool isPressed = false;
    return StatefulBuilder(builder: (context, setInner) {
      return GestureDetector(
        onTapDown: (_) => setInner(() => isPressed = true),
        onTapUp: (_) {
          setInner(() => isPressed = false);
          _logout(context);
        },
        onTapCancel: () => setInner(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPressed
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.red.shade300, Colors.red.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(isPressed ? 0.4 : 0.2),
                blurRadius: isPressed ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "Logout",
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _animatedDivider() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 1,
      width: MediaQuery.of(context).size.width * 0.8,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(left: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings & Privacy",
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
          top: false,
          child: FadeTransition(
            opacity: CurvedAnimation(
                parent: _screenAnimController, curve: Curves.easeInOut),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.1), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: _screenAnimController, curve: Curves.easeOut)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("Account"),
                      _buildListItem(
                        icon: Icons.person_outline,
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                      ),
                      _animatedDivider(),
                      _buildListItem(
                        icon: Icons.settings_outlined,
                        title: "Account Settings",
                        subtitle: "Manage email, password, and more",
                      ),
                      _sectionHeader("Privacy"),
                      _buildListItem(
                        icon: Icons.shield_outlined,
                        title: "Privacy Controls",
                        subtitle: "Manage your privacy settings",
                      ),
                      _animatedDivider(),
                      _buildListItem(
                        icon: Icons.people_outline,
                        title: "Blocked Users",
                        subtitle: "View and unblock users",
                        badgeText: "3",
                      ),
                      _sectionHeader("CampusMatch Premium"),
                      _buildListItem(
                        icon: Icons.star_border,
                        title: "Upgrade to Premium",
                        subtitle: "Unlock all premium features",
                      ),
                      _sectionHeader("Support"),
                      _buildListItem(
                        icon: Icons.help_outline,
                        title: "Help Center",
                        subtitle: "Get answers and support",
                      ),
                      _animatedDivider(),
                      _buildListItem(
                        icon: Icons.mail_outline,
                        title: "Contact Us",
                        subtitle: "Reach out to our support team",
                      ),
                      const SizedBox(height: 40),
                      _logoutButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//rewrite your SettingsScreen with optimized animations and lazy loading to eliminate skipped frames while keeping all your gradients and styles.