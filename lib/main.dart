// File: lib/main.dart (UPDATED)
import 'package:daybyday/navigation/main_navigation.dart';
import 'package:daybyday/onboarding/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayByDay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

// Auth Wrapper to check login status and onboarding
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF61FF8F),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final hasSeenOnboarding = onboardingSnapshot.data ?? false;

        // If user hasn't seen onboarding, show it
        if (!hasSeenOnboarding) {
          return const OnboardingFlow();
        }

        // Otherwise, check auth state
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF61FF8F),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              );
            }

            // If user is logged in, go to main navigation
            if (snapshot.hasData) {
              return const MainNavigation();
            }

            // If user is not logged in, show onboarding
            return const OnboardingFlow();
          },
        );
      },
    );
  }
}