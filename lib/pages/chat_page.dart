import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:ms_undraw/ms_undraw.dart';
import 'package:wall_e/providers/chat_provider.dart' as chat_provider;
import 'package:wall_e/providers/connectivity_provider.dart';
import 'package:wall_e/providers/theme_provider.dart';
import 'package:wall_e/services/tensorflow_service.dart';
import 'package:wall_e/utils/undraw_illustrations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import 'package:wall_e/widgets/chat/chat_widgets.dart';
import 'package:wall_e/pages/result_page.dart';
import 'package:flutter/services.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with SingleTickerProviderStateMixin {
  final _user = const types.User(id: 'user');
  late final types.User _wallE;
  final _messageIds = <String, String>{};
  late final AnimationController _animationController;
  late final AutoScrollController _scrollController;
  chat_provider.ChatState? _previousChatState;
  bool _mounted = true;
  final _textController = TextEditingController();
  bool _isKeyboardVisible = false;
  final FocusNode _focusNode = FocusNode();
  String? _capturedImagePath;
  ObjectDetection? _currentPrediction;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _wallE = types.User(
      id: 'wall_e',
      firstName: 'WALL-E',
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController = AutoScrollController();
    
    // Listen to keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      _isKeyboardVisible = keyboardHeight > 0;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _animationController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleChatStateChanges() {
    if (!_mounted) return;
    
    final currentState = ref.read(chat_provider.chatProvider);
    if (_previousChatState == null) {
      _previousChatState = currentState;
      return;
    }

    // Scroll to bottom when new messages arrive
    if (currentState.messages.length != _previousChatState!.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    _previousChatState = currentState;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle state changes when dependencies (like theme) change
    _handleChatStateChanges();
  }

  @override
  void didUpdateWidget(ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle state changes when widget updates
    _handleChatStateChanges();
  }

  String _getMessageId(chat_provider.ChatMessage message) {
    final key = '${message.timestamp.millisecondsSinceEpoch}-${message.content}';
    if (!_messageIds.containsKey(key)) {
      _messageIds[key] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _messageIds[key]!;
  }

  Widget _buildWallEAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: UndrawIllustrations.custom(
          illustration: UnDrawIllustration.eco_conscious,
          color: theme.colorScheme.primary,
          height: 20,
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(delay: 200.ms);
  }

  Widget _buildUserAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: theme.colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(delay: 200.ms);
  }

  Widget _buildErrorMessage(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  BoxDecoration _getMessageDecoration(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isUser
            ? [
                theme.colorScheme.primary,  // Solid primary color for user
                theme.colorScheme.primary,
              ]
            : [
                theme.colorScheme.surfaceVariant,
                theme.colorScheme.surfaceVariant.withOpacity(0.8),
              ],
      ),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
        bottomLeft: Radius.circular(isUser ? 24 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 24),
      ),
      border: Border.all(
        color: isUser
            ? theme.colorScheme.primary.withOpacity(0.3)  // Stronger border for user
            : theme.colorScheme.outline.withOpacity(0.2),
        width: isUser ? 1.5 : 1,  // Thicker border for user
      ),
      boxShadow: [
        BoxShadow(
          color: isUser
              ? theme.colorScheme.primary.withOpacity(0.3)  // Stronger shadow for user
              : theme.shadowColor.withOpacity(0.1),
          blurRadius: 12,
          spreadRadius: isUser ? 1 : 0,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _getInputDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surface.withOpacity(0.95),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  InputDecoration _getInputFieldDecoration() {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: 'Type a message...',
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        fontSize: 15,
        fontFamily: 'Inter',  // Consistent font with user messages
        letterSpacing: 0.1,
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    types.Message message, {
    required bool isUser,
  }) {
    if (message is! types.TextMessage) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.75;

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 48 : 8,
        right: isUser ? 8 : 48,
        bottom: 12,
        top: 4,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primaryContainer.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: _getMessageDecoration(context, isUser),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white  // Force white text for user messages
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: isUser ? 15.5 : 15,  // Slightly larger font for user messages
                  height: 1.5,  // Increased line height for better readability
                  letterSpacing: isUser ? 0.2 : 0.1,  // Slightly more letter spacing for user messages
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,  // Medium weight for user, regular for WALL-E
                  fontFamily: isUser ? 'Inter' : 'Roboto',  // Different fonts for user and WALL-E
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondaryContainer,
                    theme.colorScheme.secondaryContainer.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.1, end: 0);
  }

  void _showServiceUnavailableDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,  // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Service Unavailable'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WALL-E is currently busy! *sad robot sounds*',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The service is temporarily overloaded. Please try again in a few moments.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(chat_provider.chatProvider.notifier).dismissServiceUnavailable();
              },
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ).animate()
          .fadeIn(duration: 300.ms)
          .scale(delay: 100.ms);
      },
    );
  }

  void _handleSendPressed(types.PartialText message) {
    final text = message.text.trim();
    if (text.isEmpty) return;

    ref.read(chat_provider.chatProvider.notifier).sendMessage(text);
    _textController.clear();
  }

  Future<void> _handleImageCapture() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
      );

      if (image == null) return;

      // Get predictions from TensorFlow
      final tensorflowService = ref.read(tensorflowProvider).value;
      if (tensorflowService == null) {
        throw Exception('TensorFlow service not initialized');
      }
      final predictions = await tensorflowService.detectObjects(image.path);
      
      if (!mounted) return;

      // Navigate to result page
      context.push('/result', extra: {
        'imagePath': image.path,
        'prediction': predictions.first,
      });

      // Send a message to chat
      final message = _formatPredictions(predictions);
      ref.read(chat_provider.chatProvider.notifier).sendMessage(message);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatPredictions(List<ObjectDetection> predictions) {
    if (predictions.isEmpty) {
      return "Beep boop! I couldn't detect any objects in this image. Try taking a clearer picture so I can teach you how to dispose of it properly! 🤖📸";
    }

    final prediction = predictions.first;
    final confidence = (prediction.confidence * 100).toStringAsFixed(1);
    
    return "Wooooah! I see a ${prediction.label} with ${confidence}% confidence! Let me teach you how to dispose of this properly! Ask me 'How do I dispose of ${prediction.label}?' and I'll show you the right way! 🌍♻️";
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chat_provider.chatProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    _isKeyboardVisible = keyboardHeight > 0;

    // Show service unavailable dialog if needed
    if (chatState.isServiceUnavailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showServiceUnavailableDialog(context);
      });
    }

    // Convert messages and apply current style
    final messages = chatState.messages.map((msg) {
      return types.TextMessage(
        author: msg.isUser ? _user : _wallE,
        id: _getMessageId(msg),
        text: msg.content,
        createdAt: msg.timestamp.millisecondsSinceEpoch,
      );
    }).toList();

    // Sort messages by timestamp (newest at the bottom)
    messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    // Debug print to verify messages
    developer.log('Current messages: ${messages.length}', name: 'ChatPage');
    for (var msg in messages) {
      developer.log('Message: ${msg.text} (${msg.author.id})', name: 'ChatPage');
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Chat with WALL-E',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.camera_alt_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: _handleImageCapture,
            tooltip: 'Take a picture for waste classification',
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              _messageIds.clear();
              ref.read(chat_provider.chatProvider.notifier).clearChat();
              setState(() {
                _capturedImagePath = null;
                _currentPrediction = null;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: theme.colorScheme.onErrorContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You are offline. Some features may be limited.',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.2, end: 0),
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildErrorMessage(context, chatState.error!),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.background,
                    theme.colorScheme.background.withOpacity(0.95),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  if (messages.isEmpty && !_isKeyboardVisible)
                    const ChatEmptyState()
                  else
                    CustomScrollView(
                      controller: _scrollController,
                      reverse: true,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final message = messages[index];
                              if (message is! types.TextMessage) return null;
                              return _buildMessageBubble(
                                context,
                                message,
                                isUser: message.author.id == 'user',
                              );
                            },
                            childCount: messages.length,
                          ),
                        ),
                      ],
                    ),
                  if (chatState.isLoading)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ChatLoadingIndicator(),
                    ),
                ],
              ),
            ),
          ),
          ChatInput(
            onSendMessage: (text) {
              if (text.trim().isNotEmpty) {
                ref.read(chat_provider.chatProvider.notifier).sendMessage(text);
              }
            },
            getInputFieldDecoration: _getInputFieldDecoration,
            focusNode: _focusNode,
          ),
        ],
      ),
    );
  }
} 