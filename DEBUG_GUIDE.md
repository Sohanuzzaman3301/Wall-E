# WALL-E Garbage Classifier - Debugging Guide

## If Predictions Are Still Inaccurate

### 1. Check Debug Output
Look for these patterns in the console:

**Good Signs:**
```
✅ Successfully loaded: assets/models/garbage_classifier.tflite
📊 Input data range: 0.0 to 1.0
📊 Probabilities sum: 1.0 (or close to it)
🎯 Predicted class: [reasonable prediction]
```

**Warning Signs:**
```
❌ Failed to load model
📊 Input data range: -2.0 to 3.0 (wrong normalization)
📊 Probabilities sum: 45.7 (needs softmax)
🎯 Predicted class: always the same class
```

### 2. Alternative Fixes to Try

#### A. Try Different Normalization
In `tensorflow_service.dart`, line ~140, replace the normalization:

```dart
// Current: [0,1] normalization
double r = pixel.r / 255.0;

// Try: [0,255] range (no normalization)
double r = pixel.r.toDouble();

// Or try: [-1,1] normalization  
double r = (pixel.r / 127.5) - 1.0;
```

#### B. Try Different Channel Order
Sometimes models expect BGR instead of RGB:

```dart
// Current: RGB order
inputData[index++] = r;
inputData[index++] = g; 
inputData[index++] = b;

// Try: BGR order
inputData[index++] = b;
inputData[index++] = g;
inputData[index++] = r;
```

#### C. Force Softmax Always
If the model always outputs logits, force softmax:

```dart
// Replace the conditional softmax with:
probabilities = _applySoftmax(probabilities);
```

### 3. Model Issues

If none of the above work, the issue might be:

1. **Wrong Model File**: The .tflite file might not match the training
2. **Quantization Issues**: Try using the non-quantized model only
3. **Class Order Mismatch**: The model might expect different class ordering

### 4. Test with Known Images

Try testing with very obvious garbage items:
- Clear plastic bottle → should predict "plastic"
- Newspaper → should predict "paper" 
- Aluminum can → should predict "metal"
- Food scraps → should predict "biological"

### 5. Model Replacement

If all else fails, you might need to retrain the model with verified preprocessing that matches the inference pipeline.

## Debug Checklist

- [ ] Model loads successfully
- [ ] Input data is in correct range
- [ ] Output probabilities sum to ~1.0
- [ ] Top predictions make logical sense
- [ ] Different images produce different predictions
- [ ] Confidence scores are reasonable (>0.1 for top prediction)
