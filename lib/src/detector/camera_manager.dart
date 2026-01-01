import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/core/interfaces.dart';
import 'package:facial_liveness_verification/src/models/models.dart';

/// Manages camera initialization and image streaming for face detection.
class CameraManager implements ICameraManager {
  CameraController? _controller;
  final LivenessConfig _config;

  CameraManager(this._config);

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  /// Initializes the camera, preferring the front-facing camera.
  @override
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw LivenessError.camera(
          message: 'No cameras available on this device',
        );
      }

      // Prefer front camera, fallback to any available camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        _config.cameraResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
    } catch (e, stackTrace) {
      throw LivenessError.camera(
        message: 'Failed to initialize camera',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Tests ML Kit setup by creating and closing a test detector.
  ///
  /// Throws [LivenessError] if ML Kit is not properly configured.
  @override
  Future<void> testMLKitSetup() async {
    try {
      final testDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
          minFaceSize: 0.1,
        ),
      );
      await testDetector.close();
    } catch (e) {
      throw LivenessError.faceDetection(
        message: 'ML Kit setup failed',
        details: e.toString(),
        originalException: e,
      );
    }
  }

  /// Starts the camera image stream for face detection processing.
  @override
  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw LivenessError.camera(message: 'Camera not initialized');
    }
    try {
      await _controller!.startImageStream(onImage);
    } catch (e, stackTrace) {
      throw LivenessError.camera(
        message: 'Failed to start image stream',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        // Log but don't throw - stopping is best-effort during cleanup
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stopImageStream();
    try {
      await _controller?.dispose();
    } catch (e) {
      // Log but don't throw - disposal is best-effort
    } finally {
      _controller = null;
    }
  }
}
