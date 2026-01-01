import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/challenges/challenges.dart';

/// Configuration for facial liveness verification.
///
/// All parameters have sensible defaults. Customize only what you need.
class LivenessConfig {
  final List<ChallengeType> challenges;
  final bool shuffleChallenges;
  final bool enableAntiSpoofing;
  final Duration sessionTimeout;
  final Duration challengeTimeout;
  final int maxAttempts;
  final ResolutionPreset cameraResolution;
  final FaceDetectorMode detectorMode;
  final int frameSkipRate;
  final double smileThreshold;
  final double eyeOpenThreshold;
  final double headAngleThreshold;
  final double centerTolerance;
  final double minFaceSize;
  final double maxFaceSize;
  final double maxHeadAngle;
  final bool requireNeutralPosition;
  final double minMotionVariance;
  final double maxStaticFrames;
  final double minDepthVariation;
  final int minVerificationTime;
  final int maxHistoryLength;
  final bool enableStabilityBuffer;
  final Duration stabilityGracePeriod;
  final int stabilityGoodFrameCount;
  final int stabilityBadFrameCount;

  const LivenessConfig({
    this.challenges = const [
      ChallengeType.smile,
      ChallengeType.blink,
      ChallengeType.turnLeft,
      ChallengeType.turnRight,
    ],
    this.shuffleChallenges = true,
    this.enableAntiSpoofing = true,
    this.sessionTimeout = const Duration(minutes: 5),
    this.challengeTimeout = const Duration(seconds: 20),
    this.maxAttempts = 3,
    this.cameraResolution = ResolutionPreset.medium,
    this.detectorMode = FaceDetectorMode.accurate,
    this.frameSkipRate = 2,
    this.smileThreshold = 0.55,
    this.eyeOpenThreshold = 0.35,
    this.headAngleThreshold = 18.0,
    this.centerTolerance = 0.3,
    this.minFaceSize = 0.15,
    this.maxFaceSize = 0.95,
    this.maxHeadAngle = 22.0,
    this.requireNeutralPosition = true,
    this.minMotionVariance = 0.3,
    this.maxStaticFrames = 0.8,
    this.minDepthVariation = 0.015,
    this.minVerificationTime = 2,
    this.maxHistoryLength = 30,
    this.enableStabilityBuffer = true,
    this.stabilityGracePeriod = const Duration(milliseconds: 1500),
    this.stabilityGoodFrameCount = 3,
    this.stabilityBadFrameCount = 5,
  });
}
