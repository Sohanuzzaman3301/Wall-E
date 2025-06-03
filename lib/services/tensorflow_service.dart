import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ObjectDetection {
  final String label;
  final double confidence;
  final double x1, y1, x2, y2;

  ObjectDetection({
    required this.label,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
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

  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Singleton pattern
  static final TensorFlowService _instance = TensorFlowService._internal();
  factory TensorFlowService() => _instance;
  TensorFlowService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = InterpreterOptions()..threads = 1;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/garbage_classifier.tflite',
        options: options,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TensorFlow: $e');
    }
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

  /// EfficientNet preprocessing function that matches training code exactly
  List<List<List<List<double>>>> _preprocessImageForEfficientNet(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to 224x224 as per EfficientNetB0
    img.Image resized = img.copyResize(decodedImage, width: 224, height: 224);
    
    // Create 4D tensor [1, 224, 224, 3] with [0, 255] range
    return List.generate(1, (_) => 
      List.generate(224, (y) => 
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.r.toDouble(),  // [0, 255] range
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        })
      )
    );
  }

  /// Classify garbage from image file - following FLUTTER_INFERENCE.md pattern
  Future<GarbagePrediction> classify(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔍 Starting classification for: ${imageFile.path}');
      
      // Get input tensor
      final inputBuffer = _preprocessImageForEfficientNet(imageFile);
      final input = [inputBuffer];
      
      // Prepare output tensor for 12 classes 
      var output = List.generate(1, (_) => List.filled(12, 0.0));
      
      // Run inference - model output is already probabilities
      print('🔍 Running inference...');
      _interpreter!.run(input, output);
      
      // Get probabilities directly from model output
      List<double> probabilities = output[0].cast<double>();
      print('🔍 Model output probabilities:');
      for (int i = 0; i < _garbageClasses.length; i++) {
        print('${_garbageClasses[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
      }
      
      // Find max probability and index
      final maxProbability = probabilities.reduce((a, b) => a > b ? a : b);
      final maxIndex = probabilities.indexOf(maxProbability);
      String predictedClass = _garbageClasses[maxIndex];
      
      print('🔍 Prediction: $predictedClass (${(maxProbability * 100).toStringAsFixed(2)}%)');
      
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
  bool get isModelLoaded => _isInitialized;

  /// Dispose of the TensorFlow interpreter
  void dispose() {
    if (_isInitialized) {
      _interpreter!.close();
      _isInitialized = false;
    }
  }

  Future<List<ObjectDetection>> detectObjects(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final imageFile = File(imagePath);
      
      // Get input tensor in correct 4D shape [1, 224, 224, 3]
      final input = _preprocessImageForEfficientNet(imageFile);
      
      // Create output tensor for 12 classes with correct shape [1, 12]
      var output = List.generate(1, (_) => List.filled(12, 0.0));

      // Run inference - model output is already probabilities
      _interpreter!.run(input, output);

      // Get probabilities directly from model output
      List<double> probabilities = output[0].cast<double>();
      
      // Debug logging
      print('\n🔍 Model output probabilities:');
      for (int i = 0; i < _garbageClasses.length; i++) {
        print('${_garbageClasses[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
      }
      
      // Find the class with highest probability
      final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      final maxProbability = probabilities[maxIndex];
      final predictedClass = _garbageClasses[maxIndex];
      
      print('\n🔍 Prediction: $predictedClass (${(maxProbability * 100).toStringAsFixed(2)}%)');

      // Return a single detection with the predicted class
      return [
        ObjectDetection(
          label: predictedClass,
          confidence: maxProbability,
          x1: 0.0, // No bounding box for classification
          y1: 0.0,
          x2: 1.0,
          y2: 1.0,
        ),
      ];

    } catch (e) {
      print('Error during object detection: $e');
      throw Exception('Error during object detection: $e');
    }
  }
}

final tensorflowProvider = StateNotifierProvider<TensorFlowNotifier, AsyncValue<TensorFlowService>>((ref) {
  return TensorFlowNotifier();
});

class TensorFlowNotifier extends StateNotifier<AsyncValue<TensorFlowService>> {
  TensorFlowNotifier([TensorFlowService? service]) : super(service != null ? AsyncValue.data(service) : const AsyncValue.loading()) {
    if (service == null) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final service = TensorFlowService();
      await service.initialize();
      state = AsyncValue.data(service);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<ObjectDetection>> detectObjects(String imagePath) async {
    final service = state.value;
    if (service == null) {
      throw Exception('TensorFlow service not initialized');
    }
    return service.detectObjects(imagePath);
  }

  @override
  void dispose() {
    state.value?.dispose();
    super.dispose();
  }
}
