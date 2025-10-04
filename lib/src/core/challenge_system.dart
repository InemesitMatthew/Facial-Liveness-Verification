import 'dart:developer' as dev;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/challenge_types.dart';
import '../models/liveness_config.dart';
import '../utils/liveness_constants.dart' as constants;

/// Manages the sequence of challenges for liveness verification.
///
/// Handles challenge randomization, validation, timing, and progress tracking
/// to ensure users perform live actions that cannot be replicated by photos or videos.
class ChallengeSystem {
  final LivenessConfig _config;
  final List<ChallengeType> _challenges;
  final Map<ChallengeType, DateTime> _challengeStartTimes = {};
  final Map<ChallengeType, Duration> _challengeCompletionTimes = {};
  
  int _currentChallengeIndex = 0;
  bool _waitingForNeutral = false;
  bool _isInTurnChallenge = false;
  
  // Blink detection state
  bool _wasBlinking = false;
  DateTime? _lastBlinkTime;

  /// Creates a new challenge system with the given configuration.
  ChallengeSystem(this._config) : _challenges = List.from(_config.challengeTypes) {
    _initializeChallenges();
  }

  /// Initializes the challenge sequence.
  void _initializeChallenges() {
    if (_config.shuffleChallenges) {
      _challenges.shuffle();
      
      // Ensure smile and blink are included if they were in the original list
      if (_config.challengeTypes.contains(ChallengeType.smile) && 
          !_challenges.take(2).contains(ChallengeType.smile)) {
        final smileIndex = _challenges.indexOf(ChallengeType.smile);
        if (smileIndex > 1) {
          // Swap smile to first position
          final temp = _challenges[0];
          _challenges[0] = ChallengeType.smile;
          _challenges[smileIndex] = temp;
        }
      }
      
      if (_config.challengeTypes.contains(ChallengeType.blink) && 
          !_challenges.take(2).contains(ChallengeType.blink)) {
        final blinkIndex = _challenges.indexOf(ChallengeType.blink);
        if (blinkIndex > 1) {
          // Swap blink to second position
          final temp = _challenges[1];
          _challenges[1] = ChallengeType.blink;
          _challenges[blinkIndex] = temp;
        }
      }
    }

    dev.log('Challenge sequence initialized: ${_challenges.map((c) => c.actionName).join(', ')}');
  }

  /// Gets the current challenge that needs to be completed.
  ChallengeType get currentChallenge => _challenges[_currentChallengeIndex];

  /// Gets the current challenge index (0-based).
  int get currentChallengeIndex => _currentChallengeIndex;

  /// Gets the total number of challenges.
  int get totalChallenges => _challenges.length;

  /// Whether the system is waiting for the user to return to neutral position.
  bool get isWaitingForNeutral => _waitingForNeutral;

  /// Whether the current challenge is a turn-based challenge.
  bool get isInTurnChallenge => _isInTurnChallenge;

  /// Gets the progress as a percentage (0.0 to 1.0).
  double get progress => _currentChallengeIndex / _challenges.length;

  /// Gets the list of completed challenges.
  List<ChallengeType> get completedChallenges => 
      _challenges.take(_currentChallengeIndex).toList();

  /// Gets the challenge completion times.
  Map<ChallengeType, Duration> get challengeCompletionTimes => 
      Map.from(_challengeCompletionTimes);

  /// Processes a face detection result for the current challenge.
  ///
  /// Returns a [ChallengeProgress] indicating the current state and any
  /// changes that occurred.
  ChallengeProgress processChallenge(Face face) {
    try {
      if (_currentChallengeIndex >= _challenges.length) {
        return ChallengeProgress.completed(
          allChallengesCompleted: true,
          completedChallenges: completedChallenges,
          completionTimes: challengeCompletionTimes,
        );
      }

      final challenge = currentChallenge;
      
      // Update turn challenge state
      _updateTurnChallengeState(challenge);

      // Check if waiting for neutral position
      if (_waitingForNeutral) {
        if (_isNeutralPosition(face)) {
          _waitingForNeutral = false;
          _isInTurnChallenge = false;
          dev.log('User returned to neutral position');
          
          return ChallengeProgress.neutralPositionReached(
            currentChallenge: challenge,
            challengeIndex: _currentChallengeIndex,
            totalChallenges: totalChallenges,
          );
        }
        return ChallengeProgress.waitingForNeutral(
          currentChallenge: challenge,
          challengeIndex: _currentChallengeIndex,
          totalChallenges: totalChallenges,
        );
      }

      // Start challenge timer if not already started
      _challengeStartTimes[challenge] ??= DateTime.now();

      // Check for challenge timeout
      final elapsed = DateTime.now().difference(_challengeStartTimes[challenge]!);
      if (elapsed > _config.challengeTimeout) {
        return _handleChallengeTimeout(challenge);
      }

      // Validate the challenge
      if (_validateChallenge(face, challenge)) {
        return _completeCurrentChallenge(challenge, elapsed);
      }

      return ChallengeProgress.inProgress(
        currentChallenge: challenge,
        challengeIndex: _currentChallengeIndex,
        totalChallenges: totalChallenges,
        elapsedTime: elapsed,
        remainingTime: _config.challengeTimeout - elapsed,
      );

    } catch (e, stackTrace) {
      dev.log('Challenge processing error: $e', stackTrace: stackTrace);
      return ChallengeProgress.error(
        currentChallenge: currentChallenge,
        error: 'Challenge processing failed: ${e.toString()}',
      );
    }
  }

  /// Updates the turn challenge state based on the current challenge.
  void _updateTurnChallengeState(ChallengeType challenge) {
    switch (challenge) {
      case ChallengeType.turnLeft:
      case ChallengeType.turnRight:
        _isInTurnChallenge = true;
        break;
      default:
        if (!_waitingForNeutral) {
          _isInTurnChallenge = false;
        }
        break;
    }
  }

  /// Validates whether the user is performing the required challenge action.
  bool _validateChallenge(Face face, ChallengeType challenge) {
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

  /// Validates smile challenge.
  bool _validateSmile(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;
    return smilingProbability > _config.thresholds.smileThreshold;
  }

  /// Validates blink challenge with proper eye closure detection.
  bool _validateBlink(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEye + rightEye) / 2;

    // Detect eye closure
    if (avgEyeOpen < _config.thresholds.eyeOpenThreshold && !_wasBlinking) {
      _wasBlinking = true;
      _lastBlinkTime = DateTime.now();
      return false; // Not complete yet, waiting for eyes to open
    }
    
    // Detect eye opening after closure
    if (avgEyeOpen > (1.0 - _config.thresholds.eyeOpenThreshold) && _wasBlinking) {
      _wasBlinking = false;
      
      // Validate blink timing (should be quick)
      if (_lastBlinkTime != null &&
          DateTime.now().difference(_lastBlinkTime!).inMilliseconds < 1000) {
        return true; // Valid blink completed
      }
    }

    return false;
  }

  /// Validates left turn challenge.
  bool _validateTurnLeft(Face face) {
    final headAngleY = face.headEulerAngleY ?? 0.0;
    return headAngleY > _config.thresholds.headAngleThreshold;
  }

  /// Validates right turn challenge.
  bool _validateTurnRight(Face face) {
    final headAngleY = face.headEulerAngleY ?? 0.0;
    return headAngleY < -_config.thresholds.headAngleThreshold;
  }

  /// Validates nod challenge (up and down head movement).
  bool _validateNod(Face face) {
    final headAngleX = face.headEulerAngleX ?? 0.0;
    return headAngleX.abs() > (_config.thresholds.headAngleThreshold * 0.8);
  }

  /// Validates head shake challenge (left and right head movement).
  bool _validateHeadShake(Face face) {
    final headAngleY = face.headEulerAngleY ?? 0.0;
    return headAngleY.abs() > (_config.thresholds.headAngleThreshold * 0.8);
  }

  /// Checks if the user is in a neutral position.
  bool _isNeutralPosition(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final headAngleY = face.headEulerAngleY ?? 0.0;

    return smilingProbability < constants.DetectionThresholds.neutralSmile &&
           leftEye > constants.DetectionThresholds.neutralEyeOpen &&
           rightEye > constants.DetectionThresholds.neutralEyeOpen &&
           headAngleY.abs() < constants.DetectionThresholds.neutralHeadAngle;
  }

  /// Completes the current challenge and moves to the next one.
  ChallengeProgress _completeCurrentChallenge(ChallengeType challenge, Duration elapsed) {
    // Record completion time
    _challengeCompletionTimes[challenge] = elapsed;
    
    dev.log('Challenge ${challenge.actionName} completed in ${elapsed.inMilliseconds}ms');

    // Move to next challenge
    _currentChallengeIndex++;
    
    if (_currentChallengeIndex >= _challenges.length) {
      // All challenges completed
      return ChallengeProgress.completed(
        allChallengesCompleted: true,
        completedChallenges: completedChallenges,
        completionTimes: challengeCompletionTimes,
      );
    }

    // Set up for neutral position waiting if required
    if (_config.requireNeutralPosition) {
      _waitingForNeutral = true;
    }

    return ChallengeProgress.challengeCompleted(
      completedChallenge: challenge,
      completionTime: elapsed,
      nextChallenge: currentChallenge,
      challengeIndex: _currentChallengeIndex,
      totalChallenges: totalChallenges,
      waitingForNeutral: _waitingForNeutral,
    );
  }

  /// Handles challenge timeout.
  ChallengeProgress _handleChallengeTimeout(ChallengeType challenge) {
    dev.log('Challenge ${challenge.actionName} timed out');
    
    // Reset challenge timer to allow retry
    _challengeStartTimes.remove(challenge);
    _isInTurnChallenge = false;
    
    return ChallengeProgress.timeout(
      currentChallenge: challenge,
      challengeIndex: _currentChallengeIndex,
      totalChallenges: totalChallenges,
      timeoutDuration: _config.challengeTimeout,
    );
  }

  /// Resets the challenge system to its initial state.
  void reset() {
    _currentChallengeIndex = 0;
    _waitingForNeutral = false;
    _isInTurnChallenge = false;
    _wasBlinking = false;
    _lastBlinkTime = null;
    _challengeStartTimes.clear();
    _challengeCompletionTimes.clear();
    
    _initializeChallenges();
    dev.log('Challenge system reset');
  }

  /// Skips the current challenge (for testing/debugging purposes).
  ChallengeProgress skipCurrentChallenge() {
    if (_currentChallengeIndex >= _challenges.length) {
      return ChallengeProgress.completed(
        allChallengesCompleted: true,
        completedChallenges: completedChallenges,
        completionTimes: challengeCompletionTimes,
      );
    }

    final challenge = currentChallenge;
    final elapsed = DateTime.now().difference(_challengeStartTimes[challenge] ?? DateTime.now());
    
    return _completeCurrentChallenge(challenge, elapsed);
  }
}

/// Represents the current state and progress of challenge completion.
class ChallengeProgress {
  final ChallengeProgressType type;
  final ChallengeType currentChallenge;
  final ChallengeType? completedChallenge;
  final ChallengeType? nextChallenge;
  final int challengeIndex;
  final int totalChallenges;
  final Duration? elapsedTime;
  final Duration? remainingTime;
  final Duration? completionTime;
  final Duration? timeoutDuration;
  final bool waitingForNeutral;
  final bool allChallengesCompleted;
  final List<ChallengeType> completedChallenges;
  final Map<ChallengeType, Duration> completionTimes;
  final String? error;

  const ChallengeProgress._({
    required this.type,
    required this.currentChallenge,
    this.completedChallenge,
    this.nextChallenge,
    required this.challengeIndex,
    required this.totalChallenges,
    this.elapsedTime,
    this.remainingTime,
    this.completionTime,
    this.timeoutDuration,
    this.waitingForNeutral = false,
    this.allChallengesCompleted = false,
    this.completedChallenges = const [],
    this.completionTimes = const {},
    this.error,
  });

  /// Challenge is in progress.
  factory ChallengeProgress.inProgress({
    required ChallengeType currentChallenge,
    required int challengeIndex,
    required int totalChallenges,
    required Duration elapsedTime,
    required Duration remainingTime,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.inProgress,
      currentChallenge: currentChallenge,
      challengeIndex: challengeIndex,
      totalChallenges: totalChallenges,
      elapsedTime: elapsedTime,
      remainingTime: remainingTime,
    );
  }

  /// Challenge was completed successfully.
  factory ChallengeProgress.challengeCompleted({
    required ChallengeType completedChallenge,
    required Duration completionTime,
    required ChallengeType nextChallenge,
    required int challengeIndex,
    required int totalChallenges,
    required bool waitingForNeutral,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.challengeCompleted,
      currentChallenge: nextChallenge,
      completedChallenge: completedChallenge,
      nextChallenge: nextChallenge,
      challengeIndex: challengeIndex,
      totalChallenges: totalChallenges,
      completionTime: completionTime,
      waitingForNeutral: waitingForNeutral,
    );
  }

  /// All challenges completed successfully.
  factory ChallengeProgress.completed({
    required bool allChallengesCompleted,
    required List<ChallengeType> completedChallenges,
    required Map<ChallengeType, Duration> completionTimes,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.allCompleted,
      currentChallenge: completedChallenges.last,
      challengeIndex: completedChallenges.length,
      totalChallenges: completedChallenges.length,
      allChallengesCompleted: allChallengesCompleted,
      completedChallenges: completedChallenges,
      completionTimes: completionTimes,
    );
  }

  /// Waiting for user to return to neutral position.
  factory ChallengeProgress.waitingForNeutral({
    required ChallengeType currentChallenge,
    required int challengeIndex,
    required int totalChallenges,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.waitingForNeutral,
      currentChallenge: currentChallenge,
      challengeIndex: challengeIndex,
      totalChallenges: totalChallenges,
      waitingForNeutral: true,
    );
  }

  /// User returned to neutral position.
  factory ChallengeProgress.neutralPositionReached({
    required ChallengeType currentChallenge,
    required int challengeIndex,
    required int totalChallenges,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.neutralPositionReached,
      currentChallenge: currentChallenge,
      challengeIndex: challengeIndex,
      totalChallenges: totalChallenges,
    );
  }

  /// Challenge timed out.
  factory ChallengeProgress.timeout({
    required ChallengeType currentChallenge,
    required int challengeIndex,
    required int totalChallenges,
    required Duration timeoutDuration,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.timeout,
      currentChallenge: currentChallenge,
      challengeIndex: challengeIndex,
      totalChallenges: totalChallenges,
      timeoutDuration: timeoutDuration,
    );
  }

  /// Challenge processing error occurred.
  factory ChallengeProgress.error({
    required ChallengeType currentChallenge,
    required String error,
  }) {
    return ChallengeProgress._(
      type: ChallengeProgressType.error,
      currentChallenge: currentChallenge,
      challengeIndex: 0,
      totalChallenges: 0,
      error: error,
    );
  }
}

/// Types of challenge progress states.
enum ChallengeProgressType {
  inProgress,
  challengeCompleted,
  allCompleted,
  waitingForNeutral,
  neutralPositionReached,
  timeout,
  error,
}