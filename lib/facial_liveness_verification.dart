/// Facial Liveness Verification Package
/// 
/// A comprehensive Flutter package for real-time facial liveness verification 
/// using advanced anti-spoofing techniques, challenge-based verification,
/// and customizable UI components.
library;
/// ## Features
/// 
/// - **Real-time face detection** using Google ML Kit
/// - **Advanced anti-spoofing protection** with motion analysis
/// - **Interactive challenge system** (smile, blink, head turns)
/// - **Customizable UI and theming** for brand consistency  
/// - **Comprehensive error handling** with recovery options
/// - **Performance optimized** for various device capabilities
/// - **Easy integration** with callback-based API
///
/// ## Quick Start
/// 
/// ```dart
/// import 'package:facial_liveness_verification/facial_liveness_verification.dart';
/// 
/// LivenessDetectionWidget(
///   config: LivenessConfig.secure(),
///   onLivenessDetected: (result) {
///     print('Verification successful: ${result.confidence}');
///   },
///   onError: (error) {
///     print('Verification failed: ${error.message}');
///   },
/// )
/// ```
///
/// For more examples and documentation, see the README file.

// Core API exports
export 'src/core/liveness_detector.dart';

// Configuration exports  
export 'src/models/liveness_config.dart';
export 'src/models/liveness_theme.dart';
export 'src/models/liveness_result.dart';
export 'src/models/liveness_error.dart';
export 'src/models/challenge_types.dart';

// Widget exports
export 'src/widgets/liveness_detection_widget.dart';
export 'src/widgets/simple_liveness_widget.dart';

// Utility exports that might be useful for advanced usage
export 'src/utils/liveness_constants.dart' show 
  UIConstants, 
  ErrorMessages, 
  SuccessMessages;

// Engine exports for advanced customization (optional)
export 'src/core/anti_spoofing_engine.dart';
export 'src/core/challenge_system.dart';