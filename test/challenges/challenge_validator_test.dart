import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';
import 'package:facial_liveness_verification/src/core/dependencies.dart';

void main() {
  group('ChallengeValidator', () {
    late ChallengeValidator validator;
    late LivenessConfig config;

    setUp(() {
      config = const LivenessConfig();
      validator = ChallengeValidator(config);
    });

    group('smile validation', () {
      test('should validate smile when probability exceeds threshold', () {
        final mockFace = _createMockFace(smilingProbability: 0.7);
        expect(validator.validateChallenge(mockFace, ChallengeType.smile), isTrue);
      });

      test('should reject smile when probability below threshold', () {
        final mockFace = _createMockFace(smilingProbability: 0.3);
        expect(validator.validateChallenge(mockFace, ChallengeType.smile), isFalse);
      });
    });

    group('blink validation', () {
      test('should detect blink sequence', () {
        final mockFaceClosed = _createMockFace(
          leftEyeOpenProbability: 0.2,
          rightEyeOpenProbability: 0.2,
        );
        final mockFaceOpen = _createMockFace(
          leftEyeOpenProbability: 0.8,
          rightEyeOpenProbability: 0.8,
        );

        expect(validator.validateChallenge(mockFaceClosed, ChallengeType.blink), isFalse);
        expect(validator.validateChallenge(mockFaceOpen, ChallengeType.blink), isTrue);
      });
    });

    group('head turn validation', () {
      test('should validate turn left', () {
        final mockFace = _createMockFace(headEulerAngleY: 25.0);
        expect(validator.validateChallenge(mockFace, ChallengeType.turnLeft), isTrue);
      });

      test('should validate turn right', () {
        final mockFace = _createMockFace(headEulerAngleY: -25.0);
        expect(validator.validateChallenge(mockFace, ChallengeType.turnRight), isTrue);
      });

      test('should reject insufficient turn', () {
        final mockFace = _createMockFace(headEulerAngleY: 10.0);
        expect(validator.validateChallenge(mockFace, ChallengeType.turnLeft), isFalse);
      });
    });

    group('neutral position', () {
      test('should detect neutral position', () {
        final mockFace = _createMockFace(
          smilingProbability: 0.2,
          leftEyeOpenProbability: 0.8,
          rightEyeOpenProbability: 0.8,
          headEulerAngleY: 5.0,
        );
        expect(validator.isNeutralPosition(mockFace), isTrue);
      });

      test('should reject non-neutral position (smiling)', () {
        final mockFace = _createMockFace(
          smilingProbability: 0.6,
          leftEyeOpenProbability: 0.8,
          rightEyeOpenProbability: 0.8,
          headEulerAngleY: 5.0,
        );
        expect(validator.isNeutralPosition(mockFace), isFalse);
      });

      test('should reject non-neutral position (eyes closed)', () {
        final mockFace = _createMockFace(
          smilingProbability: 0.2,
          leftEyeOpenProbability: 0.3,
          rightEyeOpenProbability: 0.3,
          headEulerAngleY: 5.0,
        );
        expect(validator.isNeutralPosition(mockFace), isFalse);
      });

      test('should reject non-neutral position (head turned)', () {
        final mockFace = _createMockFace(
          smilingProbability: 0.2,
          leftEyeOpenProbability: 0.8,
          rightEyeOpenProbability: 0.8,
          headEulerAngleY: 20.0,
        );
        expect(validator.isNeutralPosition(mockFace), isFalse);
      });
    });

    group('reset', () {
      test('should reset internal state', () {
        final mockFaceClosed = _createMockFace(
          leftEyeOpenProbability: 0.2,
          rightEyeOpenProbability: 0.2,
        );
        final mockFaceOpen = _createMockFace(
          leftEyeOpenProbability: 0.8,
          rightEyeOpenProbability: 0.8,
        );

        validator.validateChallenge(mockFaceClosed, ChallengeType.blink);
        validator.reset();
        expect(validator.validateChallenge(mockFaceOpen, ChallengeType.blink), isFalse);
      });
    });
  });
}

Face _createMockFace({
  double? smilingProbability,
  double? leftEyeOpenProbability,
  double? rightEyeOpenProbability,
  double? headEulerAngleX,
  double? headEulerAngleY,
  double? headEulerAngleZ,
}) {
  return _MockFace(
    smilingProbability: smilingProbability,
    leftEyeOpenProbability: leftEyeOpenProbability,
    rightEyeOpenProbability: rightEyeOpenProbability,
    headEulerAngleX: headEulerAngleX,
    headEulerAngleY: headEulerAngleY,
    headEulerAngleZ: headEulerAngleZ,
  );
}

class _MockFace implements Face {
  @override
  final double? smilingProbability;
  @override
  final double? leftEyeOpenProbability;
  @override
  final double? rightEyeOpenProbability;
  @override
  final double? headEulerAngleX;
  @override
  final double? headEulerAngleY;
  @override
  final double? headEulerAngleZ;

  _MockFace({
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
  });

  @override
  Rect get boundingBox => const Rect.fromLTWH(100, 100, 200, 200);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
