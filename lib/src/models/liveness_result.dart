import 'challenge_types.dart';

/// Result of a liveness detection session.
///
/// Contains information about whether the verification was successful,
/// details about completed challenges, and timing information.
class LivenessResult {
  /// Whether the liveness verification was successful.
  final bool isVerified;

  /// List of challenges that were completed successfully.
  final List<ChallengeType> completedChallenges;

  /// Total time taken for the verification session.
  final Duration totalTime;

  /// Individual challenge completion times.
  final Map<ChallengeType, Duration> challengeTimes;

  /// Confidence score for the liveness detection (0.0 to 1.0).
  /// Higher values indicate higher confidence in the result.
  final double confidenceScore;

  /// Anti-spoofing analysis result.
  final AntiSpoofingResult antiSpoofingResult;

  /// Any additional metadata from the verification session.
  final Map<String, dynamic> metadata;

  /// Reason for verification failure (if applicable).
  final String? failureReason;

  /// Number of attempts made during this session.
  final int attemptCount;

  /// Creates a new [LivenessResult].
  const LivenessResult({
    required this.isVerified,
    required this.completedChallenges,
    required this.totalTime,
    required this.challengeTimes,
    required this.confidenceScore,
    required this.antiSpoofingResult,
    this.metadata = const {},
    this.failureReason,
    this.attemptCount = 1,
  });

  /// Creates a successful verification result.
  factory LivenessResult.success({
    required List<ChallengeType> completedChallenges,
    required Duration totalTime,
    required Map<ChallengeType, Duration> challengeTimes,
    required double confidenceScore,
    required AntiSpoofingResult antiSpoofingResult,
    Map<String, dynamic> metadata = const {},
    int attemptCount = 1,
  }) {
    return LivenessResult(
      isVerified: true,
      completedChallenges: completedChallenges,
      totalTime: totalTime,
      challengeTimes: challengeTimes,
      confidenceScore: confidenceScore,
      antiSpoofingResult: antiSpoofingResult,
      metadata: metadata,
      attemptCount: attemptCount,
    );
  }

  /// Creates a failed verification result.
  factory LivenessResult.failure({
    required String reason,
    List<ChallengeType> completedChallenges = const [],
    Duration totalTime = Duration.zero,
    Map<ChallengeType, Duration> challengeTimes = const {},
    double confidenceScore = 0.0,
    AntiSpoofingResult? antiSpoofingResult,
    Map<String, dynamic> metadata = const {},
    int attemptCount = 1,
  }) {
    return LivenessResult(
      isVerified: false,
      completedChallenges: completedChallenges,
      totalTime: totalTime,
      challengeTimes: challengeTimes,
      confidenceScore: confidenceScore,
      antiSpoofingResult: antiSpoofingResult ?? const AntiSpoofingResult.failed('Verification failed'),
      metadata: metadata,
      failureReason: reason,
      attemptCount: attemptCount,
    );
  }

  /// Converts the result to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'isVerified': isVerified,
      'completedChallenges': completedChallenges.map((c) => c.actionName).toList(),
      'totalTime': totalTime.inMilliseconds,
      'challengeTimes': challengeTimes.map((key, value) => MapEntry(key.actionName, value.inMilliseconds)),
      'confidenceScore': confidenceScore,
      'antiSpoofingResult': antiSpoofingResult.toJson(),
      'metadata': metadata,
      'failureReason': failureReason,
      'attemptCount': attemptCount,
    };
  }

  /// Creates a result from a JSON representation.
  factory LivenessResult.fromJson(Map<String, dynamic> json) {
    final challengeNames = (json['completedChallenges'] as List<String>?) ?? [];
    final completedChallenges = challengeNames
        .map((name) => ChallengeType.values.firstWhere((c) => c.actionName == name))
        .toList();

    final challengeTimesMap = (json['challengeTimes'] as Map<String, dynamic>?) ?? {};
    final challengeTimes = <ChallengeType, Duration>{};
    for (final entry in challengeTimesMap.entries) {
      final challenge = ChallengeType.values.firstWhere((c) => c.actionName == entry.key);
      challengeTimes[challenge] = Duration(milliseconds: entry.value as int);
    }

    return LivenessResult(
      isVerified: json['isVerified'] as bool,
      completedChallenges: completedChallenges,
      totalTime: Duration(milliseconds: json['totalTime'] as int),
      challengeTimes: challengeTimes,
      confidenceScore: json['confidenceScore'] as double,
      antiSpoofingResult: AntiSpoofingResult.fromJson(json['antiSpoofingResult']),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      failureReason: json['failureReason'] as String?,
      attemptCount: json['attemptCount'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'LivenessResult(isVerified: $isVerified, completedChallenges: $completedChallenges, '
        'totalTime: $totalTime, confidenceScore: $confidenceScore, failureReason: $failureReason)';
  }
}

/// Result of anti-spoofing analysis.
class AntiSpoofingResult {
  /// Whether the analysis indicates a live person (true) or potential spoofing attempt (false).
  final bool isLive;

  /// Confidence score for the liveness determination (0.0 to 1.0).
  final double confidence;

  /// Detailed reason for the determination.
  final String reason;

  /// Motion analysis metrics.
  final MotionAnalysis motionAnalysis;

  /// Depth variation analysis metrics.
  final DepthAnalysis depthAnalysis;

  /// Timing analysis metrics.
  final TimingAnalysis timingAnalysis;

  const AntiSpoofingResult({
    required this.isLive,
    required this.confidence,
    required this.reason,
    required this.motionAnalysis,
    required this.depthAnalysis,
    required this.timingAnalysis,
  });

  /// Creates a successful anti-spoofing result indicating a live person.
  factory AntiSpoofingResult.live({
    double confidence = 1.0,
    String reason = 'Live person detected',
    required MotionAnalysis motionAnalysis,
    required DepthAnalysis depthAnalysis,
    required TimingAnalysis timingAnalysis,
  }) {
    return AntiSpoofingResult(
      isLive: true,
      confidence: confidence,
      reason: reason,
      motionAnalysis: motionAnalysis,
      depthAnalysis: depthAnalysis,
      timingAnalysis: timingAnalysis,
    );
  }

  /// Creates a failed anti-spoofing result indicating potential spoofing.
  const factory AntiSpoofingResult.failed(String reason) = _FailedAntiSpoofingResult;

  /// Converts to JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'isLive': isLive,
      'confidence': confidence,
      'reason': reason,
      'motionAnalysis': motionAnalysis.toJson(),
      'depthAnalysis': depthAnalysis.toJson(),
      'timingAnalysis': timingAnalysis.toJson(),
    };
  }

  /// Creates from JSON representation.
  factory AntiSpoofingResult.fromJson(Map<String, dynamic> json) {
    return AntiSpoofingResult(
      isLive: json['isLive'] as bool,
      confidence: json['confidence'] as double,
      reason: json['reason'] as String,
      motionAnalysis: MotionAnalysis.fromJson(json['motionAnalysis']),
      depthAnalysis: DepthAnalysis.fromJson(json['depthAnalysis']),
      timingAnalysis: TimingAnalysis.fromJson(json['timingAnalysis']),
    );
  }
}

class _FailedAntiSpoofingResult implements AntiSpoofingResult {
  @override
  final bool isLive = false;

  @override
  final double confidence = 0.0;

  @override
  final String reason;

  @override
  final MotionAnalysis motionAnalysis = const MotionAnalysis.failed();

  @override
  final DepthAnalysis depthAnalysis = const DepthAnalysis.failed();

  @override
  final TimingAnalysis timingAnalysis = const TimingAnalysis.failed();

  const _FailedAntiSpoofingResult(this.reason);

  @override
  Map<String, dynamic> toJson() {
    return {
      'isLive': isLive,
      'confidence': confidence,
      'reason': reason,
      'motionAnalysis': motionAnalysis.toJson(),
      'depthAnalysis': depthAnalysis.toJson(),
      'timingAnalysis': timingAnalysis.toJson(),
    };
  }
}

/// Motion analysis metrics from anti-spoofing detection.
class MotionAnalysis {
  /// Variance in head movement over the analysis period.
  final double motionVariance;

  /// Ratio of static frames to total frames analyzed.
  final double staticFrameRatio;

  /// Whether the motion analysis passed the threshold.
  final bool passed;

  const MotionAnalysis({
    required this.motionVariance,
    required this.staticFrameRatio,
    required this.passed,
  });

  const MotionAnalysis.failed() : motionVariance = 0.0, staticFrameRatio = 1.0, passed = false;

  Map<String, dynamic> toJson() => {
    'motionVariance': motionVariance,
    'staticFrameRatio': staticFrameRatio,
    'passed': passed,
  };

  factory MotionAnalysis.fromJson(Map<String, dynamic> json) => MotionAnalysis(
    motionVariance: json['motionVariance'] as double,
    staticFrameRatio: json['staticFrameRatio'] as double,
    passed: json['passed'] as bool,
  );
}

/// Depth analysis metrics from anti-spoofing detection.
class DepthAnalysis {
  /// Variation in face size indicating depth changes.
  final double sizeVariation;

  /// Minimum face size observed.
  final double minSize;

  /// Maximum face size observed.
  final double maxSize;

  /// Whether the depth analysis passed the threshold.
  final bool passed;

  const DepthAnalysis({
    required this.sizeVariation,
    required this.minSize,
    required this.maxSize,
    required this.passed,
  });

  const DepthAnalysis.failed() : sizeVariation = 0.0, minSize = 0.0, maxSize = 0.0, passed = false;

  Map<String, dynamic> toJson() => {
    'sizeVariation': sizeVariation,
    'minSize': minSize,
    'maxSize': maxSize,
    'passed': passed,
  };

  factory DepthAnalysis.fromJson(Map<String, dynamic> json) => DepthAnalysis(
    sizeVariation: json['sizeVariation'] as double,
    minSize: json['minSize'] as double,
    maxSize: json['maxSize'] as double,
    passed: json['passed'] as bool,
  );
}

/// Timing analysis metrics from anti-spoofing detection.
class TimingAnalysis {
  /// Total verification time in milliseconds.
  final int totalTime;

  /// Minimum time required for verification.
  final int minimumTime;

  /// Whether the timing analysis passed the threshold.
  final bool passed;

  const TimingAnalysis({
    required this.totalTime,
    required this.minimumTime,
    required this.passed,
  });

  const TimingAnalysis.failed() : totalTime = 0, minimumTime = 0, passed = false;

  Map<String, dynamic> toJson() => {
    'totalTime': totalTime,
    'minimumTime': minimumTime,
    'passed': passed,
  };

  factory TimingAnalysis.fromJson(Map<String, dynamic> json) => TimingAnalysis(
    totalTime: json['totalTime'] as int,
    minimumTime: json['minimumTime'] as int,
    passed: json['passed'] as bool,
  );
}