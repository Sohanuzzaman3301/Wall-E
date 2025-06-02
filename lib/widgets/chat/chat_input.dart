import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final Function(String) onSendMessage;
  final InputDecoration Function() getInputFieldDecoration;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.getInputFieldDecoration,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: getInputFieldDecoration(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSendMessage(text);
                  textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                onSendMessage(text);
                textController.clear();
              }
            },
            icon: Icon(
              Icons.send_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
} 