import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'challenge_types.dart';
import 'liveness_theme.dart';

/// Configuration class for customizing liveness detection behavior.
///
/// This class allows developers to configure all aspects of the liveness detection
/// including challenges, thresholds, timeouts, UI appearance, and performance settings.
class LivenessConfig {
  /// List of challenges the user must complete to verify liveness.
  /// Default includes smile, blink, turn left, and turn right.
  final List<ChallengeType> challengeTypes;

  /// UI theme configuration for customizing appearance.
  final LivenessTheme theme;

  /// Whether to shuffle the order of challenges to prevent predictable patterns.
  /// Default is true for security.
  final bool shuffleChallenges;

  /// Whether to enable advanced anti-spoofing detection.
  /// Default is true for maximum security.
  final bool enableAntiSpoofing;

  /// Maximum time allowed for the entire liveness detection session.
  /// Default is 5 minutes.
  final Duration sessionTimeout;

  /// Maximum time allowed for each individual challenge.
  /// Default is 20 seconds.
  final Duration challengeTimeout;

  /// Maximum number of attempts allowed before failing the verification.
  /// Default is 3 attempts.
  final int maxAttempts;

  /// Camera resolution preset for face detection.
  /// Default is medium for balanced performance and accuracy.
  final ResolutionPreset cameraResolution;

  /// Face detector performance mode.
  /// Default is accurate for better detection quality.
  final FaceDetectorMode detectorMode;

  /// Frame skip rate for performance optimization.
  /// Higher values process fewer frames but use less CPU.
  /// Default is 2 (process every 2nd frame).
  final int frameSkipRate;

  /// Detection thresholds for various facial features.
  final DetectionThresholds thresholds;

  /// Anti-spoofing sensitivity configuration.
  final AntiSpoofingConfig antiSpoofing;

  /// Face positioning and size constraints.
  final FaceConstraints faceConstraints;

  /// Whether to require the user to return to neutral position between challenges.
  /// Default is true for better verification quality.
  final bool requireNeutralPosition;

  /// Custom instruction messages for different states.
  final InstructionMessages? customMessages;

  /// Creates a new [LivenessConfig] with the specified settings.
  LivenessConfig({
    this.challengeTypes = const [
      ChallengeType.smile,
      ChallengeType.blink,
      ChallengeType.turnLeft,
      ChallengeType.turnRight,
    ],
    LivenessTheme? theme,
    this.shuffleChallenges = true,
    this.enableAntiSpoofing = true,
    this.sessionTimeout = const Duration(minutes: 5),
    this.challengeTimeout = const Duration(seconds: 20),
    this.maxAttempts = 3,
    this.cameraResolution = ResolutionPreset.medium,
    this.detectorMode = FaceDetectorMode.accurate,
    this.frameSkipRate = 2,
    this.thresholds = const DetectionThresholds(),
    this.antiSpoofing = const AntiSpoofingConfig(),
    this.faceConstraints = const FaceConstraints(),
    this.requireNeutralPosition = true,
    this.customMessages,
  }) : theme = theme ?? LivenessTheme.dark();

  /// Creates a basic configuration optimized for quick verification.
  /// Uses fewer challenges and relaxed thresholds for faster completion.
  factory LivenessConfig.basic() {
    return LivenessConfig(
      challengeTypes: [ChallengeType.smile, ChallengeType.blink],
      sessionTimeout: Duration(minutes: 2),
      challengeTimeout: Duration(seconds: 15),
      frameSkipRate: 3,
      detectorMode: FaceDetectorMode.fast,
      thresholds: DetectionThresholds(
        smileThreshold: 0.5,
        eyeOpenThreshold: 0.4,
        headAngleThreshold: 15.0,
      ),
    );
  }

  /// Creates a configuration optimized for high security environments.
  /// Uses all available challenges and strict thresholds.
  factory LivenessConfig.secure() {
    return LivenessConfig(
      challengeTypes: [
        ChallengeType.smile,
        ChallengeType.blink,
        ChallengeType.turnLeft,
        ChallengeType.turnRight,
        ChallengeType.nod,
      ],
      sessionTimeout: Duration(minutes: 7),
      challengeTimeout: Duration(seconds: 25),
      frameSkipRate: 1,
      detectorMode: FaceDetectorMode.accurate,
      thresholds: DetectionThresholds(
        smileThreshold: 0.65,
        eyeOpenThreshold: 0.3,
        headAngleThreshold: 20.0,
      ),
      antiSpoofing: AntiSpoofingConfig(
        minMotionVariance: 0.5,
        minDepthVariation: 0.02,
        minVerificationTime: 3,
      ),
    );
  }

  /// Creates a configuration optimized for performance on low-end devices.
  factory LivenessConfig.performance() {
    return LivenessConfig(
      challengeTypes: [ChallengeType.smile, ChallengeType.turnLeft],
      cameraResolution: ResolutionPreset.low,
      detectorMode: FaceDetectorMode.fast,
      frameSkipRate: 4,
      enableAntiSpoofing: false,
      thresholds: DetectionThresholds(
        smileThreshold: 0.4,
        headAngleThreshold: 12.0,
      ),
    );
  }

  /// Creates a minimal configuration for the simplest possible integration.
  /// Just requires a smile - perfect for quick onboarding flows.
  factory LivenessConfig.minimal() {
    return LivenessConfig(
      challengeTypes: [ChallengeType.smile],
      sessionTimeout: Duration(minutes: 1),
      challengeTimeout: Duration(seconds: 8),
      maxAttempts: 1,
      frameSkipRate: 4,
      enableAntiSpoofing: false, // Disable for fastest possible flow
      thresholds: DetectionThresholds(
        smileThreshold: 0.3, // Very relaxed
      ),
    );
  }

  /// Creates a one-click configuration that requires no user interaction.
  /// Just looks at the camera for a few seconds - perfect for passive verification.
  factory LivenessConfig.passive() {
    return LivenessConfig(
      challengeTypes: [], // No challenges required
      sessionTimeout: Duration(seconds: 30),
      challengeTimeout: Duration(seconds: 30),
      maxAttempts: 1,
      frameSkipRate: 2,
      enableAntiSpoofing: true, // Rely on anti-spoofing only
    );
  }
}

/// Threshold values for detecting various facial features and actions.
class DetectionThresholds {
  /// Minimum probability threshold for smile detection (0.0 to 1.0).
  /// Higher values require more obvious smiles.
  final double smileThreshold;

  /// Maximum probability threshold for eye closure during blink detection.
  /// Lower values make blink detection more sensitive.
  final double eyeOpenThreshold;

  /// Minimum head rotation angle in degrees for turn challenges.
  /// Higher values require more pronounced head turns.
  final double headAngleThreshold;

  /// Tolerance for face centering as a percentage of screen size.
  /// Higher values allow more lenient positioning.
  final double centerTolerance;

  const DetectionThresholds({
    this.smileThreshold = 0.55,
    this.eyeOpenThreshold = 0.35,
    this.headAngleThreshold = 18.0,
    this.centerTolerance = 0.2,
  });
}

/// Configuration for anti-spoofing detection parameters.
class AntiSpoofingConfig {
  /// Minimum motion variance required to detect natural movement.
  /// Higher values require more movement to pass verification.
  final double minMotionVariance;

  /// Maximum ratio of static frames allowed in the analysis window.
  /// Lower values require more consistent movement.
  final double maxStaticFrames;

  /// Minimum depth variation (size change) required to detect 3D faces.
  /// Higher values require more pronounced depth changes.
  final double minDepthVariation;

  /// Minimum time required for verification to complete.
  /// Prevents quick attacks using pre-processed content.
  final int minVerificationTime;

  /// Maximum number of face analysis history entries to maintain.
  /// Higher values provide more accurate analysis but use more memory.
  final int maxHistoryLength;

  const AntiSpoofingConfig({
    this.minMotionVariance = 0.3,
    this.maxStaticFrames = 0.8,
    this.minDepthVariation = 0.015,
    this.minVerificationTime = 2,
    this.maxHistoryLength = 30,
  });
}

/// Configuration for face positioning and size constraints.
class FaceConstraints {
  /// Minimum face size as a ratio of the screen area (0.0 to 1.0).
  final double minFaceSize;

  /// Maximum face size as a ratio of the screen area (0.0 to 1.0).
  final double maxFaceSize;

  /// Maximum allowed head angle deviation for "looking straight" detection.
  final double maxHeadAngle;

  /// Radius of the guide circle as a ratio of screen width.
  final double guideCircleRadius;

  const FaceConstraints({
    this.minFaceSize = 0.2,
    this.maxFaceSize = 0.85,
    this.maxHeadAngle = 18.0,
    this.guideCircleRadius = 0.35,
  });
}

/// Custom instruction messages for different states.
class InstructionMessages {
  /// Message shown when no face is detected.
  final String noFaceDetected;

  /// Message shown when face is detected but not positioned correctly.
  final String positionFace;

  /// Message shown when user needs to move closer.
  final String moveCloser;

  /// Message shown when user needs to move farther.
  final String moveFarther;

  /// Message shown when face is correctly positioned.
  final String facePositioned;

  /// Message shown when liveness verification is complete.
  final String verificationComplete;

  /// Message shown when verification fails.
  final String verificationFailed;

  /// Message shown when session times out.
  final String sessionTimeout;

  const InstructionMessages({
    this.noFaceDetected = 'Position your face in the center - we\'ll guide you through this!',
    this.positionFace = 'Please position your face within the guide circle',
    this.moveCloser = 'Move closer to the camera - we need a clear view!',
    this.moveFarther = 'Move back from the camera - you\'re too close!',
    this.facePositioned = 'Perfect! You\'re all set for verification! ✨',
    this.verificationComplete = '🎉 Liveness verified successfully! 🎉',
    this.verificationFailed = 'Verification failed. Please try again.',
    this.sessionTimeout = 'Session timed out. Please start verification again.',
  });
}