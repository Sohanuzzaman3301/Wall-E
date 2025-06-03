import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/camera_page.dart';
import '../pages/chat_page.dart';
import '../pages/settings_page.dart';
import '../pages/result_page.dart';
import '../pages/about_page.dart';
import '../widgets/onboarding/onboarding_screen.dart';
import '../providers/theme_provider.dart';
import '../services/tensorflow_service.dart';

// Root navigator key for the app
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider for the app's router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final themeState = ref.watch(themeProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/chat',
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) {
          // Check if it's the first launch
          return FutureBuilder<bool>(
            future: _isFirstLaunch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // If it's the first launch, show onboarding
              if (snapshot.data == true) {
                return const OnboardingScreen();
              }
              
              // Otherwise, go to chat
              return const ChatPage();
            },
          );
        },
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraPage(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResultPage(
            imagePath: extra['imagePath'] as String,
            prediction: extra['prediction'] as ObjectDetection?,
          );
        },
      ),
    ],
  );
});

Future<bool> _isFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  
  if (!hasSeenOnboarding) {
    // Mark onboarding as seen
    await prefs.setBool('has_seen_onboarding', true);
    return true;
  }
  
  return false;
}
