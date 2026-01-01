import 'package:flutter/material.dart';

/// Utility functions for coordinate transformations between camera image space and screen space.
///
/// ML Kit returns face coordinates in the camera image coordinate system, which may differ
/// from the screen coordinate system due to aspect ratio differences and rotation.
/// These utilities help convert coordinates for UI overlays.
class CoordinateUtils {
  /// Converts a face bounding box from ML Kit image coordinates to screen coordinates.
  ///
  /// ML Kit returns coordinates in the camera image's coordinate system, which is rotated
  /// 270 degrees and may have different aspect ratios than the screen. This function handles:
  /// - Aspect ratio differences between camera preview and screen
  /// - Coordinate system rotation (ML Kit uses rotated coordinates)
  /// - Scaling to match screen dimensions
  ///
  /// **Parameters:**
  /// - [imageRect]: The face bounding box from ML Kit (in image coordinates)
  /// - [previewSize]: The actual camera preview size (from CameraController)
  /// - [screenSize]: The screen/widget size where you want to draw the overlay
  ///
  /// **Returns:** A [Rect] in screen coordinates that can be used for drawing overlays.
  ///
  /// **Example:**
  /// ```dart
  /// final faceBox = detector.faceBoundingBox; // From ML Kit
  /// final previewSize = detector.cameraController!.value.previewSize!;
  /// final screenSize = MediaQuery.of(context).size;
  ///
  /// final screenRect = CoordinateUtils.convertImageRectToScreenRect(
  ///   faceBox!,
  ///   previewSize,
  ///   screenSize,
  /// );
  ///
  /// // Now you can draw overlay at screenRect
  /// ```
  static Rect convertImageRectToScreenRect(
    Rect imageRect,
    Size previewSize,
    Size screenSize,
  ) {
    // Calculate aspect ratios to determine how the preview fits on screen
    final previewAspect = previewSize.height / previewSize.width;
    final screenAspect = screenSize.height / screenSize.width;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    // Determine scaling based on which dimension constrains the fit
    if (previewAspect > screenAspect) {
      // Preview is taller - height determines scale
      scale = screenSize.height / previewSize.height;
      offsetX = (screenSize.width - previewSize.width * scale) / 2;
    } else {
      // Preview is wider - width determines scale
      scale = screenSize.width / previewSize.width;
      offsetY = (screenSize.height - previewSize.height * scale) / 2;
    }

    // ML Kit coordinates are rotated 270 degrees, so we need to transform:
    // - top becomes left
    // - right becomes top
    // - bottom becomes right
    // - left becomes bottom
    final originalImageHeight = previewSize.height.toDouble();

    final transformedLeft = imageRect.top * scale + offsetX;
    final transformedTop =
        (originalImageHeight - imageRect.right) * scale + offsetY;
    final transformedWidth = imageRect.height * scale;
    final transformedHeight = imageRect.width * scale;

    return Rect.fromLTWH(
      transformedLeft,
      transformedTop,
      transformedWidth,
      transformedHeight,
    );
  }

  /// Calculates a target rectangle for face positioning guidance.
  ///
  /// Creates a centered oval/rectangle that indicates where the user should position
  /// their face. This is useful for UI overlays that guide users to center their face.
  ///
  /// **Parameters:**
  /// - [screenSize]: The screen/widget size
  /// - [widthRatio]: Width of target as ratio of screen width (default: 0.65 = 65%)
  /// - [heightRatio]: Height of target as ratio of target width (default: 1.1 = 110%)
  ///
  /// **Returns:** A [Rect] centered on screen, suitable for drawing an oval guide.
  ///
  /// **Example:**
  /// ```dart
  /// final screenSize = MediaQuery.of(context).size;
  /// final targetRect = CoordinateUtils.calculateTargetRect(screenSize);
  ///
  /// // Draw oval at targetRect to guide user
  /// ```
  static Rect calculateTargetRect(
    Size screenSize, {
    double widthRatio = 0.65,
    double heightRatio = 1.1,
  }) {
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final targetWidth = screenSize.width * widthRatio;
    final targetHeight = targetWidth * heightRatio;

    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: targetWidth,
      height: targetHeight,
    );
  }
}
