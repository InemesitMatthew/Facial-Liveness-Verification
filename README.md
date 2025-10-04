# Facial Liveness Verification

A comprehensive Flutter package for real-time facial liveness verification using advanced anti-spoofing techniques, challenge-based verification, and customizable UI components.

## Features

- **Real-time face detection** using Google ML Kit
- **Advanced anti-spoofing protection** with motion analysis
- **Interactive challenge system** (smile, blink, head turns)
- **Customizable UI and theming** for brand consistency  
- **Comprehensive error handling** with recovery options
- **Performance optimized** for various device capabilities
- **Easy integration** with callback-based API

## Quick Start

### 🚀 Ultra-Simple Integration (One-liner!)

```dart
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

// Just one function call - that's it!
await showLivenessCheck(
  context: context,
  onSuccess: (result) => print('User verified!'),
  onFailure: (error) => print('Verification failed'),
);
```

### 🎯 Simple Widget Integration

```dart
SimpleLivenessWidget(
  onSuccess: (result) => print('Verified!'),
  onFailure: (error) => print('Failed!'),
)
```

### ⚙️ Advanced Configuration

```dart
LivenessDetectionWidget(
  config: LivenessConfig.secure(),
  onLivenessDetected: (result) {
    print('Verification successful: ${result.confidenceScore}');
  },
  onError: (error) {
    print('Verification failed: ${error.message}');
  },
)
```

## Built-in Configurations

- `LivenessConfig.minimal()` - Just smile! Perfect for quick onboarding
- `LivenessConfig.passive()` - No user interaction needed, just look at camera
- `LivenessConfig.basic()` - Quick verification with 2 challenges
- `LivenessConfig.secure()` - Maximum security with all challenges
- `LivenessConfig.performance()` - Optimized for low-end devices

## Example App

Run the example app to see the package in action:

```bash
cd example_app
flutter run
```

## Configuration

The package supports three built-in configurations:

- `LivenessConfig()` - Default settings
- `LivenessConfig.basic()` - Quick verification
- `LivenessConfig.secure()` - Maximum security

## iOS Setup

Camera permissions are automatically configured. The package adds the required `NSCameraUsageDescription` to your iOS Info.plist.

## Dependencies

- `camera: ^0.11.2`
- `google_mlkit_face_detection: ^0.13.1`
- `permission_handler: ^12.0.1`

## License

This project is licensed under the MIT License.