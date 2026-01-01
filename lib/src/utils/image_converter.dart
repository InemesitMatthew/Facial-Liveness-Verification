import 'dart:math';
import 'package:facial_liveness_verification/src/core/core.dart';

/// Converts [CameraImage] to [InputImage] format required by ML Kit.
///
/// Tries multiple formats to ensure compatibility across different devices.
class ImageConverter implements IImageConverter {
  /// Creates a new ImageConverter instance.
  const ImageConverter();

  /// Converts a camera image to ML Kit input format.
  ///
  /// Tries multiple formats in order: NV21, YUV420, BGRA8888.
  /// Returns `null` if conversion fails for all formats.
  @override
  Future<InputImage?> createInputImage(CameraImage image) async {
    final formatsToTry = [
      InputImageFormat.nv21,
      InputImageFormat.yuv420,
      InputImageFormat.bgra8888,
    ];

    for (final format in formatsToTry) {
      try {
        final inputImage = await _createInputImageWithFormat(image, format);
        if (inputImage != null) return inputImage;
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<InputImage?> _createInputImageWithFormat(
    CameraImage image,
    InputImageFormat format,
  ) async {
    try {
      Uint8List bytes;
      int bytesPerRow;

      switch (format) {
        case InputImageFormat.nv21:
          bytes = _createNV21Bytes(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.yuv420:
          bytes = _createYUV420Bytes(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.bgra8888:
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
          break;
        default:
          return null;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts YUV420 format to NV21 (interleaved UV plane).
  Uint8List _createNV21Bytes(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uvSize = (image.width * image.height) ~/ yuv420PlaneSizeDivisor;
    final nv21Bytes = Uint8List(ySize + 2 * uvSize);

    _copyPlaneWithStride(yPlane, nv21Bytes, 0, image.width, image.height);

    int uvIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      final uvPixelIndex =
          i ~/ image.width * (uPlane.bytesPerRow ~/ 2) + i % image.width;

      if (uvPixelIndex < vPlane.bytes.length &&
          uvPixelIndex < uPlane.bytes.length) {
        nv21Bytes[uvIndex++] = vPlane.bytes[uvPixelIndex];
        nv21Bytes[uvIndex++] = uPlane.bytes[uvPixelIndex];
      } else {
        final minLength = min(vPlane.bytes.length, uPlane.bytes.length);
        final safeIndex = i % minLength.toInt();
        nv21Bytes[uvIndex++] = vPlane.bytes[safeIndex];
        nv21Bytes[uvIndex++] = uPlane.bytes[safeIndex];
      }
    }

    return nv21Bytes;
  }

  /// Converts camera image to YUV420 format (planar: Y, then U, then V).
  Uint8List _createYUV420Bytes(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uSize = (image.width * image.height) ~/ yuv420PlaneSizeDivisor;
    final vSize = (image.width * image.height) ~/ yuv420PlaneSizeDivisor;
    final yuvBytes = Uint8List(ySize + uSize + vSize);

    _copyPlaneWithStride(yPlane, yuvBytes, 0, image.width, image.height);
    _copyPlaneWithStride(
      uPlane,
      yuvBytes,
      ySize,
      image.width ~/ yuv420DimensionDivisor,
      image.height ~/ yuv420DimensionDivisor,
    );
    _copyPlaneWithStride(
      vPlane,
      yuvBytes,
      ySize + uSize,
      image.width ~/ yuv420DimensionDivisor,
      image.height ~/ yuv420DimensionDivisor,
    );

    return yuvBytes;
  }

  /// Copies a plane's bytes accounting for stride (bytes per row).
  ///
  /// Handles cases where stride may differ from actual width.
  void _copyPlaneWithStride(
    Plane plane,
    Uint8List destination,
    int destOffset,
    int width,
    int height,
  ) {
    final srcBytes = plane.bytes;
    final srcStride = plane.bytesPerRow;

    for (int y = 0; y < height; y++) {
      final srcOffset = y * srcStride;
      final destStart = destOffset + y * width;
      final copyLength = min(width, srcBytes.length - srcOffset);

      if (copyLength > 0) {
        destination.setRange(
          destStart,
          destStart + copyLength,
          srcBytes,
          srcOffset,
        );
      }
    }
  }
}
