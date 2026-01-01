import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/challenges/challenges.dart';
import 'result.dart';
import 'error.dart';

/// Represents the current state of the liveness detection process.
///
/// Emitted via [LivenessDetector.stateStream] to notify listeners of state changes.
class LivenessState {
  final LivenessStateType type;
  final Face? face;
  final LivenessResult? result;
  final LivenessError? error;
  final String? message;
  final ChallengeType? currentChallenge;
  final ChallengeType? completedChallenge;
  final int challengeIndex;
  final int totalChallenges;

  const LivenessState._({
    required this.type,
    this.face,
    this.result,
    this.error,
    this.message,
    this.currentChallenge,
    this.completedChallenge,
    this.challengeIndex = 0,
    this.totalChallenges = 0,
  });

  factory LivenessState.initialized() =>
      const LivenessState._(type: LivenessStateType.initialized);

  factory LivenessState.detecting() =>
      const LivenessState._(type: LivenessStateType.detecting);

  factory LivenessState.noFace([String? message]) =>
      LivenessState._(type: LivenessStateType.noFace, message: message);

  factory LivenessState.faceDetected(Face face) =>
      LivenessState._(type: LivenessStateType.faceDetected, face: face);

  factory LivenessState.positioning(Face face, [String? message]) =>
      LivenessState._(
        type: LivenessStateType.positioning,
        face: face,
        message: message,
      );

  factory LivenessState.positioned(Face face, [String? message]) =>
      LivenessState._(
        type: LivenessStateType.positioned,
        face: face,
        message: message,
      );

  factory LivenessState.challengeInProgress({
    required ChallengeType challenge,
    required int challengeIndex,
    required int totalChallenges,
  }) =>
      LivenessState._(
        type: LivenessStateType.challengeInProgress,
        currentChallenge: challenge,
        challengeIndex: challengeIndex,
        totalChallenges: totalChallenges,
      );

  factory LivenessState.challengeCompleted({
    required ChallengeType completed,
    required ChallengeType? next,
    required int challengeIndex,
    required int totalChallenges,
  }) =>
      LivenessState._(
        type: LivenessStateType.challengeCompleted,
        completedChallenge: completed,
        currentChallenge: next,
        challengeIndex: challengeIndex,
        totalChallenges: totalChallenges,
      );

  factory LivenessState.completed(LivenessResult result) =>
      LivenessState._(type: LivenessStateType.completed, result: result);

  factory LivenessState.error(LivenessError error) =>
      LivenessState._(type: LivenessStateType.error, error: error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LivenessState &&
        other.type == type &&
        other.face == face &&
        other.result == result &&
        other.error == error &&
        other.message == message &&
        other.currentChallenge == currentChallenge &&
        other.completedChallenge == completedChallenge &&
        other.challengeIndex == challengeIndex &&
        other.totalChallenges == totalChallenges;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      face,
      result,
      error,
      message,
      currentChallenge,
      completedChallenge,
      challengeIndex,
      totalChallenges,
    );
  }

  @override
  String toString() {
    return 'LivenessState(type: $type, challengeIndex: $challengeIndex, '
        'totalChallenges: $totalChallenges)';
  }
}

/// Types of states emitted during liveness verification.
enum LivenessStateType {
  initialized,
  detecting,
  noFace,
  faceDetected,
  positioning,
  positioned,
  challengeInProgress,
  challengeCompleted,
  completed,
  error,
}
