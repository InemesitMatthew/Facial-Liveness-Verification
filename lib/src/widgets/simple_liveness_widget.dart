import 'package:flutter/material.dart';
import '../models/liveness_config.dart';
import '../models/liveness_result.dart';
import '../models/liveness_error.dart';
import 'liveness_detection_widget.dart';

/// A super simple, plug-and-play liveness detection widget.
/// 
/// This widget provides the easiest possible integration for developers
/// who just want to add liveness detection to their app with minimal code.
/// 
/// Example usage:
/// ```dart
/// SimpleLivenessWidget(
///   onSuccess: (result) => print('User is live!'),
///   onFailure: (error) => print('Verification failed'),
/// )
/// ```
class SimpleLivenessWidget extends StatelessWidget {
  /// Called when liveness verification succeeds
  final void Function(LivenessResult result) onSuccess;
  
  /// Called when liveness verification fails
  final void Function(LivenessError error) onFailure;
  
  /// Optional configuration - defaults to LivenessConfig.minimal() for easiest use
  final LivenessConfig? config;
  
  /// Optional title for the verification screen
  final String? title;
  
  /// Optional subtitle/instructions for the user
  final String? subtitle;

  const SimpleLivenessWidget({
    super.key,
    required this.onSuccess,
    required this.onFailure,
    this.config,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LivenessDetectionWidget(
      config: config ?? LivenessConfig.minimal(),
      onLivenessDetected: onSuccess,
      onError: onFailure,
      onProgress: (challenge, progress) {
        // Optional: Add progress logging for debugging
        debugPrint('Liveness progress: ${challenge.name} - ${progress.type.name}');
      },
      onCancel: () {
        // Handle cancellation
        Navigator.of(context).pop();
      },
    );
  }
}

/// A one-liner function for the ultimate plug-and-play experience.
/// 
/// Just call this function and you get a complete liveness detection flow!
/// 
/// Example:
/// ```dart
/// await showLivenessCheck(
///   context: context,
///   onSuccess: (result) => print('Verified!'),
///   onFailure: (error) => print('Failed!'),
/// );
/// ```
Future<void> showLivenessCheck({
  required BuildContext context,
  required void Function(LivenessResult result) onSuccess,
  required void Function(LivenessError error) onFailure,
  LivenessConfig? config,
  String? title,
  String? subtitle,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title ?? 'Verify Identity'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SimpleLivenessWidget(
          onSuccess: (result) {
            Navigator.of(context).pop();
            onSuccess(result);
          },
          onFailure: (error) {
            Navigator.of(context).pop();
            onFailure(error);
          },
          config: config,
          title: title,
          subtitle: subtitle,
        ),
      ),
    ),
  );
}
