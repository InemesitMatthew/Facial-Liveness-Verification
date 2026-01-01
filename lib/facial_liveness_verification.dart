/// Facial Liveness Verification Package
///
/// A simple, logic-focused package for real-time facial liveness verification.
/// Developers handle UI - this package provides detection logic only.
library;

/// ## Features
///
/// - **Real-time face detection** using Google ML Kit
/// - **Advanced anti-spoofing protection** with motion analysis
/// - **Interactive challenge system** (smile, blink, head turns)
/// - **Stream-based state updates** for reactive UI
/// - **Simple configuration** - no presets, just options
///
/// ## Quick Start
///
/// ```dart
/// import 'package:facial_liveness_verification/facial_liveness_verification.dart';
///
/// final detector = LivenessDetector(LivenessConfig());
/// await detector.initialize();
/// await detector.start();
///
/// detector.stateStream.listen((state) {
///   if (state.type == LivenessStateType.completed) {
///     print('Verification successful!');
///   }
/// });
///
/// // Use detector.cameraController for UI preview
/// CameraPreview(detector.cameraController!)
/// ```
///
/// For more examples and documentation, see the README file.

export 'src/detector/detector.dart';
export 'src/models/models.dart';
export 'src/challenges/challenges.dart';
export 'src/utils/utils.dart';
