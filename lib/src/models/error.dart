/// Exception thrown during liveness verification operations.
///
/// Provides error codes, messages, and recovery information via extensions.
class LivenessError implements Exception {
  final LivenessErrorCode code;
  final String message;
  final String? details;
  final Object? originalException;
  final StackTrace? stackTrace;
  final Map<String, dynamic> context;

  const LivenessError({
    required this.code,
    required this.message,
    this.details,
    this.originalException,
    this.stackTrace,
    this.context = const {},
  });

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

  factory LivenessError.timeout({
    required Duration timeoutDuration,
    String? details,
  }) {
    return LivenessError(
      code: LivenessErrorCode.timeout,
      message:
          'Verification timed out after ${timeoutDuration.inSeconds} seconds',
      details: details,
      context: {'timeoutDuration': timeoutDuration.inMilliseconds},
    );
  }

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

  factory LivenessError.userCancelled() {
    return const LivenessError(
      code: LivenessErrorCode.userCancelled,
      message: 'Verification was cancelled by the user',
    );
  }

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
        return true;
    }
  }

  bool get requiresUserAction {
    switch (code) {
      case LivenessErrorCode.permissionDenied:
      case LivenessErrorCode.userCancelled:
        return true;
      default:
        return false;
    }
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
}

enum LivenessErrorCode {
  cameraError,
  permissionDenied,
  faceDetectionError,
  timeout,
  maxAttemptsExceeded,
  antiSpoofingFailed,
  configurationError,
  deviceNotSupported,
  userCancelled,
  unknown,
}

extension LivenessErrorCodeExtension on LivenessErrorCode {
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
