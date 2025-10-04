import 'dart:math';
import 'package:flutter/material.dart';

import '../core/challenge_system.dart';
import '../models/liveness_config.dart';
import '../models/challenge_types.dart';
import '../utils/liveness_constants.dart';

/// Custom painter for the liveness detection overlay.
///
/// Draws face guidance, challenge indicators, bounding boxes, and visual feedback
/// to guide users through the verification process.
class LivenessOverlayPainter extends CustomPainter {
  final LivenessConfig config;
  final double animationValue;
  final bool isFaceDetected;
  final bool isPositionedCorrectly;
  final Rect? faceBoundingBox;
  final ChallengeType? currentChallenge;
  final ChallengeSystem? challengeSystem;

  LivenessOverlayPainter({
    required this.config,
    required this.animationValue,
    required this.isFaceDetected,
    required this.isPositionedCorrectly,
    this.faceBoundingBox,
    this.currentChallenge,
    this.challengeSystem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFaceMask(canvas, size);
    _drawGuideCircle(canvas, size);
    
    if (faceBoundingBox != null) {
      _drawFaceBoundingBox(canvas);
      _drawPositioningStatus(canvas, size);
    }

    _drawCornerGuides(canvas, size);
    
    if (currentChallenge != null) {
      _drawChallengeIndicator(canvas, size);
    }
  }

  /// Draws the semi-transparent mask with circular cutout for face guidance.
  void _drawFaceMask(Canvas canvas, Size size) {
    final center = _getGuideCircleCenter(size);
    final radius = _getGuideCircleRadius(size);
    final animatedRadius = radius + (animationValue * 10);

    final maskPaint = Paint()
      ..color = config.theme.backgroundColor.withValues(alpha:0.7)
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: animatedRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);
  }

  /// Draws the main face guide circle.
  void _drawGuideCircle(Canvas canvas, Size size) {
    final center = _getGuideCircleCenter(size);
    final radius = _getGuideCircleRadius(size);
    final animatedRadius = radius + (animationValue * 10);

    final guideColor = _getGuideCircleColor();
    final guideAlpha = _getGuideCircleAlpha();

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha:guideAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = UIConstants.guideCircleStrokeWidth;

    canvas.drawCircle(center, animatedRadius, guidePaint);

    // Draw inner pulse ring for better visibility
    if (isPositionedCorrectly) {
      final innerPaint = Paint()
        ..color = guideColor.withValues(alpha:guideAlpha * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, animatedRadius - 8, innerPaint);
    }
  }

  /// Draws the face bounding box when a face is detected.
  void _drawFaceBoundingBox(Canvas canvas) {
    if (faceBoundingBox == null) return;

    final boxColor = _getFaceBoundingBoxColor();
    final boxPaint = Paint()
      ..color = boxColor.withValues(alpha:0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = UIConstants.faceBoundingBoxStrokeWidth;

    canvas.drawRect(faceBoundingBox!, boxPaint);

    // Draw corner indicators
    _drawFaceCorners(canvas, faceBoundingBox!, boxColor);

    // Draw center point
    final centerPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(faceBoundingBox!.center, 3.0, centerPaint);
  }

  /// Draws corner indicators on the face bounding box.
  void _drawFaceCorners(Canvas canvas, Rect box, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = UIConstants.cornerIndicatorLength;
    final corners = [
      box.topLeft,
      box.topRight,
      box.bottomLeft,
      box.bottomRight,
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx + cornerLength * (corner.dx < box.center.dx ? 1 : -1),
          corner.dy,
        )
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx,
          corner.dy + cornerLength * (corner.dy < box.center.dy ? 1 : -1),
        );

      canvas.drawPath(path, cornerPaint);
    }
  }

  /// Draws positioning status text near the face.
  void _drawPositioningStatus(Canvas canvas, Size size) {
    if (!isFaceDetected || faceBoundingBox == null) return;

    final center = _getGuideCircleCenter(size);
    final radius = _getGuideCircleRadius(size);
    final color = _getGuideCircleColor();

    final textPainter = TextPainter(
      text: TextSpan(
        text: isPositionedCorrectly ? 'Face Positioned ✓' : 'Positioning...',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final textPosition = Offset(
      center.dx - textPainter.width / 2,
      center.dy + radius + 20,
    );

    // Draw background
    final backgroundRect = Rect.fromLTWH(
      textPosition.dx - 10,
      textPosition.dy - 5,
      textPainter.width + 20,
      textPainter.height + 10,
    );

    final backgroundPaint = Paint()
      ..color = config.theme.backgroundColor.withValues(alpha:0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      backgroundPaint,
    );

    textPainter.paint(canvas, textPosition);
  }

  /// Draws corner guides around the guide circle.
  void _drawCornerGuides(Canvas canvas, Size size) {
    final center = _getGuideCircleCenter(size);
    final radius = _getGuideCircleRadius(size);
    final color = _getGuideCircleColor();

    final cornerPaint = Paint()
      ..color = color.withValues(alpha:0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerLength = UIConstants.cornerGuideLength;
    final corners = [
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius),
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx + cornerLength * (corner.dx < center.dx ? 1 : -1),
          corner.dy,
        )
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx,
          corner.dy + cornerLength * (corner.dy < center.dy ? 1 : -1),
        );

      canvas.drawPath(path, cornerPaint);
    }
  }

  /// Draws challenge-specific indicators.
  void _drawChallengeIndicator(Canvas canvas, Size size) {
    if (currentChallenge == null || !isPositionedCorrectly) return;

    final center = _getGuideCircleCenter(size);
    final color = config.theme.primaryColor;

    // Draw challenge emoji/icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: currentChallenge!.emoji,
        style: const TextStyle(fontSize: 32),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final emojiPosition = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    // Draw background circle for emoji
    final emojiBackgroundPaint = Paint()
      ..color = color.withValues(alpha:0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 30, emojiBackgroundPaint);

    textPainter.paint(canvas, emojiPosition);

    // Draw animated ring for active challenge
    final ringPaint = Paint()
      ..color = color.withValues(alpha:0.6 + animationValue * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, 35 + animationValue * 5, ringPaint);

    // Draw progress arc for timed challenges
    if (challengeSystem != null && challengeSystem!.currentChallengeIndex >= 0) {
      _drawChallengeProgressArc(canvas, center, color);
    }
  }

  /// Draws a progress arc for challenge timing.
  void _drawChallengeProgressArc(Canvas canvas, Offset center, Color color) {
    // This would show progress based on challenge timing
    // For now, we'll show a simple pulsing ring
    final progressPaint = Paint()
      ..color = color.withValues(alpha:0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: 50);
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * animationValue;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  /// Gets the center point of the guide circle.
  Offset _getGuideCircleCenter(Size size) {
    return Offset(
      size.width / 2,
      size.height / 2 + UIConstants.guideCircleOffset,
    );
  }

  /// Gets the radius of the guide circle.
  double _getGuideCircleRadius(Size size) {
    return size.width * config.faceConstraints.guideCircleRadius;
  }

  /// Gets the appropriate color for the guide circle based on current state.
  Color _getGuideCircleColor() {
    if (isPositionedCorrectly) {
      return config.theme.guideCircleVerifiedColor;
    } else if (isFaceDetected) {
      return config.theme.guideCircleActiveColor;
    } else {
      return config.theme.guideCircleInactiveColor;
    }
  }

  /// Gets the appropriate alpha/opacity for the guide circle.
  double _getGuideCircleAlpha() {
    if (isPositionedCorrectly) {
      return 0.8 + animationValue * 0.2;
    } else if (isFaceDetected) {
      return 0.6 + animationValue * 0.3;
    } else {
      return 0.3 + animationValue * 0.1;
    }
  }

  /// Gets the appropriate color for the face bounding box.
  Color _getFaceBoundingBoxColor() {
    if (isPositionedCorrectly) {
      return config.theme.successColor;
    } else if (isFaceDetected) {
      return config.theme.warningColor;
    } else {
      return config.theme.errorColor;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! LivenessOverlayPainter ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.isFaceDetected != isFaceDetected ||
           oldDelegate.isPositionedCorrectly != isPositionedCorrectly ||
           oldDelegate.faceBoundingBox != faceBoundingBox ||
           oldDelegate.currentChallenge != currentChallenge;
  }
}

/// Enhanced version of the original head mask painter with additional features.
class EnhancedHeadMaskPainter extends CustomPainter {
  final double animationValue;
  final bool isFaceQualityGood;
  final Rect? faceBoundingBox;
  final bool isLivenessVerified;
  final bool isFaceDetected;
  final LivenessConfig config;

  EnhancedHeadMaskPainter({
    required this.animationValue,
    required this.isFaceQualityGood,
    this.faceBoundingBox,
    required this.isLivenessVerified,
    required this.isFaceDetected,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + UIConstants.guideCircleOffset);
    final baseRadius = size.width * config.faceConstraints.guideCircleRadius;
    final animatedRadius = baseRadius + (animationValue * 10);

    // Background mask
    final maskPaint = Paint()
      ..color = config.theme.backgroundColor.withValues(alpha:0.7)
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: animatedRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    // Guide circle with dynamic colors
    Color guideColor;
    double guideAlpha;

    if (isLivenessVerified) {
      guideColor = config.theme.successColor;
      guideAlpha = 0.8 + animationValue * 0.2;
    } else if (isFaceQualityGood && faceBoundingBox != null) {
      guideColor = config.theme.primaryColor;
      guideAlpha = 0.6 + animationValue * 0.3;
    } else if (isFaceDetected) {
      guideColor = config.theme.warningColor;
      guideAlpha = 0.4 + animationValue * 0.2;
    } else {
      guideColor = config.theme.errorColor;
      guideAlpha = 0.3 + animationValue * 0.1;
    }

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha:guideAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = UIConstants.guideCircleStrokeWidth;

    canvas.drawCircle(center, animatedRadius, guidePaint);

    // Face bounding box
    if (faceBoundingBox != null) {
      _drawFaceBoundingBox(canvas, guideColor);
      _drawPositioningStatus(canvas, size, center, animatedRadius, guideColor);
    }

    // Corner guides
    _drawCornerGuides(canvas, center, animatedRadius, guideColor);
  }

  void _drawPositioningStatus(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
  ) {
    if (faceBoundingBox == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Face Detected ✓',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final textPosition = Offset(
      center.dx - textPainter.width / 2,
      center.dy + radius + 20,
    );

    final backgroundRect = Rect.fromLTWH(
      textPosition.dx - 10,
      textPosition.dy - 5,
      textPainter.width + 20,
      textPainter.height + 10,
    );

    final backgroundPaint = Paint()
      ..color = config.theme.backgroundColor.withValues(alpha:0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      backgroundPaint,
    );

    textPainter.paint(canvas, textPosition);
  }

  void _drawFaceBoundingBox(Canvas canvas, Color color) {
    if (faceBoundingBox == null) return;

    final boxPaint = Paint()
      ..color = color.withValues(alpha:0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = UIConstants.faceBoundingBoxStrokeWidth;

    canvas.drawRect(faceBoundingBox!, boxPaint);

    // Corner indicators
    final cornerLength = UIConstants.cornerIndicatorLength;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final corners = [
      faceBoundingBox!.topLeft,
      faceBoundingBox!.topRight,
      faceBoundingBox!.bottomLeft,
      faceBoundingBox!.bottomRight,
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx + cornerLength * (corner.dx < faceBoundingBox!.center.dx ? 1 : -1),
          corner.dy,
        )
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx,
          corner.dy + cornerLength * (corner.dy < faceBoundingBox!.center.dy ? 1 : -1),
        );

      canvas.drawPath(path, cornerPaint);
    }

    // Center point
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(faceBoundingBox!.center, 3.0, centerPaint);
  }

  void _drawCornerGuides(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final cornerPaint = Paint()
      ..color = color.withValues(alpha:0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerLength = UIConstants.cornerGuideLength;
    final corners = [
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius),
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx + cornerLength * (corner.dx < center.dx ? 1 : -1),
          corner.dy,
        )
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx,
          corner.dy + cornerLength * (corner.dy < center.dy ? 1 : -1),
        );

      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
