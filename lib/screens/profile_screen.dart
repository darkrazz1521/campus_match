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
  final TextEditingController dobController = TextEditingController();
  final TextEditingController branchController = TextEditingController();

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
    final userData = await _profileService.getCurrentUserData();
    if (userData == null) return;

    setState(() {
      nameController.text = userData['fullName'] ?? '';
      collegeController.text = userData['gender'] ?? '';
      majorController.text = userData['collegeYear'] ?? '';
      dobController.text = userData['dob'] ?? '';
      branchController.text = userData['branch'] ?? '';
      bioController.text = userData['bio'] ?? '';

      uploadedPhotos.clear();
      uploadedPhotos.addAll(List<String>.from(userData['photos'] ?? []));
      selectedInterests.clear();
      selectedInterests.addAll(List<String>.from(userData['interests'] ?? []));
    });
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
    dobController.dispose();
    branchController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // 🔹 Pick & Upload Image
  Future<void> _pickAndUploadImage() async {
    final image = await _profileService.pickImage(fromCamera: false);
    if (image == null) return;

    setState(() => _isUploading = true);

    final userId = _profileService.getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ You must be logged in to upload.")),
      );
      return;
    }

    final url = await _profileService.uploadImage(image, userId);
    // replace with real userId

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
    final gender = collegeController.text.trim();
    final collegeYear = majorController.text.trim();
    final dob = dobController.text.trim();
    final bio = bioController.text.trim();
    final branch = branchController.text.trim();

    if (name.isEmpty ||
        gender.isEmpty ||
        collegeYear.isEmpty ||
        dob.isEmpty ||
        branch.isEmpty) {
      _showError(
        "Please fill all fields: Name, Gender, College Year, Branch, and DOB.",
      );
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
        gender: gender,
        collegeYear: collegeYear,
        dob: dob,
        bio: bio,
        photos: uploadedPhotos,
        interests: selectedInterests.toList(),
        branch: branch,
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
              colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1b0d14),
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                            buildAddPhotoCard(
                              context,
                              primaryColor,
                              onTap: _pickAndUploadImage,
                            ),
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
                      // 🔹 Gender Dropdown
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("Gender", style: fieldLabelStyle()),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: collegeController.text.isEmpty
                            ? null
                            : collegeController.text,
                        items: ["Male", "Female", "Other"]
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => collegeController.text = val ?? ''),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Select Gender",
                        ),
                      ),

                      // 🔹 College Year Dropdown (1–5)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("College Year", style: fieldLabelStyle()),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: majorController.text.isEmpty
                            ? null
                            : majorController.text,
                        items: List.generate(5, (i) => "${i + 1}")
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text("Year $y"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => majorController.text = val ?? ''),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Select Year",
                        ),
                      ),

                      // 🔹 Branch Field
                      buildLabeledField(
                        label: "Branch",
                        icon: Icons.school_outlined,
                        controller: branchController,
                        primaryColor: primaryColor,
                      ),

                      // 🔹 Date of Birth
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("Date of Birth", style: fieldLabelStyle()),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1970),
                            lastDate: DateTime(DateTime.now().year - 16),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dobController.text =
                                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: dobController,
                            decoration: InputDecoration(
                              hintText: "Select your birth date",
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: const Icon(Icons.date_range),
                            ),
                          ),
                        ),
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
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
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
                            "Tech",
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
                              content: Text("Quiz feature coming soon!"),
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
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
