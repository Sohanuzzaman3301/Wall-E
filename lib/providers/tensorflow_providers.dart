import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tensorflow_service.dart';

// State classes
class ModelState {
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const ModelState({
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  ModelState copyWith({
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return ModelState(
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PredictionState {
  final GarbagePrediction? prediction;
  final File? selectedImage;
  final bool isProcessing;
  final String? error;

  const PredictionState({
    this.prediction,
    this.selectedImage,
    this.isProcessing = false,
    this.error,
  });

  PredictionState copyWith({
    GarbagePrediction? prediction,
    File? selectedImage,
    bool? isProcessing,
    String? error,
    bool clearPrediction = false,
    bool clearSelectedImage = false,
    bool clearError = false,
  }) {
    return PredictionState(
      prediction: clearPrediction ? null : (prediction ?? this.prediction),
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// TensorFlow Service Provider (Singleton)
final tensorFlowServiceProvider = Provider<TensorFlowService>((ref) {
  return TensorFlowService();
});

// Model Loading State Provider
final modelStateProvider = StateNotifierProvider<ModelStateNotifier, ModelState>((ref) {
  return ModelStateNotifier(ref.read(tensorFlowServiceProvider));
});

// Prediction State Provider
final predictionStateProvider = StateNotifierProvider<PredictionStateNotifier, PredictionState>((ref) {
  return PredictionStateNotifier(ref.read(tensorFlowServiceProvider));
});

// Image Picker Provider
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

// State Notifiers
class ModelStateNotifier extends StateNotifier<ModelState> {
  final TensorFlowService _tensorFlowService;

  ModelStateNotifier(this._tensorFlowService) : super(const ModelState()) {
    loadModel();
  }

  Future<void> loadModel() async {
    if (state.isLoading || state.isLoaded) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _tensorFlowService.loadModel();
      if (success) {
        state = state.copyWith(isLoaded: true, isLoading: false);
      } else {
        state = state.copyWith(
          isLoaded: false,
          isLoading: false,
          error: 'Failed to load TensorFlow model',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoaded: false,
        isLoading: false,
        error: 'Error loading model: $e',
      );
    }
  }

  void retryLoading() {
    state = const ModelState();
    loadModel();
  }
}

class PredictionStateNotifier extends StateNotifier<PredictionState> {
  final TensorFlowService _tensorFlowService;

  PredictionStateNotifier(this._tensorFlowService) : super(const PredictionState());

  Future<void> predictFromCamera() async {
    if (state.isProcessing) return;

    state = state.copyWith(isProcessing: true, clearError: true, clearPrediction: true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final File imageFile = File(pickedFile.path);
      state = state.copyWith(selectedImage: imageFile);

      // Run prediction
      final prediction = await _tensorFlowService.classify(imageFile);

      state = state.copyWith(
        prediction: prediction,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error: $e',
      );
    }
  }

  Future<void> predictFromGallery() async {
    if (state.isProcessing) return;

    state = state.copyWith(isProcessing: true, clearError: true, clearPrediction: true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final File imageFile = File(pickedFile.path);
      state = state.copyWith(selectedImage: imageFile);

      // Run prediction
      final prediction = await _tensorFlowService.classify(imageFile);

      state = state.copyWith(
        prediction: prediction,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error: $e',
      );
    }
  }
  

  void clearPrediction() {
    state = const PredictionState();
  }
  
  /// Classify from an existing image file (e.g., taken via CameraController).
  Future<void> predictFromFile(File imageFile, {File? displayFile}) async {
    if (state.isProcessing) return;
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearPrediction: true,
      selectedImage: displayFile ?? imageFile,
    );
    try {
      final prediction = await _tensorFlowService.classify(imageFile);
      state = state.copyWith(
        prediction: prediction,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
