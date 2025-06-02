import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that checks initial connectivity state
final initialConnectivityProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Connectivity().checkConnectivity();
    debugPrint('Initial connectivity check: $result (${result.name})');
    // Check if we have any type of connection
    final isConnected = result != ConnectivityResult.none && 
                       result != ConnectivityResult.bluetooth;
    debugPrint('Is connected: $isConnected');
    return isConnected;
  } catch (e) {
    debugPrint('Initial connectivity check failed: $e');
    return true; // Assume online on error to allow app to function
  }
});

/// Provider that manages network connectivity state
final connectivityProvider = StreamProvider<bool>((ref) {
  // Start with the initial connectivity state
  ref.watch(initialConnectivityProvider);
  
  return Connectivity()
      .onConnectivityChanged
      .map((ConnectivityResult result) {
        debugPrint('Raw connectivity result: $result (${result.name})');
        // Check if we have any type of connection
        final isOnline = result != ConnectivityResult.none && 
                        result != ConnectivityResult.bluetooth;
        debugPrint('Mapped to online state: $isOnline');
        return isOnline;
      });
});

/// Provider that gives the current connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  final state = ref.watch(connectivityProvider);
  debugPrint('Current connectivity state: $state');
  
  return state.when(
    data: (isOnline) {
      debugPrint('Using stream data, isOnline: $isOnline');
      return isOnline;
    },
    loading: () {
      debugPrint('Stream is loading, checking initial state');
      return ref.watch(initialConnectivityProvider).when(
        data: (isOnline) {
          debugPrint('Using initial state, isOnline: $isOnline');
          return isOnline;
        },
        loading: () {
          debugPrint('Both stream and initial state are loading, assuming online');
          return true;
        },
        error: (error, stack) {
          debugPrint('Initial state error: $error, assuming online');
          return true;
        },
      );
    },
    error: (error, stack) {
      debugPrint('Stream error: $error, assuming online');
      return true;
    },
  );
}); 