import 'package:facial_liveness_verification/src/challenges/challenges.dart';

/// Result of a liveness verification session.
class LivenessResult {
  final bool isVerified;
  final List<ChallengeType> completedChallenges;
  final Duration totalTime;
  final Map<ChallengeType, Duration> challengeTimes;
  final double confidenceScore;
  final int attemptCount;
  final String? failureReason;

  const LivenessResult({
    required this.isVerified,
    required this.completedChallenges,
    required this.totalTime,
    required this.challengeTimes,
    required this.confidenceScore,
    this.attemptCount = 1,
    this.failureReason,
  });

  /// Creates a successful verification result.
  factory LivenessResult.success({
    required List<ChallengeType> completedChallenges,
    required Duration totalTime,
    required Map<ChallengeType, Duration> challengeTimes,
    required double confidenceScore,
    int attemptCount = 1,
  }) {
    return LivenessResult(
      isVerified: true,
      completedChallenges: completedChallenges,
      totalTime: totalTime,
      challengeTimes: challengeTimes,
      confidenceScore: confidenceScore,
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
    int attemptCount = 1,
  }) {
    return LivenessResult(
      isVerified: false,
      completedChallenges: completedChallenges,
      totalTime: totalTime,
      challengeTimes: challengeTimes,
      confidenceScore: confidenceScore,
      attemptCount: attemptCount,
      failureReason: reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LivenessResult) return false;
    if (other.isVerified != isVerified) return false;
    if (other.completedChallenges.length != completedChallenges.length) return false;
    for (var i = 0; i < completedChallenges.length; i++) {
      if (other.completedChallenges[i] != completedChallenges[i]) return false;
    }
    if (other.totalTime != totalTime) return false;
    if (other.challengeTimes.length != challengeTimes.length) return false;
    for (var entry in challengeTimes.entries) {
      if (other.challengeTimes[entry.key] != entry.value) return false;
    }
    if (other.confidenceScore != confidenceScore) return false;
    if (other.attemptCount != attemptCount) return false;
    if (other.failureReason != failureReason) return false;
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      isVerified,
      completedChallenges,
      totalTime,
      challengeTimes,
      confidenceScore,
      attemptCount,
      failureReason,
    );
  }

  @override
  String toString() {
    return 'LivenessResult(isVerified: $isVerified, '
        'completedChallenges: $completedChallenges, '
        'totalTime: $totalTime, confidenceScore: $confidenceScore)';
  }
}
