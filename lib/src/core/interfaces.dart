/// Abstract interfaces for dependency injection.
library;

import 'package:facial_liveness_verification/src/core/dependencies.dart';

/// Interface for face detection operations.
abstract class IFaceDetector {
  /// Processes an image and returns detected faces.
  Future<List<Face>> processImage(InputImage image);

  /// Closes the detector and releases resources.
  Future<void> close();
}

/// Interface for camera management operations.
abstract class ICameraManager {
  /// Initializes the camera.
  Future<void> initialize();

  /// Tests ML Kit setup.
  Future<void> testMLKitSetup();

  /// Starts the camera image stream.
  Future<void> startImageStream(Function(CameraImage) onImage);

  /// Stops the camera image stream.
  Future<void> stopImageStream();

  /// Disposes camera resources.
  Future<void> dispose();

  /// Gets the camera controller.
  CameraController? get controller;

  /// Checks if camera is initialized.
  bool get isInitialized;
}

/// Interface for image conversion operations.
abstract class IImageConverter {
  /// Converts a camera image to ML Kit input format.
  Future<InputImage?> createInputImage(CameraImage image);
}

