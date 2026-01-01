import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

void main() {
  group('LivenessState', () {
    test('should create initialized state', () {
      final state = LivenessState.initialized();
      expect(state.type, LivenessStateType.initialized);
      expect(state.face, isNull);
      expect(state.result, isNull);
      expect(state.error, isNull);
    });

    test('should create detecting state', () {
      final state = LivenessState.detecting();
      expect(state.type, LivenessStateType.detecting);
    });

    test('should create noFace state with message', () {
      final state = LivenessState.noFace('No face detected');
      expect(state.type, LivenessStateType.noFace);
      expect(state.message, 'No face detected');
    });

    test('should create challengeInProgress state', () {
      final state = LivenessState.challengeInProgress(
        challenge: ChallengeType.smile,
        challengeIndex: 0,
        totalChallenges: 3,
      );
      expect(state.type, LivenessStateType.challengeInProgress);
      expect(state.currentChallenge, ChallengeType.smile);
      expect(state.challengeIndex, 0);
      expect(state.totalChallenges, 3);
    });

    test('should create completed state', () {
      final result = LivenessResult.success(
        completedChallenges: [ChallengeType.smile],
        totalTime: const Duration(seconds: 5),
        challengeTimes: {},
        confidenceScore: 1.0,
      );
      final state = LivenessState.completed(result);
      expect(state.type, LivenessStateType.completed);
      expect(state.result, result);
    });

    test('should create error state', () {
      final error = LivenessError.generic(message: 'Test error');
      final state = LivenessState.error(error);
      expect(state.type, LivenessStateType.error);
      expect(state.error, error);
    });

    group('equality', () {
      test('should be equal when values are same', () {
        final state1 = LivenessState.initialized();
        final state2 = LivenessState.initialized();
        expect(state1 == state2, isTrue);
        expect(state1.hashCode, state2.hashCode);
      });

      test('should not be equal when types differ', () {
        final state1 = LivenessState.initialized();
        final state2 = LivenessState.detecting();
        expect(state1 == state2, isFalse);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final state = LivenessState.challengeInProgress(
          challenge: ChallengeType.smile,
          challengeIndex: 1,
          totalChallenges: 3,
        );
        final str = state.toString();
        expect(str, contains('LivenessState'));
        expect(str, contains('challengeIndex: 1'));
        expect(str, contains('totalChallenges: 3'));
      });
    });
  });
}

