/// Constants used throughout the liveness detection package.
library;

/// Default configuration values.
class LivenessDefaults {
  // Prevent instantiation
  const LivenessDefaults._();

  /// Default session timeout duration.
  static const Duration sessionTimeout = Duration(minutes: 5);

  /// Default challenge timeout duration.
  static const Duration challengeTimeout = Duration(seconds: 20);

  /// Default maximum attempts allowed.
  static const int maxAttempts = 3;

  /// Default frame skip rate for performance optimization.
  static const int frameSkipRate = 2;

  /// Default minimum face size ratio.
  static const double minFaceSize = 0.2;

  /// Default maximum face size ratio.
  static const double maxFaceSize = 0.85;

  /// Default center tolerance for face positioning.
  static const double centerTolerance = 0.2;

  /// Default angle tolerance for head positioning.
  static const double angleTolerance = 18.0;

  /// Default guide circle radius ratio.
  static const double guideCircleRadius = 0.35;
}

/// Detection thresholds for various facial features.
class DetectionThresholds {
  // Prevent instantiation
  const DetectionThresholds._();

  /// Default smile detection threshold.
  static const double smile = 0.55;

  /// Default eye open threshold for blink detection.
  static const double eyeOpen = 0.35;

  /// Default head angle threshold for turn detection.
  static const double headAngle = 18.0;

  /// Default neutral position thresholds.
  static const double neutralSmile = 0.35;
  static const double neutralEyeOpen = 0.65;
  static const double neutralHeadAngle = 12.0;
}

/// Anti-spoofing detection parameters.
class AntiSpoofingDefaults {
  // Prevent instantiation
  const AntiSpoofingDefaults._();

  /// Maximum history length for analysis.
  static const int maxHistoryLength = 30;

  /// Minimum history length required for analysis.
  static const int minHistoryForAnalysis = 10;

  /// Minimum motion variance threshold.
  static const double minMotionVariance = 0.3;

  /// Maximum static frames ratio allowed.
  static const double maxStaticFrames = 0.8;

  /// Minimum depth variation threshold.
  static const double minDepthVariation = 0.015;

  /// Minimum verification time in seconds.
  static const int minVerificationTime = 2;
}

/// UI-related constants.
class UIConstants {
  // Prevent instantiation
  const UIConstants._();

  /// Default animation duration for UI transitions.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Default border radius for UI panels.
  static const double borderRadius = 12.0;

  /// Default panel padding.
  static const double panelPadding = 16.0;

  /// Default text sizes.
  static const double instructionTextSize = 16.0;
  static const double challengeTextSize = 18.0;
  static const double statusTextSize = 14.0;
  static const double progressTextSize = 14.0;

  /// Default icon sizes.
  static const double statusIconSize = 20.0;
  static const double progressIndicatorSize = 12.0;

  /// Default spacing values.
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 20.0;

  /// Face guide positioning.
  static const double guideCircleOffset = -50.0; // Offset from screen center
  static const double faceBoundingBoxStrokeWidth = 3.0;
  static const double guideCircleStrokeWidth = 4.0;
  static const double cornerGuideLength = 25.0;
  static const double cornerIndicatorLength = 15.0;
}

/// Performance-related constants.
class PerformanceConstants {
  // Prevent instantiation
  const PerformanceConstants._();

  /// Memory management settings.
  static const int maxFaceHistoryEntries = 30;
  static const int maxSizeTrackingEntries = 15;
  static const int memoryCleanupInterval = 30; // frames

  /// Frame processing settings.
  static const int defaultFrameSkipRate = 2;
  static const int lowEndDeviceFrameSkipRate = 4;
  static const int highEndDeviceFrameSkipRate = 1;

  /// Timing thresholds.
  static const int frameProcessingTimeoutMs = 100;
  static const int maxFrameProcessingTimeMs = 500;

  /// Device classification thresholds.
  static const int minAndroidSdkForHighEnd = 30;
  static const int minMemoryMbForHighEnd = 4096;
}

/// Error message templates.
class ErrorMessages {
  // Prevent instantiation
  const ErrorMessages._();

  /// Camera-related error messages.
  static const String cameraInitFailed = 'Failed to initialize camera';
  static const String cameraNotAvailable = 'No cameras available on this device';
  static const String cameraPermissionDenied = 'Camera permission is required for verification';

  /// Face detection error messages.
  static const String faceDetectionFailed = 'Face detection failed';
  static const String noFaceDetected = 'No face detected - please position your face in view';
  static const String multipleFacesDetected = 'Multiple faces detected - ensure only one person is in frame';

  /// Verification error messages.
  static const String verificationTimeout = 'Verification timed out - please try again';
  static const String maxAttemptsReached = 'Maximum verification attempts reached';
  static const String antiSpoofingFailed = 'Liveness verification failed - please ensure you are a real person';

  /// Configuration error messages.
  static const String invalidConfiguration = 'Invalid configuration provided';
  static const String unsupportedChallengeType = 'Unsupported challenge type specified';
  static const String invalidThreshold = 'Invalid threshold value provided';

  /// Generic error messages.
  static const String unknownError = 'An unknown error occurred';
  static const String deviceNotSupported = 'This device is not supported';
  static const String userCancelled = 'Verification was cancelled by user';
}

/// Success message templates.
class SuccessMessages {
  // Prevent instantiation
  const SuccessMessages._();

  /// Verification success messages.
  static const String verificationComplete = '🎉 Liveness verified successfully! 🎉';
  static const String challengeCompleted = 'Great job! Challenge completed successfully! 🎉';
  static const String facePositioned = 'Perfect! You\'re all set for verification! ✨';

  /// Progress messages.
  static const String faceDetected = 'Face detected ✓';
  static const String positionCorrect = 'Position is correct ✓';
  static const String readyForChallenge = 'Ready for challenge ✓';
}

/// Analytics event names.
class AnalyticsEvents {
  // Prevent instantiation
  const AnalyticsEvents._();

  /// Session events.
  static const String sessionStarted = 'liveness_session_started';
  static const String sessionCompleted = 'liveness_session_completed';
  static const String sessionFailed = 'liveness_session_failed';
  static const String sessionTimeout = 'liveness_session_timeout';
  static const String sessionCancelled = 'liveness_session_cancelled';

  /// Challenge events.
  static const String challengeStarted = 'liveness_challenge_started';
  static const String challengeCompleted = 'liveness_challenge_completed';
  static const String challengeFailed = 'liveness_challenge_failed';
  static const String challengeTimeout = 'liveness_challenge_timeout';

  /// Detection events.
  static const String faceDetected = 'face_detected';
  static const String faceLost = 'face_lost';
  static const String positioningCompleted = 'positioning_completed';
  static const String antiSpoofingTriggered = 'anti_spoofing_triggered';

  /// Error events.
  static const String cameraError = 'camera_error';
  static const String permissionDenied = 'permission_denied';
  static const String detectionError = 'detection_error';
  static const String configurationError = 'configuration_error';
}

/// Package metadata.
class PackageInfo {
  // Prevent instantiation
  const PackageInfo._();

  /// Package name.
  static const String name = 'facial_liveness_detection';

  /// Package version.
  static const String version = '1.0.0';

  /// Package description.
  static const String description = 'Advanced facial liveness detection with anti-spoofing protection';

  /// Minimum Flutter version required.
  static const String minFlutterVersion = '3.19.0';

  /// Supported platforms.
  static const List<String> supportedPlatforms = ['android', 'ios', 'windows', 'macos', 'linux'];
}