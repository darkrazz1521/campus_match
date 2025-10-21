import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'providers/user_provider.dart';
import 'providers/swipe_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Wrap your app in MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, SwipeProvider>(
          create: (_) => SwipeProvider(),
          update: (_, userProvider, swipeProvider) {
            swipeProvider ??= SwipeProvider();
            swipeProvider.update(userProvider);
            return swipeProvider;
          },
        ),
      ],
      child: const CampusMatchApp(),
    ),
  );
}

class CampusMatchApp extends StatelessWidget {
  const CampusMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFF04299),
        scaffoldBackgroundColor: const Color(0xFFFCF8FA),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/verify-email': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return VerifyEmailScreen(
            email: args['email']!,
            password: args['password']!,
          );
        },
      },
    );
  }
}
