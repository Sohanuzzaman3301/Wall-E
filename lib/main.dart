import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wall_e/providers/theme_provider.dart';
import 'package:wall_e/router/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
      ],
      child: const WallEApp(),
    ),
  );
}

class WallEApp extends ConsumerWidget {
  const WallEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final baseTheme = ref.watch(baseThemeDataProvider);
    final router = ref.watch(routerProvider);
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors if available
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Fallback to base theme colors
          lightScheme = baseTheme.colorScheme;
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          title: 'WALL-E',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            brightness: Brightness.dark,
          ),
          themeMode: themeState.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
