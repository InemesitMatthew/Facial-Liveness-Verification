import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/liveness_config.dart';
import '../models/liveness_result.dart';
import '../models/liveness_error.dart';
import '../models/challenge_types.dart';
import '../utils/liveness_constants.dart';
import 'anti_spoofing_engine.dart';
import 'challenge_system.dart';

/// Main liveness detection engine that orchestrates all components.
///
/// This class manages camera initialization, face detection, challenge validation,
/// and anti-spoofing analysis to provide a complete liveness verification system.
class LivenessDetector {
  final LivenessConfig _config;
  late final FaceDetector _faceDetector;
  late final AntiSpoofingEngine _antiSpoofingEngine;
  late final ChallengeSystem _challengeSystem;

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isDetecting = false;
  int _frameSkipCounter = 0;
  int _attemptCount = 0;
  DateTime? _sessionStartTime;

  // Current state
  bool _isFaceDetected = false;
  bool _isPositionedCorrectly = false;
  Rect? _faceBoundingBox;
  String _feedbackMessage = 'Initializing camera...';
  
  // Face feature probabilities
  double? _smilingProbability;
  double? _leftEyeOpenProbability;
  double? _rightEyeOpenProbability;
  double? _headEulerAngleY;
  double? _headEulerAngleX;
  double? _headEulerAngleZ;

  // Stream controllers for real-time updates
  final _stateController = StreamController<LivenessDetectionState>.broadcast();
  final _progressController = StreamController<ChallengeProgress>.broadcast();

  /// Stream of liveness detection state updates.
  Stream<LivenessDetectionState> get stateStream => _stateController.stream;

  /// Stream of challenge progress updates.
  Stream<ChallengeProgress> get progressStream => _progressController.stream;

  /// Creates a new liveness detector with the given configuration.
  LivenessDetector(this._config) {
    _initializeComponents();
  }

  /// Initializes ML Kit components and detection engines.
  void _initializeComponents() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: _config.detectorMode,
        enableContours: true,
        enableClassification: true,
        minFaceSize: _config.faceConstraints.minFaceSize,
        enableTracking: true,
        enableLandmarks: true,
      ),
    );

    if (_config.enableAntiSpoofing) {
      _antiSpoofingEngine = AntiSpoofingEngine(_config.antiSpoofing);
    }

    _challengeSystem = ChallengeSystem(_config);
  }

  /// Initializes the camera and starts liveness detection.
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      dev.log('Initializing liveness detector...');

      // Test ML Kit setup
      await _testMLKitSetup();

      // Initialize camera
      await _initializeCamera();

      // Start session
      _sessionStartTime = DateTime.now();
      _attemptCount++;

      _isInitialized = true;
      _updateState(LivenessDetectionState.initialized());

      dev.log('Liveness detector initialized successfully');
    } catch (e, stackTrace) {
      dev.log('Liveness detector initialization failed: $e', stackTrace: stackTrace);
      throw LivenessError.generic(
        message: 'Failed to initialize liveness detection',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Tests ML Kit setup to ensure it's working correctly.
  Future<void> _testMLKitSetup() async {
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
      dev.log('✅ ML Kit setup verified');
    } catch (e) {
      dev.log('💥 ML Kit setup error: $e');
      throw LivenessError.faceDetection(
        message: 'ML Kit face detection setup failed',
        details: e.toString(),
        originalException: e,
      );
    }
  }

  /// Initializes the camera for face detection.
  Future<void> _initializeCamera() async {
    try {
      dev.log('📱 Initializing camera...');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw LivenessError.camera(message: ErrorMessages.cameraNotAvailable);
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        _config.cameraResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      dev.log('📱 Camera initialized successfully');

    } catch (e, stackTrace) {
      dev.log('📱 Camera initialization failed: $e', stackTrace: stackTrace);
      throw LivenessError.camera(
        message: ErrorMessages.cameraInitFailed,
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts the face detection and liveness verification process.
  Future<void> startDetection() async {
    if (!_isInitialized || _cameraController == null) {
      throw LivenessError.generic(message: 'Detector not initialized');
    }

    try {
      dev.log('🚀 Starting face detection stream...');
      await _cameraController!.startImageStream(_processFrame);
      _updateState(LivenessDetectionState.detecting());
    } catch (e, stackTrace) {
      dev.log('🚀 Failed to start detection: $e', stackTrace: stackTrace);
      throw LivenessError.camera(
        message: 'Failed to start face detection',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processes individual camera frames for face detection.
  Future<void> _processFrame(CameraImage image) async {
    // Frame skipping for performance
    if (_frameSkipCounter % _config.frameSkipRate != 0) {
      _frameSkipCounter++;
      return;
    }
    _frameSkipCounter++;

    // Prevent concurrent processing
    if (_isDetecting) return;

    _isDetecting = true;

    try {
      await _detectFacesWithAntiSpoofing(image);
    } catch (e) {
      dev.log('⚠️ Frame processing error: $e');
      _updateState(LivenessDetectionState.error(
        LivenessError.faceDetection(
          message: 'Frame processing failed',
          details: e.toString(),
          originalException: e,
        ),
      ));
    } finally {
      _isDetecting = false;
    }
  }

  /// Main face detection and analysis pipeline.
  Future<void> _detectFacesWithAntiSpoofing(CameraImage image) async {
    final startTime = DateTime.now();

    // Create input image for ML Kit
    final inputImage = await _createOptimizedInputImage(image);
    if (inputImage == null) {
      _resetFaceState('Failed to process camera image');
      return;
    }

    // Detect faces
    final faces = await _faceDetector.processImage(inputImage);
    final validFaces = faces.where((face) => _isValidFace(face)).toList();

    if (validFaces.isEmpty) {
      _resetFaceState('No valid face detected - please position your face in the center');
      return;
    }

    // Anti-spoofing analysis (if enabled)
    if (_config.enableAntiSpoofing) {
      final spoofingResult = await _antiSpoofingEngine.analyzeFaces(
        validFaces,
        image,
        DateTime.now(),
      );

      if (!spoofingResult.isLive) {
        _resetFaceState(spoofingResult.reason);
        return;
      }
    }

    final face = validFaces.first;
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    dev.log('⚡ Processing time: ${processingTime}ms');

    // Update face state
    _updateFaceState(face, image.width, image.height);
    
    // Check face positioning
    _checkFacePositioning(face, image.width, image.height);

    if (_isPositionedCorrectly) {
      // Process challenges
      await _processChallenge(face);
    }
  }

  /// Updates the current face detection state.
  void _updateFaceState(Face face, int imageWidth, int imageHeight) {
    _isFaceDetected = true;
    _smilingProbability = face.smilingProbability;
    _leftEyeOpenProbability = face.leftEyeOpenProbability;
    _rightEyeOpenProbability = face.rightEyeOpenProbability;
    _headEulerAngleY = face.headEulerAngleY;
    _headEulerAngleX = face.headEulerAngleX;
    _headEulerAngleZ = face.headEulerAngleZ;
    _faceBoundingBox = face.boundingBox;

    _updateState(LivenessDetectionState.faceDetected(face));
  }

  /// Resets the face detection state.
  void _resetFaceState(String feedback) {
    _isFaceDetected = false;
    _isPositionedCorrectly = false;
    _feedbackMessage = feedback;
    _faceBoundingBox = null;

    _updateState(LivenessDetectionState.noFace(feedback));
  }

  /// Checks if the detected face is properly positioned for verification.
  void _checkFacePositioning(Face face, int imageWidth, int imageHeight) {
    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;
    final centerY = box.top + box.height / 2;

    final inFrame = _isInFrame(box, imageWidth, imageHeight);
    final centered = _isCentered(centerX, centerY, imageWidth, imageHeight);
    final lookingStraight = _isLookingStraight(face);
    final goodSize = _isGoodSize(box, imageWidth, imageHeight);
    final withinGuideCircle = _isWithinGuideCircle(centerX, centerY, imageWidth, imageHeight);

    final isTurnChallenge = _challengeSystem.isInTurnChallenge;
    final relaxedCentering = isTurnChallenge
        ? _isCenteredRelaxed(centerX, centerY, imageWidth, imageHeight)
        : centered;

    final qualityGood = isTurnChallenge
        ? inFrame && goodSize && withinGuideCircle
        : inFrame && relaxedCentering && lookingStraight && goodSize && withinGuideCircle;

    _isPositionedCorrectly = qualityGood;
    _feedbackMessage = _getPositioningFeedback(
      face: face,
      inFrame: inFrame,
      centered: relaxedCentering,
      lookingStraight: lookingStraight,
      goodSize: goodSize,
      withinGuideCircle: withinGuideCircle,
      isTurnChallenge: isTurnChallenge,
      centerX: centerX,
      screenCenterX: imageWidth / 2,
      centerY: centerY,
      screenCenterY: imageHeight / 2,
    );

    if (qualityGood) {
      _updateState(LivenessDetectionState.positioned(face, _feedbackMessage));
    } else {
      _updateState(LivenessDetectionState.positioning(face, _feedbackMessage));
    }
  }

  /// Processes the current challenge with the detected face.
  Future<void> _processChallenge(Face face) async {
    final progress = _challengeSystem.processChallenge(face);
    _progressController.add(progress);

    switch (progress.type) {
      case ChallengeProgressType.allCompleted:
        await _completeLivenessVerification(progress);
        break;
      case ChallengeProgressType.challengeCompleted:
        _updateState(LivenessDetectionState.challengeCompleted(
          progress.completedChallenge!,
          progress.nextChallenge!,
        ));
        break;
      case ChallengeProgressType.timeout:
        _updateState(LivenessDetectionState.challengeTimeout(
          progress.currentChallenge,
          progress.timeoutDuration!,
        ));
        break;
      case ChallengeProgressType.error:
        _updateState(LivenessDetectionState.error(
          LivenessError.generic(message: progress.error!),
        ));
        break;
      default:
        // Continue with current challenge
        break;
    }
  }

  /// Completes the liveness verification process.
  Future<void> _completeLivenessVerification(ChallengeProgress progress) async {
    final totalTime = DateTime.now().difference(_sessionStartTime!);
    
    // Calculate confidence score
    double confidenceScore = 1.0;
    if (_config.enableAntiSpoofing) {
      final stats = _antiSpoofingEngine.getAnalysisStats();
      if (stats['overallPassed'] == true) {
        confidenceScore = 0.9; // High confidence for passed anti-spoofing
      }
    }

    // Create anti-spoofing result
    AntiSpoofingResult antiSpoofingResult;
    if (_config.enableAntiSpoofing) {
      final stats = _antiSpoofingEngine.getAnalysisStats();
      antiSpoofingResult = AntiSpoofingResult.live(
        confidence: confidenceScore,
        motionAnalysis: MotionAnalysis(
          motionVariance: stats['motionVariance'] ?? 0.0,
          staticFrameRatio: stats['staticFrameRatio'] ?? 1.0,
          passed: stats['overallPassed'] ?? false,
        ),
        depthAnalysis: DepthAnalysis(
          sizeVariation: stats['sizeVariation'] ?? 0.0,
          minSize: 0.0,
          maxSize: 0.0,
          passed: stats['overallPassed'] ?? false,
        ),
        timingAnalysis: TimingAnalysis(
          totalTime: totalTime.inMilliseconds,
          minimumTime: _config.antiSpoofing.minVerificationTime * 1000,
          passed: true,
        ),
      );
    } else {
      antiSpoofingResult = const AntiSpoofingResult.failed('Anti-spoofing disabled');
    }

    final result = LivenessResult.success(
      completedChallenges: progress.completedChallenges,
      totalTime: totalTime,
      challengeTimes: progress.completionTimes,
      confidenceScore: confidenceScore,
      antiSpoofingResult: antiSpoofingResult,
      attemptCount: _attemptCount,
    );

    _updateState(LivenessDetectionState.completed(result));
    dev.log('🎉 Liveness verification completed successfully!');
  }

  /// Helper methods for face positioning validation
  bool _isInFrame(Rect box, int width, int height) {
    return box.left >= 0 && box.top >= 0 && box.right <= width && box.bottom <= height;
  }

  bool _isCentered(double centerX, double centerY, int width, int height) {
    final screenCenterX = width / 2;
    final screenCenterY = height / 2;
    final thresholdX = width * _config.thresholds.centerTolerance;
    final thresholdY = height * _config.thresholds.centerTolerance;

    return (centerX - screenCenterX).abs() < thresholdX &&
        (centerY - screenCenterY).abs() < thresholdY;
  }

  bool _isCenteredRelaxed(double centerX, double centerY, int width, int height) {
    final screenCenterX = width / 2;
    final screenCenterY = height / 2;
    final relaxedThresholdX = width * (_config.thresholds.centerTolerance * 1.5);
    final relaxedThresholdY = height * (_config.thresholds.centerTolerance * 1.5);

    return (centerX - screenCenterX).abs() < relaxedThresholdX &&
        (centerY - screenCenterY).abs() < relaxedThresholdY;
  }

  bool _isLookingStraight(Face face) {
    return (face.headEulerAngleY?.abs() ?? 0) < _config.faceConstraints.maxHeadAngle &&
        (face.headEulerAngleX?.abs() ?? 0) < _config.faceConstraints.maxHeadAngle &&
        (face.headEulerAngleZ?.abs() ?? 0) < _config.faceConstraints.maxHeadAngle;
  }

  bool _isGoodSize(Rect box, int width, int height) {
    final faceArea = box.width * box.height;
    final imageArea = width * height;
    final ratio = faceArea / imageArea;
    return ratio >= _config.faceConstraints.minFaceSize &&
        ratio <= _config.faceConstraints.maxFaceSize;
  }

  bool _isWithinGuideCircle(double centerX, double centerY, int imageWidth, int imageHeight) {
    final screenCenterX = imageWidth / 2;
    final screenCenterY = imageHeight / 2 + UIConstants.guideCircleOffset;
    final guideRadius = imageWidth * _config.faceConstraints.guideCircleRadius;

    final distance = sqrt(
      pow(centerX - screenCenterX, 2) + pow(centerY - screenCenterY, 2),
    );

    return distance <= guideRadius;
  }

  bool _isValidFace(Face face) {
    final hasEyes = face.leftEyeOpenProbability != null || face.rightEyeOpenProbability != null;
    final hasSmile = face.smilingProbability != null;
    final hasHeadAngles = face.headEulerAngleX != null ||
        face.headEulerAngleY != null ||
        face.headEulerAngleZ != null;

    final box = face.boundingBox;
    final aspectRatio = box.width / box.height;
    final reasonableAspectRatio = aspectRatio >= 0.5 && aspectRatio <= 2.0;
    final faceArea = box.width * box.height;
    final reasonableSize = faceArea > 1000;

    return hasEyes && hasSmile && hasHeadAngles && reasonableAspectRatio && reasonableSize;
  }

  /// Creates optimized input image for ML Kit processing.
  Future<InputImage?> _createOptimizedInputImage(CameraImage image) async {
    try {
      final formats = [
        InputImageFormat.nv21,
        InputImageFormat.yuv420,
        InputImageFormat.bgra8888,
      ];

      for (final format in formats) {
        try {
          final inputImage = await _createInputImageWithFormat(image, format);
          if (inputImage != null) return inputImage;
        } catch (e) {
          continue;
        }
      }
      return null;
    } catch (e) {
      dev.log('💥 InputImage creation error: $e');
      return null;
    }
  }

  Future<InputImage?> _createInputImageWithFormat(
    CameraImage image,
    InputImageFormat format,
  ) async {
    try {
      Uint8List bytes;
      int bytesPerRow;

      switch (format) {
        case InputImageFormat.nv21:
          bytes = _createNV21BytesEnhanced(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.yuv420:
          bytes = _createYUV420BytesEnhanced(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.bgra8888:
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
          break;
        default:
          return null;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getImageRotationDynamic(),
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List _createNV21BytesEnhanced(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uvSize = (image.width * image.height) ~/ 4;
    final nv21Bytes = Uint8List(ySize + 2 * uvSize);

    _copyPlaneWithStride(yPlane, nv21Bytes, 0, image.width, image.height);

    int uvIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      final uvPixelIndex = i ~/ image.width * (uPlane.bytesPerRow ~/ 2) + i % image.width;

      if (uvPixelIndex < vPlane.bytes.length && uvPixelIndex < uPlane.bytes.length) {
        nv21Bytes[uvIndex++] = vPlane.bytes[uvPixelIndex];
        nv21Bytes[uvIndex++] = uPlane.bytes[uvPixelIndex];
      } else {
        nv21Bytes[uvIndex++] = vPlane.bytes[i % vPlane.bytes.length];
        nv21Bytes[uvIndex++] = uPlane.bytes[i % uPlane.bytes.length];
      }
    }

    return nv21Bytes;
  }

  Uint8List _createYUV420BytesEnhanced(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uSize = (image.width * image.height) ~/ 4;
    final vSize = (image.width * image.height) ~/ 4;
    final yuvBytes = Uint8List(ySize + uSize + vSize);

    _copyPlaneWithStride(yPlane, yuvBytes, 0, image.width, image.height);
    _copyPlaneWithStride(uPlane, yuvBytes, ySize, image.width ~/ 2, image.height ~/ 2);
    _copyPlaneWithStride(vPlane, yuvBytes, ySize + uSize, image.width ~/ 2, image.height ~/ 2);

    return yuvBytes;
  }

  void _copyPlaneWithStride(
    Plane plane,
    Uint8List destination,
    int destOffset,
    int width,
    int height,
  ) {
    final srcBytes = plane.bytes;
    final srcStride = plane.bytesPerRow;

    for (int y = 0; y < height; y++) {
      final srcOffset = y * srcStride;
      final destStart = destOffset + y * width;
      final copyLength = min(width, srcBytes.length - srcOffset);

      if (copyLength > 0) {
        destination.setRange(destStart, destStart + copyLength, srcBytes, srcOffset);
      }
    }
  }

  InputImageRotation _getImageRotationDynamic() {
    return InputImageRotation.rotation270deg;
  }

  /// Gets positioning feedback message for the user.
  String _getPositioningFeedback({
    required Face face,
    required bool inFrame,
    required bool centered,
    required bool lookingStraight,
    required bool goodSize,
    required bool withinGuideCircle,
    required bool isTurnChallenge,
    required double centerX,
    required double screenCenterX,
    required double centerY,
    required double screenCenterY,
  }) {
    final customMessages = _config.customMessages;

    if (!inFrame) return 'Face not in frame - please move into view 📱';

    if (!centered) {
      return centerX < screenCenterX
          ? 'Move right to center your face - you\'re almost there!'
          : 'Move left to center your face - you\'re almost there!';
    }

    if (!lookingStraight) return 'Look straight ahead - keep your head level!';

    if (!goodSize) {
      return face.boundingBox.width * face.boundingBox.height < 10000
          ? customMessages?.moveCloser ?? 'Move closer to the camera - we need a clear view!'
          : customMessages?.moveFarther ?? 'Move back from the camera - you\'re too close!';
    }

    if (!withinGuideCircle) {
      if (isTurnChallenge) {
        return 'Keep your face in the guide circle while turning - you\'re doing great!';
      }
      return customMessages?.positionFace ?? 'Position your face within the guide circle - you\'re almost there!';
    }

    if (isTurnChallenge) {
      return 'Perfect! Now turn back to center when ready!';
    }

    return customMessages?.facePositioned ?? 'Perfect! You\'re all set for verification! ✨';
  }

  /// Updates the current state and notifies listeners.
  void _updateState(LivenessDetectionState state) {
    _stateController.add(state);
  }

  /// Gets the current camera controller (for UI preview).
  CameraController? get cameraController => _cameraController;

  /// Gets the current face bounding box (for UI overlay).
  Rect? get faceBoundingBox => _faceBoundingBox;

  /// Gets whether a face is currently detected.
  bool get isFaceDetected => _isFaceDetected;

  /// Gets whether the face is positioned correctly.
  bool get isPositionedCorrectly => _isPositionedCorrectly;

  /// Gets the current feedback message.
  String get feedbackMessage => _feedbackMessage;

  /// Gets the current challenge system.
  ChallengeSystem get challengeSystem => _challengeSystem;

  /// Gets current facial feature probabilities.
  double? get smilingProbability => _smilingProbability;
  double? get leftEyeOpenProbability => _leftEyeOpenProbability;
  double? get rightEyeOpenProbability => _rightEyeOpenProbability;
  double? get headEulerAngleY => _headEulerAngleY;
  double? get headEulerAngleX => _headEulerAngleX;
  double? get headEulerAngleZ => _headEulerAngleZ;

  /// Stops face detection and cleans up resources.
  Future<void> dispose() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
      }
      
      await _faceDetector.close();
      
      if (_config.enableAntiSpoofing) {
        _antiSpoofingEngine.dispose();
      }

      await _stateController.close();
      await _progressController.close();

      dev.log('Liveness detector disposed');
    } catch (e) {
      dev.log('Error disposing liveness detector: $e');
    }
  }
}

/// Represents the current state of liveness detection.
class LivenessDetectionState {
  final LivenessDetectionStateType type;
  final Face? face;
  final LivenessResult? result;
  final LivenessError? error;
  final String? message;
  final ChallengeType? completedChallenge;
  final ChallengeType? nextChallenge;
  final Duration? timeoutDuration;

  const LivenessDetectionState._({
    required this.type,
    this.face,
    this.result,
    this.error,
    this.message,
    this.completedChallenge,
    this.nextChallenge,
    this.timeoutDuration,
  });

  factory LivenessDetectionState.initialized() =>
      const LivenessDetectionState._(type: LivenessDetectionStateType.initialized);

  factory LivenessDetectionState.detecting() =>
      const LivenessDetectionState._(type: LivenessDetectionStateType.detecting);

  factory LivenessDetectionState.noFace(String message) =>
      LivenessDetectionState._(type: LivenessDetectionStateType.noFace, message: message);

  factory LivenessDetectionState.faceDetected(Face face) =>
      LivenessDetectionState._(type: LivenessDetectionStateType.faceDetected, face: face);

  factory LivenessDetectionState.positioning(Face face, String message) =>
      LivenessDetectionState._(
          type: LivenessDetectionStateType.positioning, face: face, message: message);

  factory LivenessDetectionState.positioned(Face face, String message) =>
      LivenessDetectionState._(
          type: LivenessDetectionStateType.positioned, face: face, message: message);

  factory LivenessDetectionState.challengeCompleted(
          ChallengeType completed, ChallengeType next) =>
      LivenessDetectionState._(
        type: LivenessDetectionStateType.challengeCompleted,
        completedChallenge: completed,
        nextChallenge: next,
      );

  factory LivenessDetectionState.challengeTimeout(
          ChallengeType challenge, Duration timeout) =>
      LivenessDetectionState._(
        type: LivenessDetectionStateType.challengeTimeout,
        timeoutDuration: timeout,
      );

  factory LivenessDetectionState.completed(LivenessResult result) =>
      LivenessDetectionState._(type: LivenessDetectionStateType.completed, result: result);

  factory LivenessDetectionState.error(LivenessError error) =>
      LivenessDetectionState._(type: LivenessDetectionStateType.error, error: error);
}

/// Types of liveness detection states.
enum LivenessDetectionStateType {
  initialized,
  detecting,
  noFace,
  faceDetected,
  positioning,
  positioned,
  challengeCompleted,
  challengeTimeout,
  completed,
  error,
}