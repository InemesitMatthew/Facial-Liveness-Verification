import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/src/anti_spoofing/spoofing_detector.dart';
import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/models/config.dart';

void main() {
  group('SpoofingDetector', () {
    late SpoofingDetector detector;
    late LivenessConfig config;

    setUp(() {
      config = const LivenessConfig();
      detector = SpoofingDetector(config);
    });

    test('should return false for empty faces', () async {
      final result = await detector.analyzeFaces(
        [],
        _createMockCameraImage(),
        DateTime.now(),
      );

      expect(result.isLive, isFalse);
      expect(result.reason, 'No face detected');
    });

    test('should return false when collecting data', () async {
      final mockFace = _createMockFace();
      final result = await detector.analyzeFaces(
        [mockFace],
        _createMockCameraImage(),
        DateTime.now(),
      );

      expect(result.isLive, isFalse);
      expect(result.reason, 'Collecting data...');
    });

    test('should dispose resources', () {
      detector.dispose();
      expect(detector, isNotNull);
    });
  });
}

Face _createMockFace() {
  return _MockFace();
}

CameraImage _createMockCameraImage() {
  return _MockCameraImage();
}

class _MockFace implements Face {
  @override
  Rect get boundingBox => const Rect.fromLTWH(100, 100, 200, 200);

  @override
  double? get headEulerAngleX => 0.0;

  @override
  double? get headEulerAngleY => 0.0;

  @override
  double? get headEulerAngleZ => 0.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCameraImage implements CameraImage {
  @override
  int get width => 640;

  @override
  int get height => 480;

  @override
  List<Plane> get planes => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

