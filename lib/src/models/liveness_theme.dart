import 'package:flutter/material.dart';

/// Theming configuration for the liveness detection UI.
///
/// Allows complete customization of colors, text styles, and visual elements
/// to match your app's design system.
class LivenessTheme {
  /// Background color for the camera view
  final Color backgroundColor;

  /// Primary accent color used for active states
  final Color primaryColor;

  /// Success color for completed challenges and positive feedback
  final Color successColor;

  /// Warning color for guidance and positioning feedback
  final Color warningColor;

  /// Error color for failed attempts and error states
  final Color errorColor;

  /// Color for text content
  final Color textColor;

  /// Color for secondary text and labels
  final Color secondaryTextColor;

  /// Text style for main instructions
  final TextStyle instructionTextStyle;

  /// Text style for challenge descriptions
  final TextStyle challengeTextStyle;

  /// Text style for status information
  final TextStyle statusTextStyle;

  /// Text style for progress indicators
  final TextStyle progressTextStyle;

  /// Border radius for UI panels and overlays
  final BorderRadius borderRadius;

  /// Background color for instruction panels
  final Color panelBackgroundColor;

  /// Border color for UI panels
  final Color panelBorderColor;

  /// Face guide circle color when face is not detected
  final Color guideCircleInactiveColor;

  /// Face guide circle color when face is detected
  final Color guideCircleActiveColor;

  /// Face guide circle color when liveness is verified
  final Color guideCircleVerifiedColor;

  /// Face bounding box color
  final Color faceBoundingBoxColor;

  /// Animation duration for UI transitions
  final Duration animationDuration;

  /// Creates a new [LivenessTheme] with the specified configuration.
  const LivenessTheme({
    required this.backgroundColor,
    required this.primaryColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.instructionTextStyle,
    required this.challengeTextStyle,
    required this.statusTextStyle,
    required this.progressTextStyle,
    required this.borderRadius,
    required this.panelBackgroundColor,
    required this.panelBorderColor,
    required this.guideCircleInactiveColor,
    required this.guideCircleActiveColor,
    required this.guideCircleVerifiedColor,
    required this.faceBoundingBoxColor,
    required this.animationDuration,
  });

  /// Creates a light theme configuration.
  factory LivenessTheme.light() {
    return LivenessTheme(
      backgroundColor: Colors.white,
      primaryColor: Colors.blue,
      successColor: Colors.green,
      warningColor: Colors.amber,
      errorColor: Colors.red,
      textColor: Colors.black87,
      secondaryTextColor: Colors.black54,
      instructionTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      challengeTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      statusTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      progressTextStyle: const TextStyle(
        color: Colors.black54,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      borderRadius: BorderRadius.circular(12),
      panelBackgroundColor: Colors.white.withOpacity(0.9),
      panelBorderColor: Colors.blue,
      guideCircleInactiveColor: Colors.grey,
      guideCircleActiveColor: Colors.blue,
      guideCircleVerifiedColor: Colors.green,
      faceBoundingBoxColor: Colors.green,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Creates a dark theme configuration.
  factory LivenessTheme.dark() {
    return LivenessTheme(
      backgroundColor: Colors.black,
      primaryColor: Colors.amberAccent,
      successColor: Colors.green,
      warningColor: Colors.orange,
      errorColor: Colors.red,
      textColor: Colors.white,
      secondaryTextColor: Colors.white70,
      instructionTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      challengeTextStyle: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      statusTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      progressTextStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      borderRadius: BorderRadius.circular(12),
      panelBackgroundColor: Colors.black.withOpacity(0.8),
      panelBorderColor: Colors.amberAccent,
      guideCircleInactiveColor: Colors.grey,
      guideCircleActiveColor: Colors.orange,
      guideCircleVerifiedColor: Colors.green,
      faceBoundingBoxColor: Colors.green,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Creates a copy of this theme with the specified changes.
  LivenessTheme copyWith({
    Color? backgroundColor,
    Color? primaryColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? textColor,
    Color? secondaryTextColor,
    TextStyle? instructionTextStyle,
    TextStyle? challengeTextStyle,
    TextStyle? statusTextStyle,
    TextStyle? progressTextStyle,
    BorderRadius? borderRadius,
    Color? panelBackgroundColor,
    Color? panelBorderColor,
    Color? guideCircleInactiveColor,
    Color? guideCircleActiveColor,
    Color? guideCircleVerifiedColor,
    Color? faceBoundingBoxColor,
    Duration? animationDuration,
  }) {
    return LivenessTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      primaryColor: primaryColor ?? this.primaryColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      instructionTextStyle: instructionTextStyle ?? this.instructionTextStyle,
      challengeTextStyle: challengeTextStyle ?? this.challengeTextStyle,
      statusTextStyle: statusTextStyle ?? this.statusTextStyle,
      progressTextStyle: progressTextStyle ?? this.progressTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      guideCircleInactiveColor: guideCircleInactiveColor ?? this.guideCircleInactiveColor,
      guideCircleActiveColor: guideCircleActiveColor ?? this.guideCircleActiveColor,
      guideCircleVerifiedColor: guideCircleVerifiedColor ?? this.guideCircleVerifiedColor,
      faceBoundingBoxColor: faceBoundingBoxColor ?? this.faceBoundingBoxColor,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}