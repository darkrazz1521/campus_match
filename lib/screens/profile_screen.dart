import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);
  final Color backgroundColor = const Color(0xFFfcf8fa);

  final TextEditingController bioController = TextEditingController();
  int bioCharCount = 0;
  final int bioLimit = 200;
  final Set<String> selectedInterests = {};

  // --- Step 1 additions ---
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _scrollToTop() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );
  }
  // --- end Step 1 additions ---

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Scroll to top',
              child: const Icon(Icons.arrow_upward),
              backgroundColor: primaryColor,
              heroTag: 'scrollTopFAB',
              elevation: 6,
            )
          : null,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFDEE9),
                Color(0xFFB5FFFC),
              ],
            ),
          ),
          child: Column(
            children: [
              // 🔹 Header
              Container(
                padding: EdgeInsets.only(
                  top: topInset > 0 ? (topInset * 0.2) : 8,
                  left: 8,
                  right: 8,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF1b0d14)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Profile Setup",
                          style: GoogleFonts.beVietnamPro(
                            color: const Color(0xFF1b0d14),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // 🔹 Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼 Upload Photos
                      sectionTitle("Upload Photos"),
                      SizedBox(
                        height: 160,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...[
                              "https://picsum.photos/300?1",
                              "https://picsum.photos/300?2",
                              "https://picsum.photos/300?3"
                            ].map(buildPhotoCard),
                            buildAddPhotoCard(context, primaryColor),
                          ],
                        ),
                      ),

                      // 👩 About Me
                      sectionTitle("About Me"),
                      buildLabeledField("Name", Icons.person_outline, primaryColor),
                      buildLabeledField("College", Icons.school_outlined, primaryColor),
                      buildLabeledField("Major", Icons.menu_book_outlined, primaryColor),

                      // ✍️ Bio
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("Short Bio", style: fieldLabelStyle()),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: bioController,
                        maxLength: bioLimit,
                        maxLines: 5,
                        onChanged: (v) =>
                            setState(() => bioCharCount = v.length),
                        decoration: InputDecoration(
                          hintText: "Tell something about yourself...",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          counterText: "$bioCharCount/$bioLimit",
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),

                      // 💕 Interests
                      sectionTitle("Interests"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in [
                            "Hiking",
                            "Reading",
                            "Coding",
                            "Photography",
                            "Gaming",
                            "Music",
                            "Movies",
                            "Tech"
                          ])
                            ChoiceChip(
                              label: Text(interest),
                              selected: selectedInterests.contains(interest),
                              labelStyle: TextStyle(
                                color: selectedInterests.contains(interest)
                                    ? Colors.white
                                    : accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                              selectedColor: primaryColor,
                              backgroundColor: Colors.white.withOpacity(0.6),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedInterests.add(interest);
                                  } else {
                                    selectedInterests.remove(interest);
                                  }
                                });
                              },
                            ),
                        ],
                      ),

                      // 🧠 Personality Quiz
                      sectionTitle("Personality Quiz"),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Quiz feature coming soon!")),
                          );
                        },
                        child: buildPersonalityQuizCard(),
                      ),
                    ],
                  ),
                ),
              ),

              // 🩷 Sticky Complete Button
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(
                    "Complete Profile",
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
