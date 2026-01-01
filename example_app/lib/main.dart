// Example app demonstrating how to use the Facial Liveness Verification package.
//
// This example shows:
// - How to initialize and use LivenessDetector
// - How to listen to state updates via streams
// - How to build custom UI overlays for face guidance
// - How to use coordinate transformation utilities for drawing overlays
//
// The package provides detection logic only - you build your own UI!
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facial Liveness Detection Demo',
      theme: ThemeData(useMaterial3: true),
      home: const ExampleHomePage(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

/// Home page state that manages verification results and navigation.
class _ExampleHomePageState extends State<ExampleHomePage> {
  // Store the last verification result to display to the user
  LivenessResult? _lastResult;
  // Store any errors that occurred during verification
  LivenessError? _lastError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar('Liveness Detection Demo'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[900]!, Colors.grey[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Facial Liveness Detection',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simple logic-focused API',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildVerificationButton(
              title: 'Start Verification',
              subtitle: 'Default: smile, blink, turn left, turn right',
              icon: Icons.face,
              onTap: () => _startVerification(const LivenessConfig()),
            ),
            const SizedBox(height: 16),

            _buildVerificationButton(
              title: 'Quick Verification',
              subtitle: 'Just smile and blink',
              icon: Icons.speed,
              onTap: () => _startVerification(
                const LivenessConfig(
                  challenges: [ChallengeType.smile, ChallengeType.blink],
                  challengeTimeout: Duration(seconds: 15),
                ),
              ),
            ),

            // Results section
            if (_lastResult != null || _lastError != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Last Result',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildResultWidget(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_lastError != null) {
      return _buildResultCard(
        header: _buildResultHeader(
          icon: Icons.error_outline,
          title: 'Verification Failed',
        ),
        children: [
          const SizedBox(height: 12),
          _buildInfoRow('Error', _lastError!.message),
          if (_lastError!.isRecoverable) ...[
            const SizedBox(height: 16),
            _buildPrimaryButton(
              icon: Icons.refresh,
              label: 'Try Again',
              onPressed: () {
                setState(() {
                  _lastError = null;
                });
              },
            ),
          ],
        ],
      );
    }

    if (_lastResult != null) {
      return _buildResultCard(
        header: _buildResultHeader(
          icon: _lastResult!.isVerified
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          title: _lastResult!.isVerified
              ? 'Verification Successful!'
              : 'Verification Incomplete',
        ),
        children: [
          if (_lastResult!.isVerified) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              'Confidence',
              '${(_lastResult!.confidenceScore * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultCard({
    required Widget header,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, ...children],
        ),
      ),
    );
  }

  Widget _buildResultHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[800], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildVerificationButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildIconContainer(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer({required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.grey[800], size: 28),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.grey[200],
      foregroundColor: Colors.grey[900],
      elevation: 0,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Starts the verification process by navigating to the verification screen.
  ///
  /// After verification completes (success or error), the result is stored
  /// and displayed on this home page.
  void _startVerification(LivenessConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(config: config),
      ),
    ).then((result) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      // Handle successful verification result
      if (result is LivenessResult) {
        setState(() {
          _lastResult = result;
          _lastError = null;
        });
      }
      // Handle verification error
      else if (result is LivenessError) {
        setState(() {
          _lastError = result;
          _lastResult = null;
        });
      }
    });
  }
}

/// Example verification screen showing custom UI integration.
///
/// This screen demonstrates:
/// - How to initialize LivenessDetector with a custom config
/// - How to listen to state stream updates
/// - How to display camera preview with custom overlays
/// - How to use coordinate utilities for face bounding box overlays
/// - How to show challenge progress and instructions
class VerificationScreen extends StatefulWidget {
  final LivenessConfig config;

  const VerificationScreen({super.key, required this.config});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // The main detector instance - handles all face detection and challenge logic
  late LivenessDetector _detector;
  // Subscription to state stream - listen for updates from the detector
  StreamSubscription<LivenessState>? _stateSubscription;

  // UI state flags - updated from detector state stream
  bool _isInitialized = false; // Camera and detector ready
  bool _isFaceDetected = false; // Face currently visible
  bool _isPositioned = false; // Face properly centered and positioned
  ChallengeType? _currentChallenge; // Current active challenge
  int _challengeProgress = 0; // Index of current challenge (0-based)
  int _totalChallenges = 0; // Total number of challenges
  Rect? _faceBoundingBox; // Face position in image coordinates
  Size?
  _cameraPreviewSize; // Size of camera preview widget (for coordinate conversion)

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  /// Initializes the detector and sets up state stream listener.
  ///
  /// This is where we:
  /// 1. Create the LivenessDetector with the provided config
  /// 2. Listen to state updates and update our UI state accordingly
  /// 3. Initialize the camera and start detection
  Future<void> _initializeDetector() async {
    // Create detector instance - this handles all the detection logic
    _detector = LivenessDetector(widget.config);

    // Listen to state stream - this is how we get updates from the detector
    // The detector emits states like: faceDetected, positioned, challengeInProgress, etc.
    _stateSubscription = _detector.stateStream.listen((state) {
      if (!mounted) return;

      // Update UI state based on detector state
      setState(() {
        switch (state.type) {
          case LivenessStateType.initialized:
            // Camera and detector are ready
            _isInitialized = true;
            break;
          case LivenessStateType.detecting:
            // Detection in progress (no UI change needed)
            break;
          case LivenessStateType.noFace:
            // No face detected - reset face-related state
            _isFaceDetected = false;
            _isPositioned = false;
            _faceBoundingBox = null;
            break;
          case LivenessStateType.faceDetected:
            // Face detected but may not be positioned correctly yet
            _isFaceDetected = true;
            if (state.face != null) {
              // Store face bounding box for overlay drawing
              _faceBoundingBox = state.face!.boundingBox;
            }
            break;
          case LivenessStateType.positioning:
            // Face detected but not yet properly positioned
            _isPositioned = false;
            if (state.face != null) {
              _faceBoundingBox = state.face!.boundingBox;
            }
            break;
          case LivenessStateType.positioned:
            // Face is properly positioned - challenges can begin
            _isPositioned = true;
            if (state.face != null) {
              _faceBoundingBox = state.face!.boundingBox;
            }
            break;
          case LivenessStateType.challengeInProgress:
            // A challenge is currently active
            _currentChallenge = state.currentChallenge;
            _challengeProgress = state.challengeIndex;
            _totalChallenges = state.totalChallenges;
            break;
          case LivenessStateType.challengeCompleted:
            // Challenge completed, moving to next (no UI change needed)
            break;
          case LivenessStateType.completed:
            // All challenges completed successfully!
            if (state.result != null) {
              // Stop detector before navigating back
              _detector.stop();
              // Use post-frame callback to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, state.result);
                }
              });
            }
            break;
          case LivenessStateType.error:
            // An error occurred during verification
            if (state.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pop(context, state.error);
                }
              });
            }
            break;
        }
      });
    });

    // Initialize camera and start detection
    try {
      await _detector.initialize(); // Sets up camera and ML Kit
      await _detector.start(); // Starts processing camera frames
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(
              context,
              LivenessError.generic(message: e.toString()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildVerificationAppBar(),
      body: _isInitialized && _detector.cameraController != null
          ? Stack(
              // Stack allows us to layer camera preview, overlays, and UI elements
              children: [
                // Layer 1: Camera preview (background)
                // The package provides cameraController - we just display it
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Store the actual preview size for coordinate conversion
                      // This is needed because the preview size may differ from screen size
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted &&
                            _cameraPreviewSize != constraints.biggest) {
                          setState(() {
                            _cameraPreviewSize = constraints.biggest;
                          });
                        }
                      });
                      // Use the camera controller from the package
                      return CameraPreview(_detector.cameraController!);
                    },
                  ),
                ),

                // Layer 2: Face positioning guide overlay
                // Shows target position and current face position (if detected)
                if (_cameraPreviewSize != null)
                  Positioned.fill(child: _buildFaceGuideOverlay()),

                // Layer 3: Challenge progress indicators (top of screen)
                // Shows dots/indicators for each challenge, highlighting current one
                if (_totalChallenges > 0)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Create one indicator per challenge
                        for (int i = 0; i < _totalChallenges; i++)
                          _buildProgressIndicator(
                            index: i,
                            currentProgress: _challengeProgress,
                          ),
                      ],
                    ),
                  ),

                // Layer 4: Instruction text (bottom of screen)
                // Shows what the user should do (position face, smile, blink, etc.)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: _buildInstructionText(),
                ),
              ],
            )
          : const Center(
              // Show loading indicator while camera initializes
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds the instruction text shown at the bottom of the screen.
  ///
  /// Shows different messages based on current state:
  /// - No face detected: Ask user to position face
  /// - Face not positioned: Ask user to center face
  /// - Challenge active: Show challenge instruction from package
  /// - Ready: Generic ready message
  Widget _buildInstructionText() {
    String instruction;

    if (!_isFaceDetected) {
      instruction = 'Position your face within the frame';
    } else if (!_isPositioned) {
      instruction = 'Center your face in the oval';
    } else if (_currentChallenge != null) {
      // Use the instruction from the package's ChallengeType extension
      // This provides user-friendly messages like "smile naturally" or "blink your eyes"
      instruction = _currentChallenge!.instruction;
    } else {
      instruction = 'Get ready...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        instruction,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProgressIndicator({
    required int index,
    required int currentProgress,
  }) {
    final isActive = index == currentProgress;
    final isCompleted = index < currentProgress;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${isActive}_$index'),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 24 : 12,
        height: 12,
        decoration: isActive
            ? BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(6),
                color: isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
      ),
    );
  }

  /// Builds the face guide overlay that shows target position and current face position.
  ///
  /// This overlay helps users position their face correctly by showing:
  /// - A target oval (where face should be)
  /// - Current face position (if detected)
  /// - Color coding: grey (no face), red (not positioned), green (positioned)
  Widget _buildFaceGuideOverlay() {
    // If no face detected or missing data, just show the target guide
    if (!_isFaceDetected ||
        _faceBoundingBox == null ||
        _cameraPreviewSize == null) {
      return CustomPaint(
        painter: FaceGuidePainter(
          targetRect: _calculateTargetRect(),
          showTarget: true,
          isPositioned: false,
        ),
      );
    }

    // Get camera controller and preview size for coordinate conversion
    final cameraController = _detector.cameraController;
    if (cameraController == null) return const SizedBox.shrink();

    final previewSize = cameraController.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    // Convert face bounding box from ML Kit image coordinates to screen coordinates
    // This is necessary because ML Kit uses a different coordinate system than the screen
    final screenRect = _convertImageRectToScreenRect(
      _faceBoundingBox!,
      previewSize,
      _cameraPreviewSize!,
    );

    // Draw overlay with both target and current face position
    return CustomPaint(
      painter: FaceGuidePainter(
        faceRect: screenRect, // Current face position (in screen coordinates)
        targetRect: _calculateTargetRect(), // Target position guide
        showTarget: true,
        isPositioned: _isPositioned, // Whether face is properly positioned
      ),
    );
  }

  /// Calculates the target rectangle for face positioning guidance.
  ///
  /// Uses the package utility to create a centered oval guide that shows users
  /// where to position their face. The target is 65% of screen width and 110% height ratio.
  Rect _calculateTargetRect() {
    if (_cameraPreviewSize == null) return Rect.zero;
    // Use the package utility for consistent target calculation
    return CoordinateUtils.calculateTargetRect(_cameraPreviewSize!);
  }

  /// Converts face bounding box from ML Kit image coordinates to screen coordinates.
  ///
  /// ML Kit returns coordinates in camera image space, which is rotated and may have
  /// different aspect ratios than the screen. This uses the package utility to handle
  /// the complex coordinate transformation automatically.
  Rect _convertImageRectToScreenRect(
    Rect imageRect,
    Size previewSize,
    Size screenSize,
  ) {
    // Use the package utility for coordinate transformation
    // This handles aspect ratio differences and rotation automatically
    return CoordinateUtils.convertImageRectToScreenRect(
      imageRect,
      previewSize,
      screenSize,
    );
  }

  AppBar _buildVerificationAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Verify Your Identity'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _detector.stop();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _detector.dispose();
    super.dispose();
  }
}

/// Custom painter that draws face positioning guides on the camera preview.
///
/// Draws:
/// - Target oval: Shows where the user should position their face
///   - Grey: No face detected
///   - Red: Face detected but not properly positioned
///   - Green: Face properly positioned
/// - Face oval: Shows current face position (only when not positioned)
class FaceGuidePainter extends CustomPainter {
  final Rect? faceRect; // Current face position in screen coordinates
  final Rect targetRect; // Target position guide
  final bool showTarget; // Whether to show the target guide
  final bool isPositioned; // Whether face is properly positioned

  FaceGuidePainter({
    this.faceRect,
    required this.targetRect,
    required this.showTarget,
    required this.isPositioned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw the target oval guide
    if (showTarget) {
      // Color code based on positioning status
      if (faceRect == null) {
        // No face detected - grey
        paint.color = Colors.grey.withValues(alpha: 0.6);
      } else if (!isPositioned) {
        // Face detected but not positioned - red
        paint.color = Colors.red.withValues(alpha: 0.7);
      } else {
        // Face properly positioned - green
        paint.color = Colors.green.withValues(alpha: 0.7);
      }

      // Draw target oval
      final ovalRect = Rect.fromLTWH(
        targetRect.left,
        targetRect.top,
        targetRect.width,
        targetRect.height,
      );
      canvas.drawOval(ovalRect, paint);
    }

    // Draw current face position (only when not yet positioned)
    // This helps users see where their face is relative to the target
    if (faceRect != null && !isPositioned) {
      paint.color = Colors.orange.withValues(alpha: 0.4);
      paint.strokeWidth = 2.0;
      final faceOval = Rect.fromLTWH(
        faceRect!.left,
        faceRect!.top,
        faceRect!.width,
        faceRect!.height,
      );
      canvas.drawOval(faceOval, paint);
    }
  }

  @override
  bool shouldRepaint(FaceGuidePainter oldDelegate) {
    // Only repaint if relevant properties changed
    return oldDelegate.faceRect != faceRect ||
        oldDelegate.targetRect != targetRect ||
        oldDelegate.showTarget != showTarget ||
        oldDelegate.isPositioned != isPositioned;
  }
}
