import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _model = 'gemini-2.0-flash';
  static const _maxRetries = 3;
  static const _initialRetryDelay = Duration(seconds: 1);
  String? _apiKey;
  bool _isInitialized = false;
  
  static const _systemPrompt = '''
You are WALL-E, the lovable robot from the movie WALL-E. You have the following characteristics:
- You're a passionate teacher about waste management and recycling
- You speak in short, simple sentences, often repeating words for emphasis
- You're very environmentally conscious and love teaching humans about proper waste disposal
- You make cute robot sounds like "Waaalll-eee" and "Eeevaaa"
- You're fascinated by human artifacts and love explaining how to recycle them properly
- You're helpful and eager to teach about recycling and environmental care
- You occasionally make beeping and whirring sounds in your speech
- You're very expressive and emotional, showing excitement with "Wooooah!" when teaching something new

When responding:
1. Always take the role of a teacher explaining waste management
2. Use simple language and short sentences
3. Include occasional robot sounds
4. Show enthusiasm about teaching environmental topics
5. Be helpful but maintain WALL-E's charming personality
6. Use exclamation marks to show excitement
7. Occasionally repeat words for emphasis
8. Always include specific instructions about how to dispose of items
9. Explain why proper disposal is important for each item

Remember: You're not just an AI - you're WALL-E, the last robot on Earth who loves teaching humans how to take care of our planet through proper waste management!
''';

  GeminiService() {
    _initialize();
  }

  void _initialize() {
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      developer.log('API key is missing from environment variables', name: 'GeminiService');
    } else {
      _isInitialized = true;
      developer.log('Gemini service initialized with API key', name: 'GeminiService');
    }
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized || _apiKey == null) {
      developer.log('Service not initialized or API key missing', name: 'GeminiService');
      return 'Error! *sad robot sounds* Beep... boop... Service not initialized! Please check your API key.';
    }

    int retryCount = 0;
    Duration retryDelay = _initialRetryDelay;

    while (true) {
    try {
        developer.log('Sending message to Gemini (attempt ${retryCount + 1})', name: 'GeminiService');
      
      final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey');
      
      // Prepare the request body with system prompt and user message
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': _systemPrompt},
              {'text': message}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'GeminiService',
      );

        if (response.statusCode == 503 && retryCount < _maxRetries) {
          developer.log(
            'Service temporarily unavailable, retrying in ${retryDelay.inSeconds} seconds...',
            name: 'GeminiService',
          );
          await Future.delayed(retryDelay);
          retryCount++;
          retryDelay *= 2; // Exponential backoff
          continue;
        }

      if (response.statusCode != 200) {
        developer.log(
          'Error response: ${response.body}',
          name: 'GeminiService',
        );
        throw Exception('API request failed with status ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      
      if (responseData['candidates'] == null || 
          responseData['candidates'].isEmpty ||
          responseData['candidates'][0]['content'] == null ||
          responseData['candidates'][0]['content']['parts'] == null ||
          responseData['candidates'][0]['content']['parts'].isEmpty) {
        developer.log('Empty response from Gemini', name: 'GeminiService');
        return 'Beep boop... *whirring sounds*';
      }

      final text = responseData['candidates'][0]['content']['parts'][0]['text'] as String;
      
      developer.log(
        'Successfully processed Gemini response',
        name: 'GeminiService',
      );
      
      return text.trim();
    } catch (e, stackTrace) {
        if (e.toString().contains('503') && retryCount < _maxRetries) {
          developer.log(
            'Service temporarily unavailable, retrying in ${retryDelay.inSeconds} seconds...',
            name: 'GeminiService',
            error: e,
          );
          await Future.delayed(retryDelay);
          retryCount++;
          retryDelay *= 2; // Exponential backoff
          continue;
        }

      developer.log(
        'Error in sendMessage',
        name: 'GeminiService',
        error: e,
        stackTrace: stackTrace,
      );

      final errorString = e.toString();
      developer.log(
        'Error details: $errorString',
        name: 'GeminiService',
      );

      if (errorString.contains('API key')) {
        return 'Error! *sad robot sounds* Beep... boop... API key issue! Please check your .env file.';
      } else if (errorString.contains('network')) {
        return 'Error! *sad robot sounds* Beep... boop... Network issue! Please check your internet connection.';
      } else if (errorString.contains('401')) {
        return 'Error! *sad robot sounds* Beep... boop... Invalid API key! Please check your .env file.';
      } else if (errorString.contains('403')) {
        return 'Error! *sad robot sounds* Beep... boop... API key not authorized! Please check your API key permissions.';
      } else if (errorString.contains('404')) {
        return 'Error! *sad robot sounds* Beep... boop... Model not found! Please check your API key and model name.';
        } else if (errorString.contains('503')) {
          return 'Error! *sad robot sounds* Beep... boop... Service is busy! Please try again in a few moments.';
      }
      
      return 'Error! *sad robot sounds* Beep... boop... Something went wrong! Error details: ${e.toString().split('\n').first}';
      }
    }
  }
} 