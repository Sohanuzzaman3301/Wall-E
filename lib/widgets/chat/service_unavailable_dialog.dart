import 'package:flutter/material.dart';

class ServiceUnavailableDialog extends StatelessWidget {
  final VoidCallback onTryAgain;

  const ServiceUnavailableDialog({
    super.key,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Service Unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: Text(
        'WALL-E is currently busy helping other users. Please try again in a moment.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onTryAgain();
          },
          child: Text(
            'Try Again',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
} 