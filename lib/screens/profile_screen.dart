import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFDEE9), // soft pink
                Color(0xFFB5FFFC), // light aqua
              ],
            ),
          ),
          child: Column(
            children: [
              // 🔹 Header
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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


              // 🔹 Scrollable body
              Expanded(
                child: SingleChildScrollView(
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
                            buildAddPhotoCard(),
                          ],
                        ),
                      ),

                      // 👩 About Me
                      sectionTitle("About Me"),
                      buildLabeledField("Name", Icons.person_outline),
                      buildLabeledField("College", Icons.school_outlined),
                      buildLabeledField("Major", Icons.menu_book_outlined),

                      // ✍️ Bio
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          "Short Bio",
                          style: fieldLabelStyle(),
                        ),
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
                            borderSide: BorderSide(color: primaryColor, width: 2),
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
                        child: Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Take the Quiz",
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Discover your personality type and find better matches.",
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  // ---------- UI HELPERS ----------

  Widget sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1b0d14),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFF04299),
            decorationThickness: 2,
          ),
        ),
      );

  TextStyle fieldLabelStyle() => GoogleFonts.beVietnamPro(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      );

  Widget buildLabeledField(String label, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: fieldLabelStyle()),
            const SizedBox(height: 4),
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color(0xFF9A4C73)),
                hintText: "Enter $label",
                filled: true,
                fillColor: Colors.white.withOpacity(0.7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      );

  Widget buildPhotoCard(String url) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                )
              ],
            ),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
      );

  Widget buildAddPhotoCard() => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Add photo feature coming soon")),
            );
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo, color: Colors.pinkAccent, size: 36),
            ),
          ),
        ),
      );
}
