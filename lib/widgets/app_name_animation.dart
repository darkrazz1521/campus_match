import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Renamed from _AppNameAnimation to AppNameAnimation (public)
class AppNameAnimation extends StatefulWidget {
  final Color primaryColor;
  const AppNameAnimation({required this.primaryColor, super.key}); // Added super.key

  @override
  State<AppNameAnimation> createState() => _AppNameAnimationState();
}

// State class remains private
class _AppNameAnimationState extends State<AppNameAnimation>
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