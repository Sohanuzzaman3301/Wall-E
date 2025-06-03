import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wall_e/providers/tensorflow_providers.dart';
import 'package:wall_e/services/tensorflow_service.dart';

class ChatInput extends ConsumerStatefulWidget {
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
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _handleImageCapture() async {
    try {
      setState(() => _isProcessing = true);
      
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Get predictions from TensorFlow
      final predictions = await ref.read(tensorflowProvider.notifier).detectObjects(image.path);
      
      if (!mounted) return;

      // Format predictions into a readable message
      final message = _formatPredictions(predictions);
      widget.onSendMessage(message);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatPredictions(List<ObjectDetection> predictions) {
    if (predictions.isEmpty) {
      return "I couldn't detect any objects in this image. Try taking a clearer picture!";
    }

    // Sort predictions by confidence
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Take top 3 predictions
    final topPredictions = predictions.take(3).toList();
    
    final buffer = StringBuffer("I detected the following objects:\n\n");
    
    for (var prediction in topPredictions) {
      final confidence = (prediction.confidence * 100).toStringAsFixed(1);
      buffer.writeln("• ${prediction.label} (${confidence}% confident)");
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _isProcessing ? null : _handleImageCapture,
              icon: _isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_rounded,
                      color: theme.colorScheme.primary,
                    ),
              tooltip: 'Take a picture for object detection',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: widget.focusNode,
                decoration: widget.getInputFieldDecoration(),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    widget.onSendMessage(text);
                    _textController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  widget.onSendMessage(text);
                  _textController.clear();
                }
              },
              icon: Icon(
                Icons.send_rounded,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Send message',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
} 