import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'connectivity_provider.dart';

/// Global navigator key for the app
final navigatorKey = GlobalKey<NavigatorState>();

/// Provider that handles navigation based on connectivity
final navigationProvider = Provider<NavigationNotifier>((ref) {
  return NavigationNotifier(ref);
});

/// Provider to track the current route
final currentRouteProvider = StateProvider<String>((ref) => '/');

class NavigationNotifier {
  final Ref _ref;
  NavigationNotifier(this._ref) {
    // Listen to connectivity changes
    _ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (!isOnline) {
        final currentRoute = _ref.read(currentRouteProvider);
        // Only navigate if we're on the chat page
        if (currentRoute == '/chat') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            context.go('/camera');
          }
        }
      }
    });
  }
} 