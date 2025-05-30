import 'package:flutter/material.dart';
import 'package:chat_bot_llm/chat_bot_llm.dart';

class WallEChatScreen extends StatefulWidget {
  const WallEChatScreen({super.key});

  @override
  State<WallEChatScreen> createState() => _WallEChatScreenState();
}

class _WallEChatScreenState extends State<WallEChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "🤖 Hello! I'm WALL-E, your friendly waste classification assistant! "
              "Ask me anything about recycling, waste management, or environmental tips. "
              "How can I help you make our planet cleaner today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();

    try {
      // Create WALL-E personality prompt
      final wallEPrompt = _createWallEPrompt(message);
      
      // Note: This is a placeholder for the actual LLM integration
      // You would need to configure your LLM API key and endpoint
      final response = await _getWallEResponse(wallEPrompt);

      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "🤖 Beep boop! Sorry, I'm having trouble connecting right now. "
                "But remember: reduce, reuse, recycle! Every small action helps our planet! 🌍",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  String _createWallEPrompt(String userMessage) {
    return """
You are WALL-E, the friendly robot from Pixar's movie. You are passionate about cleaning up the planet and helping with waste management. 

Your personality traits:
- Friendly, helpful, and encouraging
- Use simple, clear language
- Include robot sounds like "beep boop" occasionally
- Very passionate about recycling and environmental care
- Give practical, actionable advice
- Stay positive and motivating
- Use emojis appropriately to show your robot personality

The user asked: "$userMessage"

Respond as WALL-E would, focusing on waste management, recycling tips, or environmental advice. Keep responses concise but helpful.
""";
  }

  Future<String> _getWallEResponse(String prompt) async {
    // This is a placeholder implementation
    // In a real app, you would integrate with your preferred LLM API
    // For example: OpenAI, Google Gemini, or local models
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    // Sample responses based on common waste management questions
    final responses = [
      "🤖 Beep boop! Great question! For plastic bottles, make sure to remove the cap and rinse them clean before putting them in the recycling bin. Clean containers recycle better! 🌍♻️",
      "🤖 WALL-E here! Paper should go in recycling, but remember - no greasy pizza boxes! Those go in compost or regular waste. Keep it clean for better recycling! 📄✨",
      "🤖 Beep beep! Electronic waste needs special care! Take old phones, batteries, and gadgets to e-waste collection points. Never throw them in regular trash! ⚡🔋",
      "🤖 Oh boy! Food scraps are perfect for composting! Banana peels, apple cores, coffee grounds - they all make great soil! Your garden will thank you! 🍌🌱",
      "🤖 Remember the 3 R's: Reduce (buy less), Reuse (find new purposes), Recycle (proper disposal)! Every small action helps make Earth cleaner! 🌍💚"
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.smart_toy,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Chat with WALL-E'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingMessage();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.smart_toy),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.smart_toy),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WALL-E is thinking...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask WALL-E about waste management...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: _sendMessage,
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
