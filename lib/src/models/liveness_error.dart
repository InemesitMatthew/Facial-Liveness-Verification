/// Exception thrown during liveness detection operations.
///
/// Provides detailed error information including error codes,
/// user-friendly messages, and technical details for debugging.
class LivenessError implements Exception {
  /// Unique error code for programmatic handling.
  final LivenessErrorCode code;

  /// User-friendly error message suitable for display.
  final String message;

  /// Detailed technical description for debugging.
  final String? details;

  /// The original exception that caused this error (if any).
  final Object? originalException;

  /// Stack trace from the original exception (if any).
  final StackTrace? stackTrace;

  /// Additional context information.
  final Map<String, dynamic> context;

  /// Creates a new [LivenessError].
  const LivenessError({
    required this.code,
    required this.message,
    this.details,
    this.originalException,
    this.stackTrace,
    this.context = const {},
  });

  /// Creates a camera-related error.
  factory LivenessError.camera({
    required String message,
    String? details,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return LivenessError(
      code: LivenessErrorCode.cameraError,
      message: message,
      details: details,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Creates a permission-related error.
  factory LivenessError.permission({
    required String message,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.permissionDenied,
      message: message,
      details: details,
    );
  }

  /// Creates a face detection error.
  factory LivenessError.faceDetection({
    required String message,
    String? details,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return LivenessError(
      code: LivenessErrorCode.faceDetectionError,
      message: message,
      details: details,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Creates a timeout error.
  factory LivenessError.timeout({
    required Duration timeoutDuration,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.timeout,
      message: 'Verification timed out after ${timeoutDuration.inSeconds} seconds',
      details: details,
      context: {'timeoutDuration': timeoutDuration.inMilliseconds},
    );
  }

  /// Creates an error for exceeding maximum attempts.
  factory LivenessError.maxAttemptsExceeded({
    required int maxAttempts,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.maxAttemptsExceeded,
      message: 'Maximum verification attempts ($maxAttempts) exceeded',
      details: details,
      context: {'maxAttempts': maxAttempts},
    );
  }

  /// Creates an anti-spoofing detection error.
  factory LivenessError.antiSpoofing({
    required String message,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.antiSpoofingFailed,
      message: message,
      details: details,
    );
  }

  /// Creates a configuration error.
  factory LivenessError.configuration({
    required String message,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.configurationError,
      message: message,
      details: details,
    );
  }

  /// Creates a device compatibility error.
  factory LivenessError.deviceCompatibility({
    required String message,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.deviceNotSupported,
      message: message,
      details: details,
    );
  }

  /// Creates a user cancellation error.
  factory LivenessError.userCancelled() {
    return const LivenessError(
      code: LivenessErrorCode.userCancelled,
      message: 'Verification was cancelled by the user',
    );
  }

  /// Creates a generic error.
  factory LivenessError.generic({
    required String message,
    String? details,
    Object? originalException,
    StackTrace? stackTrace,
  }) {
    return LivenessError(
      code: LivenessErrorCode.unknown,
      message: message,
      details: details,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Whether this error is recoverable (user can retry).
  bool get isRecoverable {
    switch (code) {
      case LivenessErrorCode.userCancelled:
      case LivenessErrorCode.timeout:
      case LivenessErrorCode.antiSpoofingFailed:
        return true;
      case LivenessErrorCode.maxAttemptsExceeded:
      case LivenessErrorCode.permissionDenied:
      case LivenessErrorCode.deviceNotSupported:
      case LivenessErrorCode.configurationError:
        return false;
      case LivenessErrorCode.cameraError:
      case LivenessErrorCode.faceDetectionError:
      case LivenessErrorCode.unknown:
        return true; // May be recoverable depending on the specific issue
    }
  }

  /// Whether this error requires user action to resolve.
  bool get requiresUserAction {
    switch (code) {
      case LivenessErrorCode.permissionDenied:
      case LivenessErrorCode.userCancelled:
        return true;
      default:
        return false;
    }
  }

  /// Converts the error to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'code': code.name,
      'message': message,
      'details': details,
      'context': context,
      'isRecoverable': isRecoverable,
      'requiresUserAction': requiresUserAction,
    };
  }

  /// Creates an error from a JSON representation.
  factory LivenessError.fromJson(Map<String, dynamic> json) {
    final codeString = json['code'] as String;
    final code = LivenessErrorCode.values.firstWhere(
      (c) => c.name == codeString,
      orElse: () => LivenessErrorCode.unknown,
    );

    return LivenessError(
      code: code,
      message: json['message'] as String,
      details: json['details'] as String?,
      context: (json['context'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('LivenessError(${code.name}): $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LivenessError &&
            code == other.code &&
            message == other.message &&
            details == other.details;
  }

  @override
  int get hashCode => Object.hash(code, message, details);
}

/// Enumeration of possible liveness detection error codes.
enum LivenessErrorCode {
  /// Camera initialization or operation failed.
  cameraError,

  /// Camera permission was denied by the user.
  permissionDenied,

  /// Face detection processing failed.
  faceDetectionError,

  /// Verification session timed out.
  timeout,

  /// Maximum number of verification attempts exceeded.
  maxAttemptsExceeded,

  /// Anti-spoofing detection failed (potential spoofing detected).
  antiSpoofingFailed,

  /// Invalid configuration provided.
  configurationError,

  /// Device is not supported or compatible.
  deviceNotSupported,

  /// User cancelled the verification process.
  userCancelled,

  /// Unknown or unexpected error.
  unknown,
}

/// Extension to provide human-readable descriptions for error codes.
extension LivenessErrorCodeExtension on LivenessErrorCode {
  /// Returns a user-friendly description of the error code.
  String get description {
    switch (this) {
      case LivenessErrorCode.cameraError:
        return 'Camera initialization or operation failed';
      case LivenessErrorCode.permissionDenied:
        return 'Camera permission was denied';
      case LivenessErrorCode.faceDetectionError:
        return 'Face detection processing failed';
      case LivenessErrorCode.timeout:
        return 'Verification session timed out';
      case LivenessErrorCode.maxAttemptsExceeded:
        return 'Maximum verification attempts exceeded';
      case LivenessErrorCode.antiSpoofingFailed:
        return 'Potential spoofing attempt detected';
      case LivenessErrorCode.configurationError:
        return 'Invalid configuration provided';
      case LivenessErrorCode.deviceNotSupported:
        return 'Device is not supported or compatible';
      case LivenessErrorCode.userCancelled:
        return 'User cancelled the verification';
      case LivenessErrorCode.unknown:
        return 'An unexpected error occurred';
    }
  }

  /// Returns a suggested user action for resolving the error.
  String get userAction {
    switch (this) {
      case LivenessErrorCode.cameraError:
        return 'Please restart the app and try again. If the problem persists, check your device camera.';
      case LivenessErrorCode.permissionDenied:
        return 'Please grant camera permission in your device settings and try again.';
      case LivenessErrorCode.faceDetectionError:
        return 'Ensure you are in a well-lit area and your face is clearly visible.';
      case LivenessErrorCode.timeout:
        return 'Please try the verification again. Make sure to complete all challenges within the time limit.';
      case LivenessErrorCode.maxAttemptsExceeded:
        return 'Please wait before attempting verification again, or contact support if you continue having issues.';
      case LivenessErrorCode.antiSpoofingFailed:
        return 'Please ensure you are a real person in front of the camera and try again.';
      case LivenessErrorCode.configurationError:
        return 'There was a configuration error. Please contact support.';
      case LivenessErrorCode.deviceNotSupported:
        return 'Your device may not support this feature. Please try on a different device.';
      case LivenessErrorCode.userCancelled:
        return 'You can restart the verification process at any time.';
      case LivenessErrorCode.unknown:
        return 'Please try again. If the problem persists, contact support.';
    }
  }
}