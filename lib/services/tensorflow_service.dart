import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// Data models
class GarbagePrediction {
  final String predictedClass;
  final double confidence;
  final List<ClassPrediction> allPredictions;
  final Uint8List processedImageBytes;

  GarbagePrediction({
    required this.predictedClass,
    required this.confidence,
    required this.allPredictions,
    required this.processedImageBytes,
  });
}

class ClassPrediction {
  final String className;
  final double confidence;

  ClassPrediction({
    required this.className,
    required this.confidence,
  });
}

class DisposalInfo {
  final String category;
  final String disposalMethod;
  final bool recyclable;
  final String tips;
  final int color;
  final String icon;

  DisposalInfo({
    required this.category,
    required this.disposalMethod,
    required this.recyclable,
    required this.tips,
    required this.color,
    required this.icon,
  });
}

class TensorFlowService {
  static const List<String> _garbageClasses = [
    'battery',
    'biological', 
    'brown-glass',
    'cardboard',
    'clothes',
    'green-glass',
    'metal',
    'paper',
    'plastic',
    'shoes',
    'trash',
    'white-glass'
  ];

  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  // Singleton pattern
  static final TensorFlowService _instance = TensorFlowService._internal();
  factory TensorFlowService() => _instance;
  TensorFlowService._internal();

  /// Initialize the TensorFlow Lite model
  Future<bool> loadModel() async {
    print('🔄 Starting model loading process...');
    
    // List of models to try (in order of preference)
    final List<String> modelPaths = [
      'assets/models/garbage_classifier.tflite',
      'assets/models/garbage_classifier_quantized.tflite',
    ];
    
    for (String modelPath in modelPaths) {
      try {
        print('🔍 Attempting to load: $modelPath');
        
        // Create interpreter with options for better compatibility
        final options = InterpreterOptions();
        options.threads = 1; // Use single thread for stability
        
        _interpreter = await Interpreter.fromAsset(modelPath, options: options);
        
        // Verify model is working by checking tensor info
        final inputTensors = _interpreter.getInputTensors();
        final outputTensors = _interpreter.getOutputTensors();
        
        print('✅ Successfully loaded: $modelPath');
        print('📊 Input tensors: ${inputTensors.length}');
        print('📊 Output tensors: ${outputTensors.length}');
        
        if (inputTensors.isNotEmpty) {
          print('📊 Input shape: ${inputTensors[0].shape}');
          print('📊 Input type: ${inputTensors[0].type}');
        }
        
        if (outputTensors.isNotEmpty) {
          print('📊 Output shape: ${outputTensors[0].shape}');
          print('📊 Output type: ${outputTensors[0].type}');
        }
        
        _isModelLoaded = true;
        return true;
        
      } catch (e) {
        print('❌ Failed to load $modelPath: $e');
        continue; // Try next model
      }
    }
    
    print('❌ All model loading attempts failed');
    _isModelLoaded = false;
    return false;
  }

  /// Preprocess image according to training notebook - model expects [0, 255] range
  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    
    img.Image resized = img.copyResize(decodedImage, width: 224, height: 224);
    
    return List.generate(1, (_) => 
      List.generate(224, (y) => 
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r.toDouble(),   // Model expects [0, 255] range (preprocess_input is no-op)
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        })
      )
    );
  }

  /// Alternative preprocessing using Float32List - [0, 255] range for EfficientNet
  Float32List _preprocessImageFlat(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    
    img.Image resized = img.copyResize(decodedImage, width: 224, height: 224);
    
    // Create flat array [224 * 224 * 3] with [0, 255] range
    Float32List inputData = Float32List(224 * 224 * 3);
    int index = 0;
    
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        inputData[index++] = pixel.r.toDouble();   // [0, 255] range
        inputData[index++] = pixel.g.toDouble();   
        inputData[index++] = pixel.b.toDouble();
      }
    }
    
    return inputData;
  }

  /// Classify garbage from image file - following FLUTTER_INFERENCE.md pattern
  Future<GarbagePrediction> classify(File imageFile) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('🔍 Starting classification for: ${imageFile.path}');
      
      // Try both preprocessing approaches to see which works better
      bool useFlat = true; // Start with Float32List approach
      
      var input;
      if (useFlat) {
        input = _preprocessImageFlat(imageFile);
        print('🔍 Using Float32List input, length: ${input.length}');
        print('🔍 Input data range: ${input.reduce((double a, double b) => a < b ? a : b)} to ${input.reduce((double a, double b) => a > b ? a : b)}');
      } else {
        input = _preprocessImage(imageFile);
        print('🔍 Using nested list input, shape: ${input.length}x${input[0].length}x${input[0][0].length}x${input[0][0][0].length}');
      }
      
      // Prepare output tensor for 12 classes 
      var output = List.generate(1, (_) => List.filled(12, 0.0));
      
      // Run inference
      print('🔍 Running inference...');
      try {
        _interpreter.run(input, output);
      } catch (e) {
        if (useFlat) {
          print('❌ Float32List failed: $e');
          print('🔄 Trying nested list approach...');
          input = _preprocessImage(imageFile);
          _interpreter.run(input, output);
        } else {
          print('❌ Nested list failed: $e');
          print('🔄 Trying Float32List approach...');
          input = _preprocessImageFlat(imageFile);
          _interpreter.run(input, output);
        }
      }
      
      // Get probabilities
      List<double> probabilities = output[0].cast<double>();
      print('🔍 Raw output: $probabilities');
      
      // Check if probabilities need softmax (like FLUTTER_INFERENCE.md approach)
      double sum = probabilities.reduce((a, b) => a + b);
      print('🔍 Probability sum: $sum');
      
      if (sum < 0.99 || sum > 1.01) {
        print('🔍 Applying softmax normalization...');
        probabilities = _applySoftmax(probabilities);
      }
      
      // Find max probability and index (like FLUTTER_INFERENCE.md)
      final maxProbability = probabilities.reduce((a, b) => a > b ? a : b);
      final maxIndex = probabilities.indexOf(maxProbability);
      
      String predictedClass = _garbageClasses[maxIndex];
      
      print('🔍 Prediction: $predictedClass ($maxProbability)');
      
      // Create all predictions
      List<ClassPrediction> allPredictions = [];
      for (int i = 0; i < _garbageClasses.length; i++) {
        allPredictions.add(ClassPrediction(
          className: _garbageClasses[i],
          confidence: probabilities[i],
        ));
      }
      
      // Sort by confidence
      allPredictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Create processed image bytes for display
      final bytes = imageFile.readAsBytesSync();
      img.Image? decodedImage = img.decodeImage(bytes);
      img.Image resizedImage = img.copyResize(decodedImage!, width: 224, height: 224);
      Uint8List processedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage));
      
      return GarbagePrediction(
        predictedClass: predictedClass,
        confidence: maxProbability,
        allPredictions: allPredictions,
        processedImageBytes: processedImageBytes,
      );
      
    } catch (e) {
      print('❌ Classification error: $e');
      rethrow;
    }
  }

  /// Apply softmax to convert logits to probabilities
  List<double> _applySoftmax(List<double> logits) {
    // Find max for numerical stability
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Compute exp(x - max) for each element
    List<double> expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    
    // Compute sum of exp values
    double sumExp = expValues.reduce((a, b) => a + b);
    
    // Normalize to get probabilities
    return expValues.map((x) => x / sumExp).toList();
  }

  /// Get disposal information for a garbage class
  static DisposalInfo getDisposalInfo(String garbageClass) {
    switch (garbageClass.toLowerCase()) {
      case 'battery':
        return DisposalInfo(
          category: 'Hazardous Waste',
          disposalMethod: 'Take to designated battery recycling centers or electronics stores',
          recyclable: true,
          tips: 'Never throw batteries in regular trash as they contain toxic materials',
          color: 0xFFFF5722,
          icon: '🔋',
        );
        
      case 'biological':
        return DisposalInfo(
          category: 'Organic Waste',
          disposalMethod: 'Compost bin or organic waste collection',
          recyclable: true,
          tips: 'Great for composting! Helps create nutrient-rich soil',
          color: 0xFF4CAF50,
          icon: '🍎',
        );
        
      case 'brown-glass':
        return DisposalInfo(
          category: 'Recyclable Glass',
          disposalMethod: 'Glass recycling bin (brown/amber glass section)',
          recyclable: true,
          tips: 'Remove caps and lids. Rinse if possible. Glass can be recycled infinitely!',
          color: 0xFF8D6E63,
          icon: '🍺',
        );
        
      case 'cardboard':
        return DisposalInfo(
          category: 'Recyclable Paper',
          disposalMethod: 'Cardboard recycling bin or paper recycling',
          recyclable: true,
          tips: 'Flatten boxes to save space. Remove tape and staples if possible',
          color: 0xFFFF9800,
          icon: '📦',
        );
        
      case 'clothes':
        return DisposalInfo(
          category: 'Textile Waste',
          disposalMethod: 'Donate, textile recycling, or clothing collection bins',
          recyclable: true,
          tips: 'Good condition: donate. Worn out: textile recycling centers',
          color: 0xFF9C27B0,
          icon: '👕',
        );
        
      case 'green-glass':
        return DisposalInfo(
          category: 'Recyclable Glass',
          disposalMethod: 'Glass recycling bin (green glass section)',
          recyclable: true,
          tips: 'Remove caps and lids. Rinse if possible. Separate by color for best recycling',
          color: 0xFF4CAF50,
          icon: '🍷',
        );
        
      case 'metal':
        return DisposalInfo(
          category: 'Recyclable Metal',
          disposalMethod: 'Metal recycling bin or scrap metal collection',
          recyclable: true,
          tips: 'Aluminum and steel are highly recyclable. Clean if possible',
          color: 0xFF607D8B,
          icon: '🥫',
        );
        
      case 'paper':
        return DisposalInfo(
          category: 'Recyclable Paper',
          disposalMethod: 'Paper recycling bin',
          recyclable: true,
          tips: 'Keep dry and clean. Remove any plastic coatings or spiral bindings',
          color: 0xFF2196F3,
          icon: '📄',
        );
        
      case 'plastic':
        return DisposalInfo(
          category: 'Recyclable Plastic',
          disposalMethod: 'Plastic recycling bin (check recycling number)',
          recyclable: true,
          tips: 'Check the recycling number (1-7). Rinse containers. Remove caps if required',
          color: 0xFF00BCD4,
          icon: '🍼',
        );
        
      case 'shoes':
        return DisposalInfo(
          category: 'Textile/Leather Waste',
          disposalMethod: 'Shoe recycling programs, donation, or specialized collection',
          recyclable: true,
          tips: 'Good condition: donate. Worn out: check for shoe recycling programs',
          color: 0xFF795548,
          icon: '👟',
        );
        
      case 'trash':
        return DisposalInfo(
          category: 'General Waste',
          disposalMethod: 'Regular garbage bin - landfill disposal',
          recyclable: false,
          tips: 'Try to minimize general waste. Consider if it can be repurposed or recycled',
          color: 0xFF424242,
          icon: '🗑️',
        );
        
      case 'white-glass':
        return DisposalInfo(
          category: 'Recyclable Glass',
          disposalMethod: 'Glass recycling bin (clear/white glass section)',
          recyclable: true,
          tips: 'Remove caps and lids. Rinse if possible. Clear glass has the highest recycling value',
          color: 0xFFECEFF1,
          icon: '🍾',
        );
        
      default:
        return DisposalInfo(
          category: 'Unknown',
          disposalMethod: 'Check with local waste management for proper disposal',
          recyclable: false,
          tips: 'When in doubt, contact your local waste management facility',
          color: 0xFF9E9E9E,
          icon: '❓',
        );
    }
  }

  /// Get whether the model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Dispose of the TensorFlow interpreter
  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
    }
  }
}
