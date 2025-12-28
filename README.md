# Facial Liveness Verification

A simple, logic-focused Flutter package for real-time facial liveness verification. Developers handle UI - this package provides detection logic only.

## Features

- **Real-time face detection** using Google ML Kit
- **Advanced anti-spoofing protection** with motion analysis
- **Interactive challenge system** (smile, blink, head turns, nod, head shake)
- **Stream-based state updates** for reactive UI
- **Simple configuration** - no presets, just essential options
- **Exposed camera controller** for custom UI integration

## Quick Start

### Basic Usage

```dart
import 'package:facial_liveness_verification/facial_liveness_verification.dart';
import 'package:camera/camera.dart';
import 'dart:async';

// Create detector with config
final detector = LivenessDetector(const LivenessConfig());

// Initialize
await detector.initialize();

// Start detection
await detector.start();

// Listen to state updates
detector.stateStream.listen((state) {
  switch (state.type) {
    case LivenessStateType.faceDetected:
      print('Face detected!');
      break;
    case LivenessStateType.positioned:
      print('Face positioned correctly!');
      break;
    case LivenessStateType.challengeInProgress:
      print('Current challenge: ${state.currentChallenge?.instruction}');
      break;
    case LivenessStateType.completed:
      print('Verification successful!');
      break;
    case LivenessStateType.error:
      print('Error: ${state.error?.message}');
      break;
  }
});

// Use camera controller for UI preview
CameraPreview(detector.cameraController!)

// Access face bounding box for custom overlays
final boundingBox = detector.faceBoundingBox;

// Stop detection when needed
await detector.stop();

// Clean up resources
await detector.dispose();
```

### Custom UI Example

```dart
class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late LivenessDetector _detector;
  StreamSubscription<LivenessState>? _subscription;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _detector = LivenessDetector(const LivenessConfig());
    
    _subscription = _detector.stateStream.listen((state) {
      setState(() {
        _status = _getStatusMessage(state);
      });
      
      if (state.type == LivenessStateType.completed) {
        // Handle success
        Navigator.pop(context, state.result);
      }
    });

    await _detector.initialize();
    await _detector.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your custom camera preview
          if (_detector.cameraController != null)
            CameraPreview(_detector.cameraController!),
          
          // Your custom UI overlay
          Center(child: Text(_status)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _detector.dispose();
    super.dispose();
  }
}
```

## Configuration

Simple configuration - no presets, just pick what you need:

```dart
// Default config
const config = LivenessConfig();

// Custom config - pick your challenges
const customConfig = LivenessConfig(
  challenges: [
    ChallengeType.smile,
    ChallengeType.blink,
    ChallengeType.turnLeft,
  ],
  enableAntiSpoofing: true,
  challengeTimeout: Duration(seconds: 15),
  sessionTimeout: Duration(minutes: 3),
  smileThreshold: 0.6,
  headAngleThreshold: 20.0,
);
```

### Available Challenge Types

- `ChallengeType.smile` - User must smile
- `ChallengeType.blink` - User must blink
- `ChallengeType.turnLeft` - User must turn head left
- `ChallengeType.turnRight` - User must turn head right
- `ChallengeType.nod` - User must nod head
- `ChallengeType.headShake` - User must shake head

### Configuration Options

**Challenge Configuration:**
- `challenges` - List of challenges to perform (default: `[smile, blink, turnLeft, turnRight]`)
- `shuffleChallenges` - Randomize challenge order (default: `true`)

**Timing Configuration:**
- `challengeTimeout` - Max time per challenge (default: `20 seconds`)
- `sessionTimeout` - Max time for entire session (default: `5 minutes`)
- `maxAttempts` - Maximum attempts allowed (default: `3`)
- `minVerificationTime` - Minimum verification time in seconds (default: `2`)

**Detection Thresholds:**
- `smileThreshold` - Smile detection threshold 0.0-1.0 (default: `0.55`)
- `eyeOpenThreshold` - Eye open threshold for blink detection 0.0-1.0 (default: `0.35`)
- `headAngleThreshold` - Head turn angle in degrees (default: `18.0`)
- `maxHeadAngle` - Maximum head angle deviation in degrees (default: `18.0`)

**Face Positioning:**
- `centerTolerance` - Face centering tolerance 0.0-1.0 (default: `0.2`)
- `minFaceSize` - Minimum face size as ratio of image (default: `0.2`)
- `maxFaceSize` - Maximum face size as ratio of image (default: `0.85`)
- `requireNeutralPosition` - Require neutral position between challenges (default: `true`)

**Performance Configuration:**
- `frameSkipRate` - Process every Nth frame (default: `2`)
- `cameraResolution` - Camera resolution preset (default: `ResolutionPreset.medium`)
- `detectorMode` - Face detector mode: `FaceDetectorMode.accurate` or `FaceDetectorMode.fast` (default: `FaceDetectorMode.accurate`)

**Anti-Spoofing Configuration:**
- `enableAntiSpoofing` - Enable anti-spoofing detection (default: `true`)
- `minMotionVariance` - Minimum motion variance threshold (default: `0.3`)
- `maxStaticFrames` - Maximum static frames ratio (default: `0.8`)
- `minDepthVariation` - Minimum depth variation (default: `0.015`)
- `maxHistoryLength` - Maximum history length for motion analysis (default: `30`)

## API Reference

### LivenessDetector Methods

- `initialize()` - Initialize the detector and camera
- `start()` - Start face detection and challenge processing
- `stop()` - Stop detection (camera continues running)
- `dispose()` - Clean up all resources

### LivenessDetector Properties

- `stateStream` - Stream of `LivenessState` updates
- `cameraController` - Exposed `CameraController` for UI preview
- `faceBoundingBox` - Current face bounding box (`Rect?`)

## State Management

The detector provides a stream of states:

- `LivenessStateType.initialized` - Detector ready
- `LivenessStateType.detecting` - Detection in progress
- `LivenessStateType.noFace` - No face detected
- `LivenessStateType.faceDetected` - Face detected
- `LivenessStateType.positioning` - Face being positioned
- `LivenessStateType.positioned` - Face positioned correctly
- `LivenessStateType.challengeInProgress` - Challenge active
- `LivenessStateType.challengeCompleted` - Challenge completed
- `LivenessStateType.completed` - All challenges completed
- `LivenessStateType.error` - Error occurred

## Example App

Run the example app to see custom UI integration:

```bash
cd example_app
flutter run
```

## iOS Setup

Add camera permission to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for identity verification</string>
```

## Android Setup

Add camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Dependencies

- `camera: ^0.11.2`
- `google_mlkit_face_detection: ^0.13.1`
- `permission_handler: ^12.0.1`

## License

This project is licensed under the MIT License.
