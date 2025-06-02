# Flutter Garbage Classification Inference

Quick implementation guide for TensorFlow Lite garbage classification in Flutter.

## Quick Setup
```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.4
  image: ^4.0.17
  image_picker: ^1.0.4

flutter:
  assets:
    - assets/garbage_classifier.tflite  # or garbage_classifier_quantized.tflite
```

## Implementation

```dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class GarbageClassifier {
  late Interpreter _interpreter;
  final _labels = ['cardboard', 'glass', 'metal', 'paper', 'plastic', 'trash'];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('garbage_classifier.tflite');
  }

  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image resized = img.copyResize(img.decodeImage(bytes)!, width: 224, height: 224);
    
    return List.generate(1, (_) => 
      List.generate(224, (y) => 
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            img.getRed(pixel) / 255.0,   // EfficientNet uses [0, 1] range
            img.getGreen(pixel) / 255.0,
            img.getBlue(pixel) / 255.0,
          ];
        })
      )
    );
  }

  Future<Map<String, dynamic>> classify(File imageFile) async {
    final input = _preprocessImage(imageFile);
    final output = List.filled(1 * 6, 0.0).reshape([1, 6]);
    
    _interpreter.run(input, output);
    
    final probabilities = output[0];
    final maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
    
    return {
      'class': _labels[maxIndex],
      'confidence': probabilities[maxIndex],
      'all_scores': Map.fromIterables(_labels, probabilities),
    };
  }

  void dispose() => _interpreter.close();
}
```

## Usage Example
```dart
class _GarbageScreenState extends State<GarbageScreen> {
  final _classifier = GarbageClassifier();
  String _result = '';

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> _classify() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      final result = await _classifier.classify(File(image.path));
      setState(() {
        _result = '${result['class']} (${(result['confidence'] * 100).toStringAsFixed(1)}%)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _classify,
              child: Text('Classify Garbage'),
            ),
            if (_result.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(_result, style: TextStyle(fontSize: 18)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
```

## Optimization Tips

**Model Selection:**
- `garbage_classifier.tflite` - Better accuracy
- `garbage_classifier_quantized.tflite` - Faster, smaller

**Performance:**
```dart
// GPU acceleration + threading
final options = InterpreterOptions()
  ..useGpuDelegateV2 = true
  ..threads = 4;
_interpreter = await Interpreter.fromAsset('model.tflite', options: options);
```

## Classes
- **cardboard, glass, metal, paper, plastic, trash**
- Input: 224x224 RGB, EfficientNet preprocessing ([0, 1] range)
- Output: 6 class probabilities
