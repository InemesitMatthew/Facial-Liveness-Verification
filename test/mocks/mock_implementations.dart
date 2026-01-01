import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/core/interfaces.dart';

/// Mock implementation of IFaceDetector for testing.
class MockFaceDetector implements IFaceDetector {
  final List<Face> Function(InputImage)? _onProcessImage;
  final Future<void> Function()? _onClose;

  MockFaceDetector({
    List<Face> Function(InputImage)? onProcessImage,
    Future<void> Function()? onClose,
  })  : _onProcessImage = onProcessImage,
        _onClose = onClose;

  @override
  Future<List<Face>> processImage(InputImage image) async {
    if (_onProcessImage != null) {
      return _onProcessImage!(image);
    }
    return [];
  }

  @override
  Future<void> close() async {
    if (_onClose != null) {
      await _onClose!();
    }
  }
}

/// Mock implementation of ICameraManager for testing.
class MockCameraManager implements ICameraManager {
  final Future<void> Function()? _onInitialize;
  final Future<void> Function()? _onTestMLKitSetup;
  final Future<void> Function(Function(CameraImage))? _onStartImageStream;
  final Future<void> Function()? _onStopImageStream;
  final Future<void> Function()? _onDispose;
  final CameraController? _controller;
  final bool _isInitialized;

  MockCameraManager({
    Future<void> Function()? onInitialize,
    Future<void> Function()? onTestMLKitSetup,
    Future<void> Function(Function(CameraImage))? onStartImageStream,
    Future<void> Function()? onStopImageStream,
    Future<void> Function()? onDispose,
    CameraController? controller,
    bool isInitialized = false,
  })  : _onInitialize = onInitialize,
        _onTestMLKitSetup = onTestMLKitSetup,
        _onStartImageStream = onStartImageStream,
        _onStopImageStream = onStopImageStream,
        _onDispose = onDispose,
        _controller = controller,
        _isInitialized = isInitialized;

  @override
  Future<void> initialize() async {
    if (_onInitialize != null) {
      await _onInitialize!();
    }
  }

  @override
  Future<void> testMLKitSetup() async {
    if (_onTestMLKitSetup != null) {
      await _onTestMLKitSetup!();
    }
  }

  @override
  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (_onStartImageStream != null) {
      await _onStartImageStream!(onImage);
    }
  }

  @override
  Future<void> stopImageStream() async {
    if (_onStopImageStream != null) {
      await _onStopImageStream!();
    }
  }

  @override
  Future<void> dispose() async {
    if (_onDispose != null) {
      await _onDispose!();
    }
  }

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized => _isInitialized;
}

/// Mock implementation of IImageConverter for testing.
class MockImageConverter implements IImageConverter {
  final Future<InputImage?> Function(CameraImage)? _onCreateInputImage;

  MockImageConverter({
    Future<InputImage?> Function(CameraImage)? onCreateInputImage,
  }) : _onCreateInputImage = onCreateInputImage;

  @override
  Future<InputImage?> createInputImage(CameraImage image) async {
    if (_onCreateInputImage != null) {
      return _onCreateInputImage!(image);
    }
    return null;
  }
}

