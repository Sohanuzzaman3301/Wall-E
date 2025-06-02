import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ms_undraw/ms_undraw.dart';
import 'package:wall_e/utils/undraw_illustrations.dart';

class CameraPage extends ConsumerWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('WALL-E Camera'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Offline mode illustration
              UndrawIllustrations.custom(
                illustration: UnDrawIllustration.warning,
                color: theme.colorScheme.primary,
                height: 200,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Offline Mode',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'WALL-E is currently in offline mode. The camera feature will be available soon.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              // Welcome illustration for first-time users
              UndrawIllustrations.custom(
                illustration: UnDrawIllustration.welcome,
                color: theme.colorScheme.secondary,
                height: 150,
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re working hard to bring you the best waste sorting experience.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 