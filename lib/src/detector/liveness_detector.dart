import 'dart:async';
import 'dart:developer' as dev;

import 'package:facial_liveness_verification/src/src.dart';

/// Main detector class for facial liveness verification.
///
/// Handles face detection, challenge validation, and anti-spoofing analysis.
/// Emits state updates via [stateStream] for reactive UI integration.
class LivenessDetector {
  final LivenessConfig _config;
  final IFaceDetector _faceDetector;
  final ICameraManager _cameraManager;
  final IImageConverter _imageConverter;
  final SpoofingDetector? _spoofingDetector;
  final ChallengeValidator _challengeValidator;

  // Internal state tracking
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isRunning = false;
  int _frameSkipCounter = 0;
  int _attemptCount = 0;
  DateTime? _sessionStartTime;

  // Challenge management
  final List<ChallengeType> _challenges;
  int _currentChallengeIndex = 0;
  bool _waitingForNeutral = false;
  bool _isInTurnChallenge = false;
  final Map<ChallengeType, DateTime> _challengeStartTimes = {};
  final Map<ChallengeType, Duration> _challengeCompletionTimes = {};

  // Stability buffer state
  DateTime? _lastGoodFaceTime;
  int _consecutiveGoodFrames = 0;
  int _consecutiveBadFrames = 0;
  bool _currentStableState = false;

  /// Current face bounding box, if a face is detected.
  Rect? get faceBoundingBox => _faceBoundingBox;
  Rect? _faceBoundingBox;

  final _stateController = StreamController<LivenessState>.broadcast();

  /// Stream of state updates during verification process.
  Stream<LivenessState> get stateStream => _stateController.stream;

  /// Camera controller for UI preview integration.
  CameraController? get cameraController => _cameraManager.controller;

  /// Creates a LivenessDetector with the given configuration.
  LivenessDetector(
    this._config, {
    IFaceDetector? faceDetector,
    ICameraManager? cameraManager,
    IImageConverter? imageConverter,
    ChallengeValidator? challengeValidator,
    SpoofingDetector? spoofingDetector,
  })  : _challenges = List.from(_config.challenges),
        _faceDetector = faceDetector ?? _createDefaultFaceDetector(_config),
        _cameraManager = cameraManager ?? CameraManager(_config),
        _imageConverter = imageConverter ?? const ImageConverter(),
        _challengeValidator = challengeValidator ?? ChallengeValidator(_config),
        _spoofingDetector = spoofingDetector ??
            (_config.enableAntiSpoofing ? SpoofingDetector(_config) : null) {
    if (_config.shuffleChallenges) {
      _challenges.shuffle();
    }
  }

  static IFaceDetector _createDefaultFaceDetector(LivenessConfig config) {
    return FaceDetectorWrapper(
      FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: config.detectorMode,
          enableContours: true,
          enableClassification: true,
          minFaceSize: config.minFaceSize,
          enableTracking: true,
          enableLandmarks: true,
        ),
      ),
    );
  }

  /// Initializes the detector and camera.
  ///
  /// Must be called before [start()]. Throws [LivenessError] on failure.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _cameraManager.testMLKitSetup();
      await _cameraManager.initialize();

      _sessionStartTime = DateTime.now();
      _attemptCount++;
      _isInitialized = true;

      _updateState(LivenessState.initialized());
    } catch (e, stackTrace) {
      throw LivenessError.generic(
        message: 'Failed to initialize liveness detection',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts face detection and challenge processing.
  ///
  /// Requires [initialize()] to be called first. Throws [LivenessError] on failure.
  Future<void> start() async {
    if (!_isInitialized) {
      throw LivenessError.generic(message: 'Detector not initialized');
    }

    if (_isRunning) return;

    try {
      await _cameraManager.startImageStream(_processFrame);
      _isRunning = true;
      _lastGoodFaceTime = null;
      _consecutiveGoodFrames = 0;
      _consecutiveBadFrames = 0;
      _currentStableState = false;
      _updateState(LivenessState.detecting());
    } catch (e, stackTrace) {
      throw LivenessError.camera(
        message: 'Failed to start detection',
        details: e.toString(),
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stops detection processing (camera remains active).
  ///
  /// Use [dispose()] to fully clean up resources.
  Future<void> stop() async {
    if (!_isRunning) return;

    await _cameraManager.stopImageStream();
    _isRunning = false;
  }

  Future<void> _processFrame(CameraImage image) async {
    // Stop processing if verification is already completed
    if (_currentChallengeIndex >= _challenges.length) {
      return;
    }

    if (!_isRunning) {
      return;
    }

    _frameSkipCounter++;
    if ((_frameSkipCounter - 1) % _config.frameSkipRate != 0) {
      return;
    }

    if (_isDetecting) return;
    _isDetecting = true;

    try {
      await _detectFaces(image);
    } catch (e) {
      dev.log('Frame processing failed', error: e);
      _updateState(LivenessState.error(
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

  Future<void> _detectFaces(CameraImage image) async {
    final inputImage = await _imageConverter.createInputImage(image);
    if (inputImage == null) {
      _updateState(LivenessState.noFace('Failed to process camera image'));
      return;
    }

    final faces = await _faceDetector.processImage(inputImage);
    final validFaces = faces.where((face) => _isValidFace(face)).toList();

    if (validFaces.isEmpty) {
      _updateState(LivenessState.noFace('No face detected'));
      return;
    }

    if (!await _checkAntiSpoofing(validFaces, image)) {
      return;
    }

    await _processDetectedFace(validFaces.first, image);
  }

  Future<bool> _checkAntiSpoofing(
      List<Face> validFaces, CameraImage image) async {
    if (!_config.enableAntiSpoofing || _spoofingDetector == null) {
      return true;
    }

    final spoofingResult = await _spoofingDetector!.analyzeFaces(
      validFaces,
      image,
      DateTime.now(),
    );

    if (!spoofingResult.isLive) {
      _updateState(LivenessState.noFace(spoofingResult.reason));
      return false;
    }

    return true;
  }

  Future<void> _processDetectedFace(Face face, CameraImage image) async {
    // Don't process if verification is already completed
    if (_currentChallengeIndex >= _challenges.length) {
      return;
    }

    _faceBoundingBox = face.boundingBox;
    _updateState(LivenessState.faceDetected(face));

    final isPositioned =
        _checkPositioningWithStability(face, image.width, image.height);
    if (isPositioned) {
      _updateState(LivenessState.positioned(face));
      await _processChallenge(face);
    } else {
      _updateState(LivenessState.positioning(face));
    }
  }

  /// Checks if face is properly positioned for challenge validation.
  bool _checkPositioning(Face face, int imageWidth, int imageHeight) {
    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;
    final centerY = box.top + box.height / 2;

    if (!_isInFrame(box, imageWidth, imageHeight)) {
      return false;
    }

    final relaxedCentering = _isInTurnChallenge
        ? _isCenteredRelaxed(centerX, centerY, imageWidth, imageHeight)
        : _isCentered(centerX, centerY, imageWidth, imageHeight);

    if (!relaxedCentering || !_isGoodSize(box, imageWidth, imageHeight)) {
      return false;
    }

    return _isInTurnChallenge || _isLookingStraight(face);
  }

  /// Checks positioning with stability buffer to prevent flickering.
  bool _checkPositioningWithStability(
      Face face, int imageWidth, int imageHeight) {
    final qualityGood = _checkPositioning(face, imageWidth, imageHeight);
    final now = DateTime.now();

    if (!_config.enableStabilityBuffer) {
      return qualityGood;
    }

    if (qualityGood) {
      _consecutiveGoodFrames++;
      _consecutiveBadFrames = 0;
      _lastGoodFaceTime = now;

      if (_consecutiveGoodFrames >= _config.stabilityGoodFrameCount) {
        _currentStableState = true;
        return true;
      }

      if (_currentStableState) {
        return true;
      }

      if (_lastGoodFaceTime != null) {
        final timeSinceGood = now.difference(_lastGoodFaceTime!);
        if (timeSinceGood < _config.stabilityGracePeriod) {
          return true;
        }
      }

      return false;
    } else {
      _consecutiveBadFrames++;
      _consecutiveGoodFrames = 0;

      if (_consecutiveBadFrames >= _config.stabilityBadFrameCount) {
        _currentStableState = false;
        _lastGoodFaceTime = null;
        return false;
      }

      if (!_currentStableState) {
        return false;
      }

      if (_lastGoodFaceTime != null) {
        final timeSinceGood = now.difference(_lastGoodFaceTime!);
        if (timeSinceGood < _config.stabilityGracePeriod) {
          return true;
        } else {
          _currentStableState = false;
          _lastGoodFaceTime = null;
          return false;
        }
      }

      return false;
    }
  }

  bool _isInFrame(Rect box, int imageWidth, int imageHeight) {
    return box.left >= 0 &&
        box.top >= 0 &&
        box.right <= imageWidth &&
        box.bottom <= imageHeight;
  }

  bool _isCentered(double centerX, double centerY, int width, int height) {
    return _isCenteredWithTolerance(
        centerX, centerY, width, height, _config.centerTolerance);
  }

  bool _isCenteredRelaxed(
      double centerX, double centerY, int width, int height) {
    return _isCenteredWithTolerance(centerX, centerY, width, height,
        _config.centerTolerance * relaxedCenteringMultiplier);
  }

  bool _isCenteredWithTolerance(
      double centerX, double centerY, int width, int height, double tolerance) {
    final screenCenterX = width / 2;
    final screenCenterY = height / 2;
    final thresholdX = width * tolerance;
    final thresholdY = height * tolerance;

    return (centerX - screenCenterX).abs() < thresholdX &&
        (centerY - screenCenterY).abs() < thresholdY;
  }

  bool _isLookingStraight(Face face) {
    return (face.headEulerAngleY?.abs() ?? 0) < _config.maxHeadAngle &&
        (face.headEulerAngleX?.abs() ?? 0) < _config.maxHeadAngle &&
        (face.headEulerAngleZ?.abs() ?? 0) < _config.maxHeadAngle;
  }

  bool _isGoodSize(Rect box, int width, int height) {
    final faceArea = box.width * box.height;
    final imageArea = width * height;
    final ratio = faceArea / imageArea;
    return ratio >= _config.minFaceSize && ratio <= _config.maxFaceSize;
  }

  bool _isValidFace(Face face) {
    final hasEyes = face.leftEyeOpenProbability != null ||
        face.rightEyeOpenProbability != null;
    final hasSmile = face.smilingProbability != null;
    final hasHeadAngles = face.headEulerAngleX != null ||
        face.headEulerAngleY != null ||
        face.headEulerAngleZ != null;

    final box = face.boundingBox;
    final aspectRatio = box.width / box.height;
    final reasonableAspectRatio =
        aspectRatio >= minFaceAspectRatio && aspectRatio <= maxFaceAspectRatio;
    final faceArea = box.width * box.height;
    final reasonableSize = faceArea > minFaceAreaPixels;

    return hasEyes &&
        hasSmile &&
        hasHeadAngles &&
        reasonableAspectRatio &&
        reasonableSize;
  }

  Future<void> _processChallenge(Face face) async {
    // Safety check: if already completed, don't process
    if (_currentChallengeIndex >= _challenges.length) {
      await _completeVerification();
      return;
    }

    if (_waitingForNeutral) {
      if (_challengeValidator.isNeutralPosition(face)) {
        _waitingForNeutral = false;
        _isInTurnChallenge = false;
      }
      return;
    }

    // Safety check: ensure challenge index is valid
    if (_currentChallengeIndex < 0 ||
        _currentChallengeIndex >= _challenges.length) {
      return;
    }

    final challenge = _challenges[_currentChallengeIndex];
    _updateTurnChallengeState(challenge);
    _challengeStartTimes[challenge] ??= DateTime.now();

    final elapsed = DateTime.now().difference(_challengeStartTimes[challenge]!);
    if (elapsed > _config.challengeTimeout) {
      _challengeStartTimes.remove(challenge);
      _isInTurnChallenge = false;
      return;
    }

    _updateState(LivenessState.challengeInProgress(
      challenge: challenge,
      challengeIndex: _currentChallengeIndex,
      totalChallenges: _challenges.length,
    ));

    if (_challengeValidator.validateChallenge(face, challenge)) {
      await _completeChallenge(challenge, elapsed);
    }
  }

  void _updateTurnChallengeState(ChallengeType challenge) {
    switch (challenge) {
      case ChallengeType.turnLeft:
      case ChallengeType.turnRight:
        _isInTurnChallenge = true;
        break;
      default:
        if (!_waitingForNeutral) {
          _isInTurnChallenge = false;
        }
        break;
    }
  }

  Future<void> _completeChallenge(
      ChallengeType challenge, Duration elapsed) async {
    _challengeCompletionTimes[challenge] = elapsed;
    _currentChallengeIndex++;

    if (_currentChallengeIndex >= _challenges.length) {
      await _completeVerification();
    } else {
      final nextChallenge = _challenges[_currentChallengeIndex];
      _updateState(LivenessState.challengeCompleted(
        completed: challenge,
        next: nextChallenge,
        challengeIndex: _currentChallengeIndex,
        totalChallenges: _challenges.length,
      ));

      if (_config.requireNeutralPosition) {
        _waitingForNeutral = true;
      }
    }
  }

  Future<void> _completeVerification() async {
    // Prevent multiple calls
    if (_currentChallengeIndex > _challenges.length) {
      return;
    }

    // Stop detection to prevent further frame processing
    await stop();

    final totalTime = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    // Safely get completed challenges
    final completedChallenges = _currentChallengeIndex > 0
        ? _challenges.take(_currentChallengeIndex).toList()
        : <ChallengeType>[];

    final result = LivenessResult.success(
      completedChallenges: completedChallenges,
      totalTime: totalTime,
      challengeTimes: _challengeCompletionTimes,
      confidenceScore: 1.0,
      attemptCount: _attemptCount,
    );

    _updateState(LivenessState.completed(result));
  }

  void _updateState(LivenessState state) {
    _stateController.add(state);
  }

  /// Disposes all resources and stops detection.
  ///
  /// Always call this when done with the detector to free resources.
  Future<void> dispose() async {
    await stop();
    await _cameraManager.dispose();
    await _faceDetector.close();
    _spoofingDetector?.dispose();
    await _stateController.close();
  }
}
