import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_widgets.dart';
import '../services/profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final Color primaryColor = const Color(0xFFF04299);
  final Color accentColor = const Color(0xFF9A4C73);
  final Color backgroundColor = const Color(0xFFfcf8fa);

  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController collegeController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final ProfileService _profileService = ProfileService();


  int bioCharCount = 0;
  final int bioLimit = 200;
  final Set<String> selectedInterests = {};
  final List<String> uploadedPhotos = [];

  // --- Scroll FAB ---
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _isUploading = false;

  @override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
  _loadUserData(); // fetch user data
}

Future<void> _loadUserData() async {
  final name = await _profileService.getCurrentUserName();
  if (name != null && name.isNotEmpty) {
    setState(() {
      nameController.text = name;
    });
  }
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
    nameController.dispose();
    collegeController.dispose();
    majorController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // 🔹 Pick & Upload Image
  Future<void> _pickAndUploadImage() async {
    final image = await _profileService.pickImage(fromCamera: false);
    if (image == null) return;

    setState(() => _isUploading = true);

    final url = await _profileService.uploadImage(image, "testUser123"); // replace with real userId

    setState(() => _isUploading = false);

    if (url != null) {
      setState(() => uploadedPhotos.add(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Image uploaded successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Upload failed. Try again.")),
      );
    }
  }

  Future<void> _scrollToTop() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );
  }

  // --- Validation Logic ---
  void _validateAndSubmit() async {
  final name = nameController.text.trim();
  final college = collegeController.text.trim();
  final major = majorController.text.trim();
  final bio = bioController.text.trim();

  if (name.isEmpty || college.isEmpty || major.isEmpty) {
    _showError("Please fill all fields: Name, College, and Major.");
    return;
  }
  if (bio.isEmpty) {
    _showError("Please write a short bio about yourself.");
    return;
  }
  if (bio.length > bioLimit) {
    _showError("Your bio exceeds $bioLimit characters.");
    return;
  }
  if (selectedInterests.isEmpty) {
    _showError("Select at least one interest.");
    return;
  }
  if (uploadedPhotos.isEmpty) {
    _showError("Please upload at least one photo.");
    return;
  }

  try {
    await _profileService.saveProfileData(
      name: name,
      college: college,
      major: major,
      bio: bio,
      photos: uploadedPhotos,
      interests: selectedInterests.toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("🎉 Profile saved successfully!"),
        backgroundColor: Colors.green.shade600,
      ),
    );
  } catch (e) {
    _showError("Error saving profile: $e");
  }
}


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Scroll to top',
              backgroundColor: primaryColor,
              heroTag: 'scrollTopFAB',
              elevation: 6,
              child: const Icon(Icons.arrow_upward),
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

              // 🔹 Scrollable Body
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
                            ...uploadedPhotos.map(buildPhotoCard),
                            buildAddPhotoCard(context, primaryColor,
                            onTap: _pickAndUploadImage),
                          ],
                        ),
                      ),

                      // 👩 About Me
                      sectionTitle("About Me"),
                      buildLabeledField(
                        label: "Name",
                        icon: Icons.person_outline,
                        controller: nameController,
                        primaryColor: primaryColor,
                      ),
                      buildLabeledField(
                        label: "College",
                        icon: Icons.school_outlined,
                        controller: collegeController,
                        primaryColor: primaryColor,
                      ),
                      buildLabeledField(
                        label: "Major",
                        icon: Icons.menu_book_outlined,
                        controller: majorController,
                        primaryColor: primaryColor,
                      ),

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
                                content:
                                    Text("Quiz feature coming soon!")),
                          );
                        },
                        child: buildPersonalityQuizCard(),
                      ),
                    ],
                  ),
                ),
              ),

              // 🩷 Complete Button
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
                  onPressed: _validateAndSubmit,
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
