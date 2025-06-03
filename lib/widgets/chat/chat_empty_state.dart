import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wall_e/providers/chat_provider.dart' as chat_provider;

class ChatEmptyState extends ConsumerWidget {
  const ChatEmptyState({super.key});

  void _startChat(BuildContext context, WidgetRef ref) {
    // Send a welcome message to start the chat
    ref.read(chat_provider.chatProvider.notifier).sendMessage(
      "Beep boop! I'm WALL-E, and I'm here to teach you about proper waste disposal! 🌍♻️\n\n"
      "I can help you identify different types of waste and show you how to dispose of them correctly. "
      "Just show me an item or ask me about anything you're not sure how to recycle! 🤖✨"
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WALL-E animation
              Container(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/animations/wall_e_wave.json',
                  fit: BoxFit.contain,
                  animate: true,
                  repeat: true,
                ),
              ).animate()
                .fadeIn(duration: 800.ms)
                .scale(delay: 200.ms),
              
              const SizedBox(height: 32),
              
              // Welcome message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello! I\'m WALL-E',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI waste management teacher! I can help you learn how to properly sort and dispose of different types of waste!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action button
                    FilledButton.icon(
                      onPressed: () => _startChat(context, ref),
                      icon: Icon(
                        Icons.chat_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                      label: const Text('Start Chatting'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
} 