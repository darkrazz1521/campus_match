import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/dialogs.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool rememberMe = false;
  bool _isLoading = false;
  bool _emailError = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (!_emailRegex.hasMatch(email)) {
    setState(() => _emailError = true);
    return;
  }

  if (password.isEmpty) return;

  setState(() => _isLoading = true);
  _fadeController.forward(from: 0);

  try {
    // Login attempt
    final result = await AuthService().loginUser(email: email, password: password);

    setState(() => _isLoading = false);

    if (result == null) {
      // ✅ Success
      _showSuccessDialog();
    } else if (result.contains("verify")) {
      // 📩 Email not verified
      Dialogs.showEmailNotVerifiedDialog(
  context,
  _emailController.text.trim(),
  password: _passwordController.text.trim(),
);

    } else {
      // ❌ Invalid credentials
      Dialogs.showErrorDialog(context, result);
    }
  } catch (e) {
    setState(() => _isLoading = false);
    Dialogs.showErrorDialog(context, 'Something went wrong. Please try again.');
  }
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
                Navigator.pushReplacementNamed(context, '/home');
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
                      // 🌟 Hero transition for App Name
                      Hero(
                        tag: "appName",
                        child: _AppNameAnimation(primaryColor: primaryColor),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Welcome Back 👋",
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
                        "Log in to continue",
                        style: GoogleFonts.notoSans(
                          color: hintColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 🧑‍🎓 Email Input
                      Container(
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.05,
                              ), // ✅ fixed
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => setState(() => _emailError = false),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            prefixIcon: Icon(
                              Icons.alternate_email,
                              color: hintColor,
                            ),
                            hintText: "College Email",
                            hintStyle: GoogleFonts.notoSans(color: hintColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          style: GoogleFonts.notoSans(color: textColor),
                        ),
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

                      // 🔐 Password Input
                      Container(
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.05,
                              ), // ✅ fixed
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: hintColor,
                            ),
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
                            hintText: "Password",
                            hintStyle: GoogleFonts.notoSans(color: hintColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          style: GoogleFonts.notoSans(color: textColor),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Remember me + Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) =>
                                    setState(() => rememberMe = value!),
                                activeColor: primaryColor,
                              ),
                              Text(
                                "Remember Me",
                                style: GoogleFonts.notoSans(color: textColor),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.notoSans(
                                color: primaryColor,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Login Button
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
                          onPressed: _validateAndLogin,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              _isLoading ? "Logging in..." : "Login",
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

                      // Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.notoSans(
                              color: hintColor,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
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
                                      ) => const RegisterScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(
                                          0.0,
                                          1.0,
                                        ); // from bottom to top
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
                              "Register",
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
      if (!mounted) return; // ✅ Prevent setState after dispose
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
