import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

void main() {
  group('LivenessConfig', () {
    test('should create config with default values', () {
      const config = LivenessConfig();
      expect(config.challenges.length, 4);
      expect(config.enableAntiSpoofing, true);
      expect(config.challengeTimeout, const Duration(seconds: 20));
      expect(config.sessionTimeout, const Duration(minutes: 5));
    });

    test('should create config with custom challenges', () {
      const config = LivenessConfig(
        challenges: [ChallengeType.smile, ChallengeType.blink],
      );
      expect(config.challenges.length, 2);
      expect(config.challenges, contains(ChallengeType.smile));
      expect(config.challenges, contains(ChallengeType.blink));
    });

    test('should allow disabling anti-spoofing', () {
      const config = LivenessConfig(enableAntiSpoofing: false);
      expect(config.enableAntiSpoofing, false);
    });

    test('should allow custom thresholds', () {
      const config = LivenessConfig(
        smileThreshold: 0.7,
        eyeOpenThreshold: 0.3,
        headAngleThreshold: 20.0,
      );
      expect(config.smileThreshold, 0.7);
      expect(config.eyeOpenThreshold, 0.3);
      expect(config.headAngleThreshold, 20.0);
    });
  });
}
