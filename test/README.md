# Testing Guide

This package has been refactored to support full testability with dependency injection.

## Overview

All major dependencies can now be mocked for testing:
- `IFaceDetector` - Face detection operations
- `ICameraManager` - Camera management
- `IImageConverter` - Image format conversion

## Backward Compatibility

The package maintains **100% backward compatibility**. Existing code continues to work:

```dart
// Still works - creates default implementations internally
final detector = LivenessDetector(const LivenessConfig());
```

## Testing with Mocks

### Option 1: Use Provided Mock Implementations

```dart
import 'package:facial_liveness_verification/facial_liveness_verification.dart';
import 'package:facial_liveness_verification/test/mocks/mock_implementations.dart';

void main() {
  test('should work with mocked dependencies', () {
    final mockFaceDetector = MockFaceDetector(
      onProcessImage: (image) => [/* mock faces */],
    );
    
    final mockCameraManager = MockCameraManager(
      onInitialize: () async => {},
    );
    
    final mockImageConverter = MockImageConverter(
      onCreateInputImage: (image) async => /* mock InputImage */,
    );

    final detector = LivenessDetector(
      const LivenessConfig(),
      faceDetector: mockFaceDetector,
      cameraManager: mockCameraManager,
      imageConverter: mockImageConverter,
    );

    // Test your detector...
  });
}
```

### Option 2: Use Mockito (Recommended for Complex Tests)

1. Create a test file with `@GenerateMocks`:

```dart
import 'package:mockito/annotations.dart';
import 'package:facial_liveness_verification/src/core/interfaces.dart';

@GenerateMocks([IFaceDetector, ICameraManager, IImageConverter])
void main() {
  // Run: flutter pub run build_runner build
}
```

2. Use the generated mocks:

```dart
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart'; // Generated file

void main() {
  test('should initialize successfully', () async {
    final mockFaceDetector = MockIFaceDetector();
    final mockCameraManager = MockICameraManager();
    final mockImageConverter = MockIImageConverter();

    when(mockCameraManager.testMLKitSetup())
        .thenAnswer((_) async => {});
    when(mockCameraManager.initialize())
        .thenAnswer((_) async => {});

    final detector = LivenessDetector(
      const LivenessConfig(),
      faceDetector: mockFaceDetector,
      cameraManager: mockCameraManager,
      imageConverter: mockImageConverter,
    );

    await detector.initialize();

    verify(mockCameraManager.testMLKitSetup()).called(1);
    verify(mockCameraManager.initialize()).called(1);
  });
}
```

## What Can Be Tested

### ✅ Fully Testable (with mocks)
- `LivenessDetector` - All methods can be tested with mocked dependencies
- `ChallengeValidator` - Pure logic, just needs mock `Face` objects
- `SpoofingDetector` - Pure logic, just needs mock `Face` and `CameraImage` objects
- `ImageConverter` - Can be mocked or tested directly
- All model classes - Pure data classes

### ⚠️ Requires Mock Objects
- `Face` objects from ML Kit - Use Mockito or create test doubles
- `CameraImage` objects - Use Mockito or create test doubles
- `InputImage` objects - Use Mockito or create test doubles

## Example Test Structure

See:
- `test/mocks/mock_implementations.dart` - Simple mock implementations
- `test/examples/liveness_detector_mockito_test_example.dart` - Mockito example
- `test/detector/liveness_detector_test.dart` - Updated test file

## Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate mocks (if using Mockito)
flutter pub run build_runner build
```

