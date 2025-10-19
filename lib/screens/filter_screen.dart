import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final Color primaryColor = const Color(0xFFF04299);

  // Filter values
  String? selectedBranch;
  String? selectedYear;
  List<String> selectedInterests = [];
  double maxDistance = 10; // in km

  // Dynamic options
  List<String> branches = [];
  List<String> years = [];
  List<String> interests = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final branchSet = <String>{};
      final yearSet = <String>{};
      final interestSet = <String>{};

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['branch'] != null && data['branch'].toString().isNotEmpty) {
          branchSet.add(data['branch']);
        }
        if (data['collegeYear'] != null &&
            data['collegeYear'].toString().isNotEmpty) {
          yearSet.add(data['collegeYear']);
        }
        if (data['interests'] != null && data['interests'] is List) {
          interestSet.addAll(List<String>.from(data['interests']));
        }
      }

      setState(() {
        branches = branchSet.toList()..sort();
        years = yearSet.toList()..sort();
        interests = interestSet.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading filters: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load filters: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Premium Filters",
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (branches.isEmpty &&
                      years.isEmpty &&
                      interests.isEmpty) ...[
                    const Center(
                        child: Text(
                            "No user data available yet for filters.")),
                    const SizedBox(height: 20),
                  ],

                  _buildSectionTitle("Branch"),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBranch,
                    decoration: _dropdownDecoration(),
                    hint: const Text("Select your branch"),
                    items: branches
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedBranch = v),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle("Year"),
                  DropdownButtonFormField<String>(
                    initialValue: selectedYear,
                    decoration: _dropdownDecoration(),
                    hint: const Text("Select your year"),
                    items: years
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedYear = v),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle("Interests"),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((i) {
                      final isSelected = selectedInterests.contains(i);
                      return ChoiceChip(
                        label: Text(i),
                        selected: isSelected,
                        selectedColor: primaryColor.withOpacity(0.7),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selectedInterests.add(i);
                            } else {
                              selectedInterests.remove(i);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle("Max Distance (km)"),
                  Slider(
                    value: maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: "${maxDistance.toInt()} km",
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    onChanged: (val) => setState(() => maxDistance = val),
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveFilters,
                      child: const Text("Save Filters",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  void _saveFilters() async {
  final filters = {
    'branch': selectedBranch,
    'collegeYear': selectedYear,
    'interests': selectedInterests,
    'maxDistanceKm': maxDistance.toInt(),
  };

  final uid = FirebaseAuth.instance.currentUser!.uid;

  await UserService.instance.saveFilterPreferences(
    uid: uid,
    branch: selectedBranch,
    collegeYear: selectedYear,
    interests: selectedInterests,
    maxDistanceKm: maxDistance.toDouble(),
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Filters saved successfully!")),
  );

  Navigator.pop(context, filters);
}

}
