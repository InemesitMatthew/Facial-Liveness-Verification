import 'package:flutter_test/flutter_test.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';
import '../mocks/mock_implementations.dart';

void main() {
  group('LivenessDetector', () {
    late LivenessConfig config;

    setUp(() {
      config = const LivenessConfig();
    });

    test('should create detector with config (backward compatible)', () {
      final detector = LivenessDetector(config);
      expect(detector, isNotNull);
      expect(detector.stateStream, isNotNull);
    });

    test('should create detector with mocked dependencies', () {
      final mockFaceDetector = MockFaceDetector();
      final mockCameraManager = MockCameraManager();
      final mockImageConverter = MockImageConverter();

      final detector = LivenessDetector(
        config,
        faceDetector: mockFaceDetector,
        cameraManager: mockCameraManager,
        imageConverter: mockImageConverter,
      );

      expect(detector, isNotNull);
      expect(detector.stateStream, isNotNull);
    });

    test('should provide state stream', () {
      final detector = LivenessDetector(config);
      expect(detector.stateStream, isNotNull);
    });

    test('should expose camera controller', () {
      final detector = LivenessDetector(config);
      expect(detector.cameraController, isNull);
    });

    group('initialization', () {
      test('should initialize successfully with mocks', () async {
        final mockCameraManager = MockCameraManager(
          onTestMLKitSetup: () async => {},
          onInitialize: () async => {},
        );

        final detector = LivenessDetector(
          config,
          cameraManager: mockCameraManager,
        );

        final states = <LivenessState>[];
        final subscription = detector.stateStream.listen(states.add);

        await detector.initialize();

        await Future.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        expect(states.any((s) => s.type == LivenessStateType.initialized), isTrue);
      });

      test('should throw error if initialization fails', () async {
        final mockCameraManager = MockCameraManager(
          onTestMLKitSetup: () async {
            throw Exception('ML Kit setup failed');
          },
        );

        final detector = LivenessDetector(
          config,
          cameraManager: mockCameraManager,
        );

        expect(
          () => detector.initialize(),
          throwsA(isA<LivenessError>()),
        );
      });

      test('should not initialize twice', () async {
        final mockCameraManager = MockCameraManager(
          onTestMLKitSetup: () async => {},
          onInitialize: () async => {},
        );

        final detector = LivenessDetector(
          config,
          cameraManager: mockCameraManager,
        );

        await detector.initialize();
        await detector.initialize();

        expect(detector.stateStream, isNotNull);
      });
    });

    group('start/stop', () {
      test('should throw error if start called before initialize', () async {
        final detector = LivenessDetector(config);

        expect(
          () => detector.start(),
          throwsA(isA<LivenessError>()),
        );
      });

      test('should start successfully after initialization', () async {
        final mockCameraManager = MockCameraManager(
          onTestMLKitSetup: () async => {},
          onInitialize: () async => {},
          onStartImageStream: (_) async => {},
        );

        final detector = LivenessDetector(
          config,
          cameraManager: mockCameraManager,
        );

        final states = <LivenessState>[];
        final subscription = detector.stateStream.listen(states.add);

        await detector.initialize();
        await detector.start();

        await Future.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        expect(states.any((s) => s.type == LivenessStateType.detecting), isTrue);
      });

      test('should stop successfully', () async {
        final mockCameraManager = MockCameraManager(
          onTestMLKitSetup: () async => {},
          onInitialize: () async => {},
          onStartImageStream: (_) async => {},
          onStopImageStream: () async => {},
        );

        final detector = LivenessDetector(
          config,
          cameraManager: mockCameraManager,
        );

        await detector.initialize();
        await detector.start();
        await detector.stop();

        expect(detector.stateStream, isNotNull);
      });
    });

    group('dispose', () {
      test('should dispose all resources', () async {
        bool faceDetectorClosed = false;
        bool cameraManagerDisposed = false;

        final mockFaceDetector = MockFaceDetector(
          onClose: () async {
            faceDetectorClosed = true;
          },
        );

        final mockCameraManager = MockCameraManager(
          onDispose: () async {
            cameraManagerDisposed = true;
          },
        );

        final detector = LivenessDetector(
          config,
          faceDetector: mockFaceDetector,
          cameraManager: mockCameraManager,
        );

        await detector.dispose();

        expect(faceDetectorClosed, isTrue);
        expect(cameraManagerDisposed, isTrue);
      });
    });

    group('challenge shuffling', () {
      test('should create detector with shuffle enabled', () {
        final configWithShuffle = LivenessConfig(
          shuffleChallenges: true,
          challenges: [
            ChallengeType.smile,
            ChallengeType.blink,
            ChallengeType.turnLeft,
          ],
        );

        final detector = LivenessDetector(configWithShuffle);
        expect(detector, isNotNull);
      });

      test('should create detector with shuffle disabled', () {
        final configWithoutShuffle = LivenessConfig(
          shuffleChallenges: false,
          challenges: [
            ChallengeType.smile,
            ChallengeType.blink,
          ],
        );

        final detector = LivenessDetector(configWithoutShuffle);
        expect(detector, isNotNull);
      });
    });
  });
}
