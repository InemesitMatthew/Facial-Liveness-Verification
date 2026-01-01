/// Constants used throughout the liveness verification package.
///
/// Centralizes magic numbers and thresholds for easier maintenance and configuration.
library;

/// Minimum number of frames required before anti-spoofing analysis.
const int minFramesForAnalysis = 10;

/// Minimum face area in pixels for a face to be considered valid.
const double minFaceAreaPixels = 1000.0;

/// Minimum aspect ratio for a valid face bounding box.
const double minFaceAspectRatio = 0.4;

/// Maximum aspect ratio for a valid face bounding box.
const double maxFaceAspectRatio = 2.5;

/// Threshold for detecting static frames (minimal movement between frames).
const double staticFrameThreshold = 0.1;

/// Multiplier for relaxed centering tolerance (1.5x normal tolerance).
const double relaxedCenteringMultiplier = 1.5;

/// Multiplier for head angle threshold in nod/head shake validation (0.8x).
const double headAngleMultiplier = 0.8;

/// Threshold for detecting eye closure (below this = closed).
const double eyeClosedThreshold = 0.35;

/// Threshold for detecting eye opening (above this = open).
const double eyeOpenThreshold = 0.65;

/// Threshold for neutral smile probability (below this = neutral).
const double neutralSmileThreshold = 0.35;

/// Threshold for neutral head angle (below this = centered).
const double neutralHeadAngleThreshold = 12.0;

/// Maximum time in milliseconds for a blink to complete.
const int maxBlinkDurationMs = 1000;

/// YUV420 format: U and V planes are 1/4 the size of Y plane.
const int yuv420PlaneSizeDivisor = 4;

/// YUV420 format: U and V planes are 1/2 the width and height of Y plane.
const int yuv420DimensionDivisor = 2;

