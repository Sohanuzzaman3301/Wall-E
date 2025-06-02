import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageBubble extends StatelessWidget {
  final types.Message message;
  final bool isUser;
  final BoxDecoration Function(BuildContext, bool) getMessageDecoration;
  final String text;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.getMessageDecoration,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (message is! types.TextMessage) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.85;

    // Check if the message is from WALL-E (system message)
    final isWallE = !isUser && message.author.id == 'wall_e';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: isUser ? 64 : 16,
        right: isUser ? 16 : 64,
        bottom: 12,
        top: 4,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildWallEAvatar(context),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : isWallE
                        ? theme.colorScheme.surfaceVariant
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser 
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : theme.shadowColor.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isWallE
                  ? MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w500,
                        ),
                        code: TextStyle(
                          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquote: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              width: 4,
                            ),
                          ),
                        ),
                        h1: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                        tableHead: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        tableBody: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tableBorder: TableBorder.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.2,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
            ),
          ),
          if (isUser) _buildUserAvatar(context),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildWallEAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 12, top: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.smart_toy_rounded,
          color: theme.colorScheme.primary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(left: 12, top: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: theme.colorScheme.onSecondaryContainer,
          size: 16,
        ),
      ),
    );
  }
} 