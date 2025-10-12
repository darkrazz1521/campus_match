import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
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

  final RegExp _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.value = 1.0; // 👈 makes Login text visible initially
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

    if (name.isEmpty) return;

    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = true);
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
    _fadeController.forward(from: 0);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Lottie.asset(
            'assets/animations/login_animation.json',
            repeat: false,
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF04299);
    final textColor = const Color(0xFF1B0D14);
    final hintColor = const Color(0xFF7A3A5D);
    final inputBgColor = const Color(0xFFF3E7ED);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8FA), Color(0xFFFDECF4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: "appName",
                        child: _AppNameAnimation(primaryColor: primaryColor),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Create Account 📝",
                        style: GoogleFonts.beVietnamPro(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sign up to get started",
                        style: GoogleFonts.notoSans(
                          color: hintColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 👤 Name
                      _buildTextField(
                        controller: _nameController,
                        hintText: "Full Name",
                        icon: Icons.person_outline,
                        inputBgColor: inputBgColor,
                        hintColor: hintColor,
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),

                      // 📧 Email
                      _buildTextField(
                        controller: _emailController,
                        hintText: "College Email",
                        icon: Icons.alternate_email,
                        inputBgColor: inputBgColor,
                        hintColor: hintColor,
                        textColor: textColor,
                        primaryColor: primaryColor,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() => _emailError = false),
                      ),
                      if (_emailError)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Invalid email format",
                            style: GoogleFonts.notoSans(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 🔐 Password
                      _buildTextField(
                        controller: _passwordController,
                        hintText: "Password",
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        inputBgColor: inputBgColor,
                        hintColor: hintColor,
                        textColor: textColor,
                        primaryColor: primaryColor,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: hintColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔐 Confirm Password
                      _buildTextField(
                        controller: _confirmController,
                        hintText: "Confirm Password",
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
                      if (_passwordMismatch)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Passwords do not match",
                            style: GoogleFonts.notoSans(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _validateAndRegister,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              _isLoading ? "signing un..." : "Signup",
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.notoSans(
                              color: hintColor,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 600,
                                  ),
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const LoginScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(
                                          -1.0,
                                          0.0,
                                        ); // slide in from left
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;

                                        final tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        final offsetAnimation = animation.drive(
                                          tween,
                                        );

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },

                            child: Text(
                              "Login",
                              style: GoogleFonts.notoSans(
                                color: primaryColor,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
