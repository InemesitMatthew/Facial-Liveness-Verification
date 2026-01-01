import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

void main() {
  group('LivenessResult', () {
    test('should create success result', () {
      final result = LivenessResult.success(
        completedChallenges: [ChallengeType.smile, ChallengeType.blink],
        totalTime: const Duration(seconds: 10),
        challengeTimes: {
          ChallengeType.smile: const Duration(seconds: 3),
          ChallengeType.blink: const Duration(seconds: 2),
        },
        confidenceScore: 0.95,
        attemptCount: 1,
      );

      expect(result.isVerified, isTrue);
      expect(result.completedChallenges.length, 2);
      expect(result.totalTime, const Duration(seconds: 10));
      expect(result.confidenceScore, 0.95);
      expect(result.attemptCount, 1);
      expect(result.failureReason, isNull);
    });

    test('should create failure result', () {
      final result = LivenessResult.failure(
        reason: 'Timeout',
        completedChallenges: [ChallengeType.smile],
        totalTime: const Duration(seconds: 5),
        challengeTimes: {},
        confidenceScore: 0.3,
        attemptCount: 2,
      );

      expect(result.isVerified, isFalse);
      expect(result.failureReason, 'Timeout');
      expect(result.completedChallenges.length, 1);
      expect(result.confidenceScore, 0.3);
      expect(result.attemptCount, 2);
    });

    group('equality', () {
      test('should be equal when values are same', () {
        final challengeTimes1 = <ChallengeType, Duration>{
          ChallengeType.smile: const Duration(seconds: 2),
        };
        final challengeTimes2 = <ChallengeType, Duration>{
          ChallengeType.smile: const Duration(seconds: 2),
        };
        final result1 = LivenessResult.success(
          completedChallenges: [ChallengeType.smile],
          totalTime: const Duration(seconds: 5),
          challengeTimes: challengeTimes1,
          confidenceScore: 1.0,
        );
        final result2 = LivenessResult.success(
          completedChallenges: [ChallengeType.smile],
          totalTime: const Duration(seconds: 5),
          challengeTimes: challengeTimes2,
          confidenceScore: 1.0,
        );

        expect(result1.completedChallenges, result2.completedChallenges);
        expect(result1.totalTime, result2.totalTime);
        expect(result1.challengeTimes, result2.challengeTimes);
        expect(result1.confidenceScore, result2.confidenceScore);
        expect(result1 == result2, isTrue);
      });

      test('should not be equal when values differ', () {
        final result1 = LivenessResult.success(
          completedChallenges: [ChallengeType.smile],
          totalTime: const Duration(seconds: 5),
          challengeTimes: {},
          confidenceScore: 1.0,
        );
        final result2 = LivenessResult.success(
          completedChallenges: [ChallengeType.blink],
          totalTime: const Duration(seconds: 5),
          challengeTimes: {},
          confidenceScore: 1.0,
        );

        expect(result1 == result2, isFalse);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final result = LivenessResult.success(
          completedChallenges: [ChallengeType.smile],
          totalTime: const Duration(seconds: 5),
          challengeTimes: {},
          confidenceScore: 0.9,
        );

        final str = result.toString();
        expect(str, contains('LivenessResult'));
        expect(str, contains('isVerified: true'));
        expect(str, contains('confidenceScore: 0.9'));
      });
    });
  });
}

