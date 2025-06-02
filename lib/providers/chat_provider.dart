import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';
import 'dart:developer' as developer;

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isServiceUnavailable;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isServiceUnavailable = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isServiceUnavailable,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isServiceUnavailable: isServiceUnavailable ?? this.isServiceUnavailable,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(const ChatState());

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    developer.log('Adding user message to chat', name: 'ChatProvider');
    // Add user message
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          content: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: true,
      error: null,
      isServiceUnavailable: false,
    );

    developer.log('Current message count: ${state.messages.length}', name: 'ChatProvider');

    try {
      final geminiService = _ref.read(geminiServiceProvider);
      developer.log('Sending message to Gemini service', name: 'ChatProvider');
      final response = await geminiService.sendMessage(message);

      developer.log('Received response from Gemini, adding to chat', name: 'ChatProvider');
      // Add AI response
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
      developer.log('Updated message count: ${state.messages.length}', name: 'ChatProvider');
    } catch (e) {
      developer.log('Error in sendMessage: $e', name: 'ChatProvider');
      final errorString = e.toString();
      final isServiceUnavailable = errorString.contains('503');
      
      state = state.copyWith(
        isLoading: false,
        error: errorString,
        isServiceUnavailable: isServiceUnavailable,
      );
    }
  }

  void clearChat() {
    state = const ChatState();
  }

  void dismissServiceUnavailable() {
    state = state.copyWith(
      isServiceUnavailable: false,
      error: null,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
}); 