import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _emailError = false;
  bool _passwordMismatch = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonScaleController;

  final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ),
  );
}


  @override
  void dispose() {
    _fadeController.dispose();
    _buttonScaleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _validateAndRegister() async {
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final confirm = _confirmController.text.trim();

  if (name.isEmpty) {
    _showSnackBar("Please enter your full name.");
    return;
  }

  if (!_emailRegex.hasMatch(email)) {
    setState(() => _emailError = true);
    return;
  }

  if (password.length < 8) {
    _showSnackBar("Password must be at least 8 characters long.");
    return;
  }

  if (password != confirm) {
    setState(() => _passwordMismatch = true);
    return;
  }

  setState(() {
    _isLoading = true;
    _passwordMismatch = false;
  });

  final auth = AuthService();
  final error = await auth.registerUser(
    fullName: name,
    email: email,
    password: password,
  );

  if (!mounted) return;
  setState(() => _isLoading = false);

  if (error == null) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => VerifyEmailScreen(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(), // Pass password here
      ),
    ),
  );
}
else {
  _showSnackBar(error);
}

}


  

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF04299);
    final textColor = const Color(0xFF1B0D14);
    final hintColor = const Color(0xFF7A3A5D);
    final inputBgColor = const Color(0xFFF3E7ED);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalSpacing = screenHeight * 0.02;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCF8FA), Color(0xFFFDECF4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 💧 Decorative Blobs
          Positioned(
            top: -60,
            right: -60,
            child: _buildBlob(primaryColor.withOpacity(0.2), 160),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildBlob(Colors.pinkAccent.withOpacity(0.1), 200),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.04),

                      // 🪄 Hero Branding
                      Hero(
                        tag: "appName",
                        child: _AppNameAnimation(primaryColor: primaryColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Find your perfect match on campus 💞",
                        style: GoogleFonts.notoSans(
                          color: hintColor,
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // 🪟 Glassmorphic Form Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 👤 Name Field
                            _labeledField(
                              label: "Full Name",
                              child: _buildTextField(
                                controller: _nameController,
                                hintText: "e.g. John Doe",
                                icon: Icons.person_outline,
                                inputBgColor: inputBgColor,
                                hintColor: hintColor,
                                textColor: textColor,
                                primaryColor: primaryColor,
                              ),
                            ),
                            SizedBox(height: verticalSpacing),

                            // 📧 Email Field
                            _labeledField(
                              label: "College Email",
                              child: _buildTextField(
                                controller: _emailController,
                                hintText: "e.g. john@university.edu",
                                icon: Icons.alternate_email,
                                inputBgColor: inputBgColor,
                                hintColor: hintColor,
                                textColor: textColor,
                                primaryColor: primaryColor,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) =>
                                    setState(() => _emailError = false),
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _emailError ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Invalid email format",
                                  style: GoogleFonts.notoSans(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing),

                            // 🔐 Password
                            _labeledField(
                              label: "Password",
                              child: _buildTextField(
                                controller: _passwordController,
                                hintText: "Enter password",
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                inputBgColor: inputBgColor,
                                hintColor: hintColor,
                                textColor: textColor,
                                primaryColor: primaryColor,
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  child: AnimatedRotation(
                                    turns: _obscurePassword ? 0 : 0.5,
                                    duration:
                                        const Duration(milliseconds: 300),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: hintColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Password Strength Bar
                            LinearProgressIndicator(
                              value: min(
                                _passwordController.text.length / 8,
                                1.0,
                              ),
                              backgroundColor: Colors.grey.shade300,
                              color: primaryColor,
                              minHeight: 3,
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Use at least 8 characters with a number & symbol.",
                                style: GoogleFonts.notoSans(
                                  color: hintColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing),

                            // Confirm Password
                            _labeledField(
                              label: "Confirm Password",
                              child: _buildTextField(
                                controller: _confirmController,
                                hintText: "Re-enter password",
                                icon: Icons.lock_person_outlined,
                                obscureText: _obscureConfirm,
                                inputBgColor: inputBgColor,
                                hintColor: hintColor,
                                textColor: textColor,
                                primaryColor: primaryColor,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: hintColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirm = !_obscureConfirm;
                                    });
                                  },
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _passwordMismatch ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Passwords do not match",
                                  style: GoogleFonts.notoSans(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing * 1.5),

                            // 🌈 Register Button (Gradient + Scale)
                            ScaleTransition(
                              scale: _buttonScaleController,
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 5,
                                  ).copyWith(
                                    backgroundColor: WidgetStateProperty.all(
                                      null,
                                    ),
                                    foregroundColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _buttonScaleController.reverse();
                                    await _buttonScaleController.forward();
                                    _validateAndRegister();
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryColor,
                                          primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Center(
                                        child: Text(
                                          _isLoading
                                              ? "Signing up..."
                                              : "Sign Up",
                                          style: GoogleFonts.beVietnamPro(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacing * 1.5),

                      // Bottom link
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) =>
                            Opacity(opacity: value, child: child),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.notoSans(
                                color: hintColor,
                                fontSize: 13,
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: AnimatedScale(
                                  scale: 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    "Login",
                                    style: GoogleFonts.notoSans(
                                      color: primaryColor,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    final hintColor = const Color(0xFF7A3A5D);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: hintColor.withOpacity(0.9),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 50,
          spreadRadius: 20,
        )
      ]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required Color inputBgColor,
    required Color hintColor,
    required Color textColor,
    required Color primaryColor,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Icon(icon, color: hintColor),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.notoSans(color: hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        style: GoogleFonts.notoSans(color: textColor),
      ),
    );
  }
}

// 🎨 Animated app name letters
class _AppNameAnimation extends StatefulWidget {
  final Color primaryColor;
  const _AppNameAnimation({required this.primaryColor});

  @override
  State<_AppNameAnimation> createState() => _AppNameAnimationState();
}

class _AppNameAnimationState extends State<_AppNameAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final String _text = "Campus Match";

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _text.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _animations = List.generate(
      _text.length,
      (i) => Tween<double>(begin: -50, end: 0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeOutBack),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_text.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Opacity(
                opacity: _controllers[i].value,
                child: Text(
                  _text[i],
                  style: GoogleFonts.beVietnamPro(
                    color: widget.primaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
