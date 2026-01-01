/// External package dependencies and type re-exports.
///
/// Centralizes external package imports for cleaner internal code organization.
library;

// Camera package exports
export 'package:camera/camera.dart' show
    CameraController,
    CameraImage,
    ResolutionPreset,
    availableCameras,
    CameraLensDirection,
    ImageFormatGroup,
    Plane;

// Google ML Kit Face Detection exports
export 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart' show
    Face,
    FaceDetector,
    FaceDetectorOptions,
    FaceDetectorMode,
    InputImage,
    InputImageFormat,
    InputImageMetadata,
    InputImageRotation;

// Flutter services and UI
export 'package:flutter/services.dart' show Uint8List;
export 'package:flutter/material.dart' show Size, Rect;

