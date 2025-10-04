import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../core/liveness_detector.dart';
import '../core/challenge_system.dart';
import '../models/liveness_config.dart';
import '../models/liveness_result.dart';
import '../models/liveness_error.dart';
import '../models/challenge_types.dart';
import '../painters/liveness_overlay_painter.dart';
import '../utils/liveness_constants.dart';

/// Main widget for facial liveness detection.
///
/// This widget provides a complete liveness verification interface with
/// camera preview, real-time face detection, challenge system, and anti-spoofing protection.
///
/// ## Basic Usage
/// ```dart
/// LivenessDetectionWidget(
///   onLivenessDetected: (result) {
///     print('Verification successful: ${result.isVerified}');
///   },
///   onError: (error) {
///     print('Verification failed: ${error.message}');
///   },
/// )
/// ```
///
/// ## Advanced Usage
/// ```dart
/// LivenessDetectionWidget(
///   config: LivenessConfig.secure(),
///   onLivenessDetected: (result) => handleSuccess(result),
///   onProgress: (challenge, progress) => updateProgress(progress),
///   onError: (error) => handleError(error),
///   onCancel: () => Navigator.pop(context),
/// )
/// ```
class LivenessDetectionWidget extends StatefulWidget {
  /// Configuration for the liveness detection behavior and appearance.
  final LivenessConfig config;

  /// Called when liveness verification is completed successfully.
  final void Function(LivenessResult result) onLivenessDetected;

  /// Called when an error occurs during verification.
  final void Function(LivenessError error) onError;

  /// Called when verification progress is updated.
  /// Provides the current challenge and progress information.
  final void Function(ChallengeType challenge, ChallengeProgress progress)? onProgress;

  /// Called when the user cancels the verification process.
  final VoidCallback? onCancel;

  /// Called when a challenge is completed successfully.
  final void Function(ChallengeType completedChallenge, ChallengeType? nextChallenge)? onChallengeCompleted;

  /// Called when camera is initialized and ready.
  final VoidCallback? onCameraReady;

  /// Called when a face is detected for the first time.
  final VoidCallback? onFaceDetected;

  /// Called when face positioning is correct and ready for challenges.
  final VoidCallback? onFacePositioned;

  /// Custom app bar widget. If null, a default app bar is shown.
  final PreferredSizeWidget? appBar;

  /// Whether to show the default app bar. Default is true.
  final bool showAppBar;

  /// Whether to show debug information overlay. Default is false.
  final bool showDebugInfo;

  /// Custom loading widget shown during initialization.
  final Widget? customLoadingWidget;

  /// Custom error widget builder for error states.
  final Widget Function(LivenessError error)? customErrorWidget;

  /// Creates a new liveness detection widget.
  LivenessDetectionWidget({
    super.key,
    LivenessConfig? config,
    required this.onLivenessDetected,
    required this.onError,
    this.onProgress,
    this.onCancel,
    this.onChallengeCompleted,
    this.onCameraReady,
    this.onFaceDetected,
    this.onFacePositioned,
    this.appBar,
    this.showAppBar = true,
    this.showDebugInfo = false,
    this.customLoadingWidget,
    this.customErrorWidget,
  }) : config = config ?? LivenessConfig();

  @override
  State<LivenessDetectionWidget> createState() => _LivenessDetectionWidgetState();
}

class _LivenessDetectionWidgetState extends State<LivenessDetectionWidget>
    with TickerProviderStateMixin {
  
  late LivenessDetector _detector;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription<LivenessDetectionState>? _stateSubscription;
  StreamSubscription<ChallengeProgress>? _progressSubscription;

  // UI State
  bool _isInitialized = false;
  bool _hasError = false;
  LivenessError? _currentError;
  String _instructionMessage = 'Initializing camera...';
  bool _isFaceDetected = false;
  bool _isPositionedCorrectly = false;
  ChallengeType? _currentChallenge;
  ChallengeProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDetector();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.config.theme.animationDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void _initializeDetector() {
    _detector = LivenessDetector(widget.config);
    
    // Listen to state changes
    _stateSubscription = _detector.stateStream.listen(_handleStateChange);
    _progressSubscription = _detector.progressStream.listen(_handleProgressChange);

    // Initialize the detector
    _detector.initialize().then((_) {
      if (mounted) {
        _detector.startDetection();
        widget.onCameraReady?.call();
      }
    }).catchError((error) {
      if (mounted) {
        _handleError(error is LivenessError ? error : 
                   LivenessError.generic(message: error.toString()));
      }
    });
  }

  void _handleStateChange(LivenessDetectionState state) {
    if (!mounted) return;

    setState(() {
      switch (state.type) {
        case LivenessDetectionStateType.initialized:
          _isInitialized = true;
          _instructionMessage = 'Camera ready - position your face in the circle';
          break;

        case LivenessDetectionStateType.detecting:
          _instructionMessage = 'Looking for your face...';
          break;

        case LivenessDetectionStateType.noFace:
          _isFaceDetected = false;
          _isPositionedCorrectly = false;
          _instructionMessage = state.message ?? 'Please position your face in view';
          break;

        case LivenessDetectionStateType.faceDetected:
          if (!_isFaceDetected) {
            _isFaceDetected = true;
            widget.onFaceDetected?.call();
          }
          break;

        case LivenessDetectionStateType.positioning:
          _isPositionedCorrectly = false;
          _instructionMessage = state.message ?? 'Position your face correctly';
          break;

        case LivenessDetectionStateType.positioned:
          if (!_isPositionedCorrectly) {
            _isPositionedCorrectly = true;
            widget.onFacePositioned?.call();
          }
          _instructionMessage = state.message ?? 'Ready for verification!';
          break;

        case LivenessDetectionStateType.challengeCompleted:
          if (state.completedChallenge != null && state.nextChallenge != null) {
            widget.onChallengeCompleted?.call(state.completedChallenge!, state.nextChallenge);
            _instructionMessage = 'Great! Challenge completed successfully! 🎉';
          }
          break;

        case LivenessDetectionStateType.challengeTimeout:
          _instructionMessage = 'Challenge timed out - please try again';
          break;

        case LivenessDetectionStateType.completed:
          if (state.result != null) {
            widget.onLivenessDetected(state.result!);
          }
          break;

        case LivenessDetectionStateType.error:
          if (state.error != null) {
            _handleError(state.error!);
          }
          break;
      }
    });
  }

  void _handleProgressChange(ChallengeProgress progress) {
    if (!mounted) return;

    setState(() {
      _currentProgress = progress;
      
      switch (progress.type) {
        case ChallengeProgressType.inProgress:
          _currentChallenge = progress.currentChallenge;
          _instructionMessage = 'Please ${progress.currentChallenge.instruction}';
          break;

        case ChallengeProgressType.challengeCompleted:
          _instructionMessage = SuccessMessages.challengeCompleted;
          break;

        case ChallengeProgressType.allCompleted:
          _instructionMessage = SuccessMessages.verificationComplete;
          break;

        case ChallengeProgressType.waitingForNeutral:
          _instructionMessage = 'Please return to neutral position';
          break;

        case ChallengeProgressType.neutralPositionReached:
          _instructionMessage = 'Good! Now ready for the next challenge';
          break;

        case ChallengeProgressType.timeout:
          _instructionMessage = 'Challenge timed out - please try again';
          break;

        case ChallengeProgressType.error:
          _instructionMessage = progress.error ?? 'An error occurred';
          break;
      }

      // Notify about progress
      widget.onProgress?.call(progress.currentChallenge, progress);
    });
  }

  void _handleError(LivenessError error) {
    setState(() {
      _hasError = true;
      _currentError = error;
      _instructionMessage = error.message;
    });

    widget.onError(error);
  }

  void _retryVerification() {
    setState(() {
      _hasError = false;
      _currentError = null;
      _instructionMessage = 'Retrying...';
    });

    _detector.dispose().then((_) {
      _initializeDetector();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.config.theme.backgroundColor,
      appBar: widget.showAppBar ? _buildAppBar() : null,
      body: _hasError ? _buildErrorView() : _buildMainView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (widget.appBar != null) return widget.appBar!;

    return AppBar(
      backgroundColor: widget.config.theme.backgroundColor,
      foregroundColor: widget.config.theme.textColor,
      elevation: 0,
      title: Text(
        'Verify Your Identity',
        style: widget.config.theme.instructionTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      leading: widget.onCancel != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onCancel,
            )
          : null,
    );
  }

  Widget _buildMainView() {
    if (!_isInitialized || _detector.cameraController == null) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: ClipRRect(
            borderRadius: widget.config.theme.borderRadius,
            child: CameraPreview(_detector.cameraController!),
          ),
        ),

        // Overlay with face guidance
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: LivenessOverlayPainter(
                config: widget.config,
                animationValue: _pulseAnimation.value,
                isFaceDetected: _isFaceDetected,
                isPositionedCorrectly: _isPositionedCorrectly,
                faceBoundingBox: _detector.faceBoundingBox,
                currentChallenge: _currentChallenge,
                challengeSystem: _detector.challengeSystem,
              ),
              child: Container(),
            );
          },
        ),

        // Instruction panel
        _buildInstructionPanel(),

        // Progress panel
        _buildProgressPanel(),

        // Status panel
        _buildStatusPanel(),

        // Debug information (if enabled)
        if (widget.showDebugInfo) _buildDebugPanel(),
      ],
    );
  }

  Widget _buildLoadingView() {
    if (widget.customLoadingWidget != null) {
      return Center(child: widget.customLoadingWidget!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: widget.config.theme.primaryColor,
          ),
          const SizedBox(height: UIConstants.largeSpacing),
          Text(
            _instructionMessage,
            style: widget.config.theme.instructionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    if (widget.customErrorWidget != null && _currentError != null) {
      return widget.customErrorWidget!(_currentError!);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.extraLargeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: widget.config.theme.errorColor,
            ),
            const SizedBox(height: UIConstants.largeSpacing),
            Text(
              _currentError?.message ?? 'An error occurred',
              style: widget.config.theme.instructionTextStyle.copyWith(
                color: widget.config.theme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.mediumSpacing),
            if (_currentError?.isRecoverable == true) ...[
              Text(
                _currentError!.code.userAction,
                style: widget.config.theme.statusTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UIConstants.extraLargeSpacing),
              ElevatedButton(
                onPressed: _retryVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.config.theme.primaryColor,
                  foregroundColor: widget.config.theme.textColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return Positioned(
      top: 20,
      left: UIConstants.largeSpacing,
      right: UIConstants.largeSpacing,
      child: AnimatedContainer(
        duration: widget.config.theme.animationDuration,
        padding: const EdgeInsets.all(UIConstants.largeSpacing),
        decoration: BoxDecoration(
          color: widget.config.theme.panelBackgroundColor,
          borderRadius: widget.config.theme.borderRadius,
          border: Border.all(
            color: _isPositionedCorrectly
                ? widget.config.theme.successColor
                : _isFaceDetected
                    ? widget.config.theme.warningColor
                    : widget.config.theme.panelBorderColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              _instructionMessage,
              style: widget.config.theme.instructionTextStyle,
              textAlign: TextAlign.center,
            ),
            
            if (_isPositionedCorrectly && _currentChallenge != null) ...[
              const SizedBox(height: UIConstants.mediumSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentChallenge!.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: UIConstants.smallSpacing),
                  Expanded(
                    child: Text(
                      'Please ${_currentChallenge!.instruction}',
                      style: widget.config.theme.challengeTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressPanel() {
    if (_currentProgress == null) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      left: UIConstants.largeSpacing,
      right: UIConstants.largeSpacing,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.mediumSpacing),
        decoration: BoxDecoration(
          color: widget.config.theme.panelBackgroundColor,
          borderRadius: widget.config.theme.borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _currentProgress!.totalChallenges; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: UIConstants.progressIndicatorSize,
                height: UIConstants.progressIndicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _currentProgress!.challengeIndex
                      ? widget.config.theme.successColor
                      : i == _currentProgress!.challengeIndex
                          ? widget.config.theme.primaryColor
                          : Colors.grey.shade600,
                  border: Border.all(
                    color: widget.config.theme.textColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Positioned(
      bottom: 20,
      left: UIConstants.largeSpacing,
      right: UIConstants.largeSpacing,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.largeSpacing),
        decoration: BoxDecoration(
          color: widget.config.theme.panelBackgroundColor,
          borderRadius: widget.config.theme.borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusIndicator('Face', _isFaceDetected),
            _buildStatusIndicator('Position', _isPositionedCorrectly),
            _buildStatusIndicator('Ready', _isPositionedCorrectly && _currentChallenge != null),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isGood) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isGood ? Icons.check_circle : Icons.cancel,
          color: isGood ? widget.config.theme.successColor : widget.config.theme.errorColor,
          size: UIConstants.statusIconSize,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: widget.config.theme.statusTextStyle.copyWith(
            color: isGood ? widget.config.theme.successColor : widget.config.theme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDebugPanel() {
    return Positioned(
      top: 200,
      right: UIConstants.largeSpacing,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.smallSpacing),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Debug Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Face: ${_isFaceDetected ? "✓" : "✗"}', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('Positioned: ${_isPositionedCorrectly ? "✓" : "✗"}', style: TextStyle(color: Colors.white, fontSize: 12)),
            if (_detector.smilingProbability != null)
              Text('Smile: ${(_detector.smilingProbability! * 100).toInt()}%', style: TextStyle(color: Colors.white, fontSize: 12)),
            if (_detector.leftEyeOpenProbability != null && _detector.rightEyeOpenProbability != null)
              Text('Eyes: ${((_detector.leftEyeOpenProbability! + _detector.rightEyeOpenProbability!) * 50).toInt()}%', 
                   style: TextStyle(color: Colors.white, fontSize: 12)),
            if (_detector.headEulerAngleY != null)
              Text('Head Y: ${_detector.headEulerAngleY!.toStringAsFixed(1)}°', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    _detector.dispose();
    super.dispose();
  }
}

/// Callback function type for liveness detection result.
typedef LivenessDetectionCallback = void Function(LivenessResult result);

/// Callback function type for liveness detection error.
typedef LivenessErrorCallback = void Function(LivenessError error);

/// Callback function type for challenge progress updates.
typedef LivenessProgressCallback = void Function(ChallengeType challenge, ChallengeProgress progress);

/// Callback function type for challenge completion.
typedef ChallengeCompletedCallback = void Function(ChallengeType completedChallenge, ChallengeType? nextChallenge);