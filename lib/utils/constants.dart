import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Colors ---
const Color kPrimaryColor = Color(0xFFF04299);
const Color kAccentColor = Color(0xFF9A4C73);
const Color kTextColor = Color(0xFF1B0D14);
const Color kHintColor = Color(0xFF7A3A5D);
const Color kInputBgColor = Color(0xFFF3E7ED);
const Color kBackgroundColorLight = Color(0xFFFCF8FA);
const Color kBackgroundColorLighter = Color(0xFFFDECF4);
const Color kWhite = Colors.white;
const Color kBlack = Colors.black;
const Color kGrey = Colors.grey;
const Color kRed = Colors.red;
const Color kRedAccent = Colors.redAccent;
const Color kGreen = Colors.green;
const Color kBlueAccent = Colors.blueAccent;
const Color kAmber = Colors.amber;
const Color kOrange = Colors.orange;

// --- Gradients ---
const Gradient kPinkBlueGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
);

const Gradient kAuthBackgroundGradient = LinearGradient(
  colors: [Color(0xFFFCF8FA), Color(0xFFFDECF4)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const Gradient kSwipeBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFDEE9), Color(0xFFFFC3A0)],
);

const Gradient kLogoutButtonGradient = LinearGradient(
  colors: [Color(0xFFEF5350), Color(0xFFD32F2F)], // Red shades
);

const Gradient kLogoutButtonPressedGradient = LinearGradient(
  colors: [Color(0xFFE57373), Color(0xFFC62828)], // Darker red shades
);

const Gradient kRegisterButtonGradient = LinearGradient(
  colors: [kPrimaryColor, Color(0xFFE33A8A)], // Adjusted opacity
);

// --- Text Styles ---
TextStyle kScreenTitleStyle = GoogleFonts.beVietnamPro(
  color: kTextColor,
  fontSize: 20,
  fontWeight: FontWeight.bold,
);

TextStyle kSectionTitleStyle = GoogleFonts.beVietnamPro(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: kTextColor.withOpacity(0.9),
);

TextStyle kBodyTextStyle = GoogleFonts.notoSans(
  color: kTextColor,
  fontSize: 14,
);

TextStyle kHintTextStyle = GoogleFonts.notoSans(
  color: kHintColor,
  fontSize: 14,
);

TextStyle kButtonTextStyle = GoogleFonts.beVietnamPro(
  color: kWhite,
  fontSize: 15,
  fontWeight: FontWeight.bold,
);

TextStyle kLinkStyle = GoogleFonts.notoSans(
  color: kPrimaryColor,
  fontSize: 14,
  decoration: TextDecoration.underline,
);

TextStyle kFieldLabelStyle = GoogleFonts.notoSans(
  color: kHintColor.withOpacity(0.9),
  fontSize: 13,
);

// --- Padding & Spacing ---
const double kDefaultPadding = 16.0;
const double kHorizontalPadding = 20.0;
const double kVerticalPadding = 12.0;
const double kSmallPadding = 8.0;

// --- Border Radius ---
const double kBorderRadius = 16.0;
const double kSmallBorderRadius = 12.0;

// --- Durations ---
const Duration kShortDuration = Duration(milliseconds: 150);
const Duration kMediumDuration = Duration(milliseconds: 300);
const Duration kLongDuration = Duration(milliseconds: 600);

// --- Regex ---
final RegExp kEmailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

// --- Asset Paths ---
const String kLoginAnimation = 'assets/animations/login_animation.json';
const String kLoveAnimation = 'assets/animations/love.json';
const String kLogoPath = 'assets/logo.png';