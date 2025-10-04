/// Enumeration of available liveness detection challenges.
///
/// Each challenge type represents a different action the user must perform
/// to prove they are a real person and not a static photo or video.
enum ChallengeType {
  /// User must smile naturally
  smile,
  
  /// User must blink their eyes
  blink,
  
  /// User must turn their head to the left
  turnLeft,
  
  /// User must turn their head to the right
  turnRight,
  
  /// User must nod their head up and down
  nod,
  
  /// User must shake their head left and right
  headShake,
}

/// Extension to provide human-readable descriptions for challenge types.
extension ChallengeTypeExtension on ChallengeType {
  /// Returns a user-friendly instruction for the challenge.
  String get instruction {
    switch (this) {
      case ChallengeType.smile:
        return 'smile naturally - just a gentle smile!';
      case ChallengeType.blink:
        return 'blink your eyes - one natural blink is enough!';
      case ChallengeType.turnLeft:
        return 'turn your head left - stay in frame and turn back to center!';
      case ChallengeType.turnRight:
        return 'turn your head right - stay in frame and turn back to center!';
      case ChallengeType.nod:
        return 'nod your head up and down - keep your face visible!';
      case ChallengeType.headShake:
        return 'shake your head left and right - stay centered!';
    }
  }

  /// Returns a short action name for internal use.
  String get actionName {
    switch (this) {
      case ChallengeType.smile:
        return 'smile';
      case ChallengeType.blink:
        return 'blink';
      case ChallengeType.turnLeft:
        return 'turn_left';
      case ChallengeType.turnRight:
        return 'turn_right';
      case ChallengeType.nod:
        return 'nod';
      case ChallengeType.headShake:
        return 'head_shake';
    }
  }

  /// Returns an emoji representation of the challenge.
  String get emoji {
    switch (this) {
      case ChallengeType.smile:
        return '😊';
      case ChallengeType.blink:
        return '👁️';
      case ChallengeType.turnLeft:
        return '↪️';
      case ChallengeType.turnRight:
        return '↩️';
      case ChallengeType.nod:
        return '🔽';
      case ChallengeType.headShake:
        return '↔️';
    }
  }
}