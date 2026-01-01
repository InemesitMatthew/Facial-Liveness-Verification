import 'dart:math';
import 'package:facial_liveness_verification/src/core/core.dart';
import 'package:facial_liveness_verification/src/models/models.dart';

/// Result of anti-spoofing analysis.
class SpoofingResult {
  final bool isLive;
  final String reason;

  const SpoofingResult(this.isLive, this.reason);
}

/// Detects potential spoofing attempts using motion and depth analysis.
///
/// Analyzes face movement patterns, depth variation, and timing to distinguish
/// real faces from photos, videos, or masks.
class SpoofingDetector {
  final LivenessConfig _config;
  final List<FaceHistoryEntry> _faceHistory = [];
  DateTime? _firstDetection;

  SpoofingDetector(this._config);

  /// Analyzes faces for spoofing indicators.
  ///
  /// Returns [SpoofingResult] indicating if the face appears to be live.
  Future<SpoofingResult> analyzeFaces(
    List<Face> faces,
    CameraImage image,
    DateTime timestamp,
  ) async {
    if (faces.isEmpty) {
      return SpoofingResult(false, 'No face detected');
    }

    final face = faces.first;
    _addToHistory(face, timestamp);

    if (_faceHistory.length < minFramesForAnalysis) {
      return SpoofingResult(false, 'Collecting data...');
    }

    // Check for natural motion patterns
    if (!_detectNaturalMotion()) {
      return SpoofingResult(false, 'Please move naturally');
    }

    // Check for depth variation (indicates 3D face, not flat photo)
    if (!_detectDepthVariation()) {
      return SpoofingResult(false, 'Move closer/further slightly');
    }

    // Ensure minimum verification time has elapsed
    if (!_validateTiming()) {
      return SpoofingResult(false, 'Verifying authenticity...');
    }

    return SpoofingResult(true, 'Live person detected');
  }

  void _addToHistory(Face face, DateTime timestamp) {
    _faceHistory.add(
      FaceHistoryEntry(
        face: face,
        timestamp: timestamp,
        headRotation: _calculateHeadRotation(face),
        faceSize: _calculateFaceSize(face),
      ),
    );

    if (_faceHistory.length > _config.maxHistoryLength) {
      _faceHistory.removeAt(0);
    }

    _firstDetection ??= timestamp;
  }

  double _calculateHeadRotation(Face face) {
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    return sqrt(yaw * yaw + pitch * pitch + roll * roll);
  }

  double _calculateFaceSize(Face face) {
    final box = face.boundingBox;
    return sqrt(box.width * box.width + box.height * box.height);
  }

  /// Detects natural motion by analyzing head rotation variance and static frame ratio.
  bool _detectNaturalMotion() {
    if (_faceHistory.length < minFramesForAnalysis) return false;

    if (!_hasSufficientMotionVariance()) {
      return false;
    }

    final staticRatio = _calculateStaticFrameRatio();
    return staticRatio < _config.maxStaticFrames;
  }

  bool _hasSufficientMotionVariance() {
    final rotations = _faceHistory.map((e) => e.headRotation).toList();
    final mean = rotations.reduce((a, b) => a + b) / rotations.length;
    final variance =
        rotations.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) /
            rotations.length;
    return variance >= _config.minMotionVariance;
  }

  double _calculateStaticFrameRatio() {
    int staticFrames = 0;
    for (int i = 1; i < _faceHistory.length; i++) {
      final prev = _faceHistory[i - 1];
      final curr = _faceHistory[i];
      if ((curr.headRotation - prev.headRotation).abs() <
          staticFrameThreshold) {
        staticFrames++;
      }
    }
    return staticFrames / _faceHistory.length;
  }

  /// Detects depth variation by analyzing face size changes.
  bool _detectDepthVariation() {
    if (_faceHistory.length < minFramesForAnalysis) return false;

    final sizes = _faceHistory.map((e) => e.faceSize).toList();
    final minSize = sizes.reduce(min);
    final maxSize = sizes.reduce(max);
    final sizeVariation = (maxSize - minSize) / maxSize;

    return sizeVariation >= _config.minDepthVariation;
  }

  /// Validates that minimum verification time has elapsed.
  ///
  /// Prevents instant spoofing attempts.
  bool _validateTiming() {
    if (_firstDetection == null) return false;
    final elapsed = DateTime.now().difference(_firstDetection!);
    return elapsed.inSeconds >= _config.minVerificationTime;
  }

  /// Cleans up resources and clears history.
  void dispose() {
    _faceHistory.clear();
    _firstDetection = null;
  }
}

/// Historical entry tracking face state at a point in time.
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
}
