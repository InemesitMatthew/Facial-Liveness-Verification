import 'package:facial_liveness_verification/src/core/dependencies.dart';
import 'package:facial_liveness_verification/src/core/interfaces.dart';

/// Wrapper for Google ML Kit FaceDetector that implements IFaceDetector.
class FaceDetectorWrapper implements IFaceDetector {
  final FaceDetector _detector;

  FaceDetectorWrapper(this._detector);

  @override
  Future<List<Face>> processImage(InputImage image) {
    return _detector.processImage(image);
  }

  @override
  Future<void> close() {
    return _detector.close();
  }
}

