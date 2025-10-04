import 'dart:developer' as dev;
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/liveness_config.dart';
import '../models/liveness_result.dart';
import '../utils/liveness_constants.dart';

/// Advanced anti-spoofing detection engine.
///
/// This engine analyzes facial movement patterns, depth variations, and timing
/// to detect potential spoofing attempts using photos, videos, or 3D masks.
class AntiSpoofingEngine {
  final List<FaceHistoryEntry> _faceHistory = [];
  final List<double> _faceSizeHistory = [];
  
  final AntiSpoofingConfig _config;
  DateTime? _firstDetection;

  /// Creates a new anti-spoofing engine with the given configuration.
  AntiSpoofingEngine(this._config);

  /// Analyzes faces for liveness detection.
  ///
  /// Returns [AntiSpoofingResult] indicating whether the faces appear to be
  /// from a live person or a spoofing attempt.
  Future<AntiSpoofingResult> analyzeFaces(
    List<Face> faces,
    CameraImage image,
    DateTime timestamp,
  ) async {
    try {
      if (faces.isEmpty) {
        return const AntiSpoofingResult.failed('No face detected');
      }

      final face = faces.first;
      _addToHistory(face, timestamp);

      if (_faceHistory.length < AntiSpoofingDefaults.minHistoryForAnalysis) {
        return const AntiSpoofingResult.failed('Collecting data...');
      }

      // Perform motion analysis
      final motionAnalysis = _detectNaturalMotion();
      if (!motionAnalysis.passed) {
        return AntiSpoofingResult.failed('Please move naturally: ${motionAnalysis.toString()}');
      }

      // Perform depth analysis
      final depthAnalysis = _detectDepthVariation();
      if (!depthAnalysis.passed) {
        return AntiSpoofingResult.failed('Move closer/further slightly: ${depthAnalysis.toString()}');
      }

      // Perform timing analysis
      final timingAnalysis = _validateTiming();
      if (!timingAnalysis.passed) {
        return AntiSpoofingResult.failed('Verifying authenticity...: ${timingAnalysis.toString()}');
      }

      // All checks passed - likely a live person
      final confidence = _calculateConfidence(motionAnalysis, depthAnalysis, timingAnalysis);
      
      return AntiSpoofingResult.live(
        confidence: confidence,
        reason: 'Live person detected with high confidence',
        motionAnalysis: motionAnalysis,
        depthAnalysis: depthAnalysis,
        timingAnalysis: timingAnalysis,
      );

    } catch (e, stackTrace) {
      dev.log('Anti-spoofing analysis error: $e', stackTrace: stackTrace);
      return AntiSpoofingResult.failed('Analysis error: ${e.toString()}');
    }
  }

  /// Adds a face detection to the analysis history.
  void _addToHistory(Face face, DateTime timestamp) {
    final entry = FaceHistoryEntry(
      face: face,
      timestamp: timestamp,
      headRotation: _calculateHeadRotation(face),
      faceSize: _calculateFaceSize(face),
    );

    _faceHistory.add(entry);

    // Maintain history size
    if (_faceHistory.length > _config.maxHistoryLength) {
      _faceHistory.removeAt(0);
    }

    // Track face size history
    _faceSizeHistory.add(entry.faceSize);
    if (_faceSizeHistory.length > _config.maxHistoryLength) {
      _faceSizeHistory.removeAt(0);
    }

    // Track first detection time
    _firstDetection ??= timestamp;
  }

  /// Calculates the overall head rotation magnitude.
  double _calculateHeadRotation(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    return sqrt(yaw * yaw + pitch * pitch + roll * roll);
  }

  /// Calculates the face size using diagonal distance.
  double _calculateFaceSize(Face face) {
    final box = face.boundingBox;
    return sqrt(box.width * box.width + box.height * box.height);
  }

  /// Detects natural motion patterns in facial movement.
  MotionAnalysis _detectNaturalMotion() {
    if (_faceHistory.length < AntiSpoofingDefaults.minHistoryForAnalysis) {
      return const MotionAnalysis.failed();
    }

    final rotations = _faceHistory.map((e) => e.headRotation).toList();
    
    // Calculate variance in head movement
    final mean = rotations.reduce((a, b) => a + b) / rotations.length;
    final variance = rotations
        .map((r) => pow(r - mean, 2))
        .reduce((a, b) => a + b) / rotations.length;

    // Count static frames (minimal movement between consecutive frames)
    int staticFrames = 0;
    for (int i = 1; i < _faceHistory.length; i++) {
      final prev = _faceHistory[i - 1];
      final curr = _faceHistory[i];
      if ((curr.headRotation - prev.headRotation).abs() < 0.1) {
        staticFrames++;
      }
    }

    final staticFrameRatio = staticFrames / _faceHistory.length;
    
    // Check if motion meets minimum requirements
    final passed = variance >= _config.minMotionVariance && 
                   staticFrameRatio <= _config.maxStaticFrames;

    return MotionAnalysis(
      motionVariance: variance,
      staticFrameRatio: staticFrameRatio,
      passed: passed,
    );
  }

  /// Detects depth variation indicating 3D face movement.
  DepthAnalysis _detectDepthVariation() {
    if (_faceSizeHistory.length < AntiSpoofingDefaults.minHistoryForAnalysis) {
      return const DepthAnalysis.failed();
    }

    final minSize = _faceSizeHistory.reduce(min);
    final maxSize = _faceSizeHistory.reduce(max);
    final sizeVariation = maxSize > 0 ? (maxSize - minSize) / maxSize : 0.0;

    final passed = sizeVariation >= _config.minDepthVariation;

    return DepthAnalysis(
      sizeVariation: sizeVariation,
      minSize: minSize,
      maxSize: maxSize,
      passed: passed,
    );
  }

  /// Validates timing requirements for liveness detection.
  TimingAnalysis _validateTiming() {
    if (_firstDetection == null) {
      return const TimingAnalysis.failed();
    }

    final elapsed = DateTime.now().difference(_firstDetection!);
    final totalTime = elapsed.inMilliseconds;
    final minimumTime = _config.minVerificationTime * 1000; // Convert to milliseconds

    final passed = elapsed.inSeconds >= _config.minVerificationTime;

    return TimingAnalysis(
      totalTime: totalTime,
      minimumTime: minimumTime,
      passed: passed,
    );
  }

  /// Calculates overall confidence score based on all analyses.
  double _calculateConfidence(
    MotionAnalysis motion,
    DepthAnalysis depth,
    TimingAnalysis timing,
  ) {
    // Base confidence from individual analyses
    double motionScore = motion.passed ? 1.0 : 0.0;
    double depthScore = depth.passed ? 1.0 : 0.0;
    double timingScore = timing.passed ? 1.0 : 0.0;

    // Adjust scores based on quality of the analysis
    if (motion.passed) {
      // Higher variance indicates more natural movement
      motionScore = (motion.motionVariance / (_config.minMotionVariance * 2)).clamp(0.5, 1.0);
    }

    if (depth.passed) {
      // Higher depth variation indicates more realistic 3D movement
      depthScore = (depth.sizeVariation / (_config.minDepthVariation * 2)).clamp(0.5, 1.0);
    }

    if (timing.passed) {
      // Longer verification time increases confidence
      final timeRatio = timing.totalTime / (timing.minimumTime * 2);
      timingScore = timeRatio.clamp(0.5, 1.0);
    }

    // Weighted average of all scores
    return ((motionScore * 0.4) + (depthScore * 0.4) + (timingScore * 0.2)).clamp(0.0, 1.0);
  }

  /// Resets the anti-spoofing analysis state.
  void reset() {
    _faceHistory.clear();
    _faceSizeHistory.clear();
    _firstDetection = null;
  }

  /// Disposes of resources used by the engine.
  void dispose() {
    reset();
  }

  /// Gets current analysis statistics for debugging.
  Map<String, dynamic> getAnalysisStats() {
    if (_faceHistory.isEmpty) {
      return {'status': 'no_data'};
    }

    final motionAnalysis = _detectNaturalMotion();
    final depthAnalysis = _detectDepthVariation();
    final timingAnalysis = _validateTiming();

    return {
      'historyLength': _faceHistory.length,
      'motionVariance': motionAnalysis.motionVariance,
      'staticFrameRatio': motionAnalysis.staticFrameRatio,
      'sizeVariation': depthAnalysis.sizeVariation,
      'verificationTime': timingAnalysis.totalTime,
      'overallPassed': motionAnalysis.passed && depthAnalysis.passed && timingAnalysis.passed,
    };
  }
}

/// Represents a single entry in the face detection history.
class FaceHistoryEntry {
  final Face face;
  final DateTime timestamp;
  final double headRotation;
  final double faceSize;

  FaceHistoryEntry({
    required this.face,
    required this.timestamp,
    required this.headRotation,
    required this.faceSize,
  });

  @override
  String toString() {
    return 'FaceHistoryEntry(timestamp: $timestamp, headRotation: $headRotation, faceSize: $faceSize)';
  }
}