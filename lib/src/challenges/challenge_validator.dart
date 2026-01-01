import 'package:facial_liveness_verification/src/core/core.dart';
import 'package:facial_liveness_verification/src/models/models.dart';
import 'challenge_types.dart';

/// Validates user completion of liveness challenges based on face detection data.
class ChallengeValidator {
  final LivenessConfig _config;

  bool _wasBlinking = false;
  DateTime? _lastBlinkTime;

  ChallengeValidator(this._config);

  /// Validates if the user has completed the specified challenge.
  ///
  /// Returns `true` if the challenge is successfully completed, `false` otherwise.
  bool validateChallenge(Face face, ChallengeType challenge) {
    switch (challenge) {
      case ChallengeType.smile:
        return _validateSmile(face);
      case ChallengeType.blink:
        return _validateBlink(face);
      case ChallengeType.turnLeft:
        return _validateTurnLeft(face);
      case ChallengeType.turnRight:
        return _validateTurnRight(face);
      case ChallengeType.nod:
        return _validateNod(face);
      case ChallengeType.headShake:
        return _validateHeadShake(face);
    }
  }

  bool _validateSmile(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;
    return smilingProbability > _config.smileThreshold;
  }

  /// Validates blink by detecting eye closure followed by opening.
  bool _validateBlink(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEye + rightEye) / 2;

    if (avgEyeOpen < _config.eyeOpenThreshold && !_wasBlinking) {
      _wasBlinking = true;
      _lastBlinkTime = DateTime.now();
      return false;
    }

    if (avgEyeOpen > eyeOpenThreshold && _wasBlinking) {
      _wasBlinking = false;
      if (_lastBlinkTime != null &&
          DateTime.now().difference(_lastBlinkTime!).inMilliseconds <
              maxBlinkDurationMs) {
        return true;
      }
    }

    return false;
  }

  bool _validateTurnLeft(Face face) {
    return _validateHeadAngle(
        face.headEulerAngleY ?? 0.0, _config.headAngleThreshold, true);
  }

  bool _validateTurnRight(Face face) {
    return _validateHeadAngle(
        face.headEulerAngleY ?? 0.0, _config.headAngleThreshold, false);
  }

  bool _validateNod(Face face) {
    return _validateHeadAngleAbsolute(
        face.headEulerAngleX ?? 0.0, _config.headAngleThreshold);
  }

  bool _validateHeadShake(Face face) {
    return _validateHeadAngleAbsolute(
        face.headEulerAngleY ?? 0.0, _config.headAngleThreshold);
  }

  bool _validateHeadAngle(double angle, double threshold, bool positive) {
    return positive ? angle > threshold : angle < -threshold;
  }

  bool _validateHeadAngleAbsolute(double angle, double threshold) {
    return angle.abs() > (threshold * headAngleMultiplier);
  }

  /// Checks if the user is in a neutral position (no active challenge).
  bool isNeutralPosition(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final headAngleY = face.headEulerAngleY ?? 0.0;

    return smilingProbability < neutralSmileThreshold &&
        leftEye > eyeOpenThreshold &&
        rightEye > eyeOpenThreshold &&
        headAngleY.abs() < neutralHeadAngleThreshold;
  }

  /// Resets internal state.
  void reset() {
    _wasBlinking = false;
    _lastBlinkTime = null;
  }
}
