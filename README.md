# Facial Liveness Verification

A simple, logic-focused Flutter package for real-time facial liveness verification. Developers handle UI - this package provides detection logic only.

## What is Liveness Detection?

Liveness detection verifies that a real person is in front of the camera, not a photo, video, or mask. This package uses:

1. **Face Detection** - Detects faces using Google ML Kit
2. **Anti-Spoofing** - Analyzes motion patterns to detect fake attempts
3. **Interactive Challenges** - Asks users to perform actions (smile, blink, turn head) that prove they're alive

## How It Works

The package follows a simple flow:

```
1. Initialize → Camera and ML Kit setup
2. Start Detection → Process camera frames
3. Detect Face → Find and validate face position
4. Run Challenges → User performs actions (smile, blink, etc.)
5. Complete → Return verification result
```

All state changes are emitted via a stream, so you can build reactive UI that responds to detection events.

## Features

- **Real-time face detection** using Google ML Kit
- **Advanced anti-spoofing protection** with motion analysis
- **Interactive challenge system** (smile, blink, head turns, nod, head shake)
- **Stream-based state updates** for reactive UI
- **Simple configuration** - no presets, just essential options
- **Exposed camera controller** for custom UI integration
- **Coordinate transformation utilities** for drawing face overlays

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

### Drawing Face Overlays

If you want to draw overlays showing face position, use the coordinate utilities:

```dart
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

// Get face bounding box from detector
final faceBox = detector.faceBoundingBox;
if (faceBox != null) {
  // Get camera preview size
  final previewSize = detector.cameraController!.value.previewSize!;
  final screenSize = MediaQuery.of(context).size;
  
  // Convert ML Kit coordinates to screen coordinates
  final screenRect = CoordinateUtils.convertImageRectToScreenRect(
    faceBox,
    previewSize,
    screenSize,
  );
  
  // Now you can draw overlay at screenRect
  // See example app for CustomPainter implementation
}

// Calculate target guide position
final targetRect = CoordinateUtils.calculateTargetRect(screenSize);
// Draw oval at targetRect to guide user positioning
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

- `initialize()` - Initialize the detector and camera. Must be called before `start()`.
- `start()` - Start face detection and challenge processing. Begins processing camera frames.
- `stop()` - Stop detection (camera continues running). Use this to pause without disposing.
- `dispose()` - Clean up all resources. Always call this when done to free camera and ML Kit resources.

### LivenessDetector Properties

- `stateStream` - Stream of `LivenessState` updates. Listen to this for all state changes.
- `cameraController` - Exposed `CameraController` for UI preview. Use with `CameraPreview` widget.
- `faceBoundingBox` - Current face bounding box (`Rect?`). In ML Kit image coordinates - use `CoordinateUtils` to convert to screen coordinates.

### CoordinateUtils (Optional Utility)

Helper class for coordinate transformations when drawing UI overlays:

- `convertImageRectToScreenRect()` - Converts ML Kit image coordinates to screen coordinates. Handles aspect ratio differences and rotation automatically.
- `calculateTargetRect()` - Calculates a centered target rectangle for face positioning guidance. Useful for drawing oval guides.

## State Management

The detector provides a stream of states that you can listen to and update your UI accordingly:

- `LivenessStateType.initialized` - Detector and camera are ready. Safe to show camera preview.
- `LivenessStateType.detecting` - Detection in progress. Processing camera frames.
- `LivenessStateType.noFace` - No face detected in current frame. Show "position face" message.
- `LivenessStateType.faceDetected` - Face detected but may not be positioned correctly yet.
- `LivenessStateType.positioning` - Face detected but not yet properly centered/sized. Show positioning guidance.
- `LivenessStateType.positioned` - Face is properly positioned. Challenges can begin.
- `LivenessStateType.challengeInProgress` - A challenge is currently active. Show challenge instruction.
- `LivenessStateType.challengeCompleted` - Current challenge completed. Moving to next challenge.
- `LivenessStateType.completed` - All challenges completed successfully! Check `state.result` for details.
- `LivenessStateType.error` - An error occurred. Check `state.error` for details and recovery options.

### Understanding the Flow

```
initialized → detecting → faceDetected → positioning → positioned 
  → challengeInProgress → challengeCompleted → (repeat for each challenge) 
  → completed
```

If face is lost at any point, state returns to `noFace` or `positioning`.

## Example App

The example app demonstrates a complete implementation with:

- Custom UI overlays showing face position and target guide
- Challenge progress indicators
- Dynamic instruction text based on state
- Coordinate transformation for drawing overlays
- Error handling and recovery

Run the example app:

```bash
cd example_app
flutter run
```

The example app code is heavily commented to help you understand how to integrate the package. Key concepts demonstrated:

1. **State Stream Listening** - How to listen and react to state changes
2. **Camera Preview Integration** - Using the exposed camera controller
3. **Coordinate Transformation** - Converting ML Kit coordinates to screen coordinates
4. **Custom Overlays** - Drawing face guides and progress indicators
5. **Challenge Instructions** - Using challenge instructions from the package

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
