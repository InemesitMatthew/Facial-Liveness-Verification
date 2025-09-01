import 'dart:developer' as dev;
import 'dart:async';
import 'dart:math';

import 'core.dart';

/// Production-ready liveness detection view with comprehensive face tracking
/// and challenge validation system
class FaceDetectionView extends StatefulWidget {
  const FaceDetectionView({super.key});

  @override
  State<FaceDetectionView> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView>
    with SingleTickerProviderStateMixin {
  // Face detector optimized for Poco M4 Pro (Helio G96)
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast, // Optimized for Helio G96
      enableContours: false, // Disabled for better performance
      enableClassification: true, // Required for smile/blink detection
      minFaceSize: 0.15, // Balanced for detection range
      enableTracking: true, // Helps with consistency
      enableLandmarks:
          false, // Disabled for performance (not needed for basic challenges)
    ),
  );
  //  final FaceDetector faceDetector = FaceDetector(
  //   options: FaceDetectorOptions(
  //     performanceMode:
  //         FaceDetectorMode.accurate, // Better accuracy for production
  //     enableContours: true,
  //     enableClassification: true,
  //     minFaceSize: 0.3, // Good balance for detection range
  //     enableTracking: true, // Maintains face tracking between frames
  //     enableLandmarks: true, // Provides precise facial feature data
  //   ),
  // );

  // Camera controller instance
  late CameraController cameraController;

  // Camera initialization state
  bool isCameraInitialized = false;

  // Face detection state
  bool isDetecting = false;
  bool isFrontCamera = true;

  // Face positioning and quality checks
  bool isFaceInFrame = false;
  bool isFaceCentered = false;
  bool isFaceLookingStraight = false;
  bool isFaceQualityGood = false;
  String facePositionFeedback = 'Position your face in the center';

  // Simplified challenge system for Poco M4 Pro (2 basic challenges)
  List<String> challengeActions = ['smile', 'blink'];
  int currentActionIndex = 0;
  bool waitingForNeutral = false;
  bool actionCompleted = false;
  bool challengeCompleted = false;

  // Face detection results with improved tracking
  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;
  double? headEulerAngleX;
  double? headEulerAngleZ;

  // Face positioning data
  Rect? faceBoundingBox;
  double? faceConfidence;

  // Current face and detection state
  Face? currentFace;
  DateTime? lastDetectionTime;
  bool isFaceDetected = false;
  bool isPositionedCorrectly = false;

  // Blink detection state tracking
  bool wasBlinking = false;
  int blinkCount = 0;
  DateTime? lastBlinkTime;

  // Action completion tracking
  Map<String, bool> completedActions = {};
  Map<String, DateTime> actionStartTimes = {};

  // Animation controller for visual feedback
  late AnimationController _animationController;

  // Poco M4 Pro optimized positioning thresholds
  static const double centerTolerance =
      0.2; // 20% tolerance (more lenient for testing)
  static const double angleTolerance = 15.0; // 15 degrees (more lenient)
  static const double minFaceSize = 0.2; // More lenient minimum face size
  static const double maxFaceSize = 0.9; // More lenient maximum face size

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for visual feedback
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Test ML Kit setup first
    testMLKitSetup();

    // Initialize the camera controller
    initializeCamera();
    // Shuffle the challenge actions for security
    challengeActions.shuffle();
    // Initialize action tracking
    for (String action in challengeActions) {
      completedActions[action] = false;
    }
  }

  /// Initialize camera with Poco M4 Pro optimized settings
  Future<void> initializeCamera() async {
    try {
      dev.log('📱 Initializing camera for Poco M4 Pro...');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        dev.log('❌ No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first, // Fallback to any camera
      );

      dev.log('📸 Found front camera: ${frontCamera.name}');
      dev.log('📐 Camera resolution: ${frontCamera.sensorOrientation}°');

      // Poco M4 Pro optimized camera settings
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset
            .low, // Use low resolution for better performance on Helio G96
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.yuv420, // Force YUV420 for better compatibility
      );

      dev.log('🔧 Camera controller created with YUV420 format');

      await cameraController.initialize();

      dev.log('✅ Camera initialized successfully');

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        startFaceDetection();
      }
    } catch (e) {
      dev.log('💥 Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start face detection with optimized throttling for Poco M4 Pro
  void startFaceDetection() {
    if (isCameraInitialized) {
      dev.log('🚀 Starting optimized face detection stream...');

      cameraController.startImageStream((CameraImage image) {
        // Optimized frame skipping for Helio G96 performance
        if (!isDetecting) {
          isDetecting = true;
          detectFacesOptimized(image)
              .then((_) {
                isDetecting = false;
              })
              .catchError((error) {
                dev.log('⚠️ Face detection error: $error');
                isDetecting = false;
              });
        }
      });
    }
  }

  /// Optimized face detection for Poco M4 Pro with proper YUV handling
  Future<void> detectFacesOptimized(CameraImage image) async {
    if (!mounted) return;

    try {
      // Performance monitoring
      final startTime = DateTime.now();

      dev.log('🔍 Processing frame: ${image.width}x${image.height}');
      dev.log('📊 Format: ${image.format.group}');
      dev.log('📋 Planes: ${image.planes.length}');

      // Poco M4 Pro specific YUV handling
      InputImage? inputImage = await _createOptimizedInputImage(image);

      if (inputImage == null) {
        dev.log('❌ Failed to create InputImage');
        return;
      }

      // Process with optimized detector settings
      List<Face> faces = await faceDetector.processImage(inputImage);

      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;
      dev.log('⚡ Processing time: ${processingTime}ms');
      dev.log('👤 Faces detected: ${faces.length}');

      if (faces.isNotEmpty) {
        Face face = faces.first;

        // Update UI efficiently
        if (mounted) {
          setState(() {
            currentFace = face;
            lastDetectionTime = DateTime.now();
            isFaceDetected = true;

            // Update face data for UI
            smilingProbability = face.smilingProbability;
            leftEyeOpenProbability = face.leftEyeOpenProbability;
            rightEyeOpenProbability = face.rightEyeOpenProbability;
            headEulerAngleY = face.headEulerAngleY;
            headEulerAngleX = face.headEulerAngleX;
            headEulerAngleZ = face.headEulerAngleZ;
            faceBoundingBox = face.boundingBox;
          });
        }

        // Check positioning and challenges
        checkFacePositioning(face, image.width, image.height);
        if (isPositionedCorrectly) {
          checkChallenge(face);
        }
      } else {
        if (mounted) {
          setState(() {
            isFaceDetected = false;
            facePositionFeedback = 'Position your face in the center';
          });
        }
      }
    } catch (e, stackTrace) {
      dev.log('💥 Optimized detection error: $e');
      dev.log('📚 Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          isFaceDetected = false;
          facePositionFeedback = 'Detection error - please try again';
        });
      }
    }
  }

  /// Create optimized InputImage for Poco M4 Pro with proper YUV handling
  /// Enhanced with DeepSeek's stride handling and dynamic rotation
  Future<InputImage?> _createOptimizedInputImage(CameraImage image) async {
    try {
      // Try multiple formats in order of preference for Poco M4 Pro
      List<InputImageFormat> formatsToTry = [
        InputImageFormat
            .nv21, // Most reliable for Android (DeepSeek's recommendation)
        InputImageFormat.yuv420, // Alternative
        InputImageFormat.bgra8888, // Fallback
      ];

      for (InputImageFormat format in formatsToTry) {
        try {
          dev.log('🎨 Trying format: $format');

          InputImage? inputImage = await _createInputImageWithFormat(
            image,
            format,
          );
          if (inputImage != null) {
            dev.log('✅ Successfully created InputImage with format: $format');
            return inputImage;
          }
        } catch (e) {
          dev.log('⚠️ Format $format failed: $e');
          continue;
        }
      }

      dev.log('❌ All formats failed');
      return null;
    } catch (e) {
      dev.log('💥 InputImage creation error: $e');
      return null;
    }
  }

  /// Create InputImage with specific format (enhanced with DeepSeek's improvements)
  Future<InputImage?> _createInputImageWithFormat(
    CameraImage image,
    InputImageFormat format,
  ) async {
    try {
      Uint8List bytes;
      int bytesPerRow;

      switch (format) {
        case InputImageFormat.nv21:
          bytes = _createNV21BytesEnhanced(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.yuv420:
          bytes = _createYUV420BytesEnhanced(image);
          bytesPerRow = image.width;
          break;
        case InputImageFormat.bgra8888:
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
          break;
        default:
          return null;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation:
              _getImageRotationDynamic(), // Enhanced with dynamic rotation
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      dev.log('💥 Error creating InputImage with format $format: $e');
      return null;
    }
  }

  /// Enhanced NV21 format bytes with DeepSeek's stride handling
  Uint8List _createNV21BytesEnhanced(CameraImage image) {
    dev.log('🎨 Creating enhanced NV21 bytes with proper stride handling...');

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uvSize = (image.width * image.height) ~/ 4;

    final nv21Bytes = Uint8List(ySize + 2 * uvSize);

    // Copy Y plane (luminance) with stride handling
    _copyPlaneWithStride(yPlane, nv21Bytes, 0, image.width, image.height);

    // Interleave U and V planes with enhanced stride handling (DeepSeek's approach)
    int uvIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      final uvPixelIndex =
          i ~/ image.width * (uPlane.bytesPerRow ~/ 2) + i % image.width;

      // Ensure we don't go out of bounds
      if (uvPixelIndex < vPlane.bytes.length &&
          uvPixelIndex < uPlane.bytes.length) {
        nv21Bytes[uvIndex++] = vPlane.bytes[uvPixelIndex]; // V first
        nv21Bytes[uvIndex++] = uPlane.bytes[uvPixelIndex]; // U second
      } else {
        // Fallback to simple indexing if stride calculation fails
        nv21Bytes[uvIndex++] = vPlane.bytes[i % vPlane.bytes.length];
        nv21Bytes[uvIndex++] = uPlane.bytes[i % uPlane.bytes.length];
      }
    }

    dev.log('✅ Enhanced NV21 bytes created: ${nv21Bytes.length} total bytes');
    return nv21Bytes;
  }

  /// Enhanced YUV420 format bytes with better stride handling
  Uint8List _createYUV420BytesEnhanced(CameraImage image) {
    dev.log('🎨 Creating enhanced YUV420 bytes...');

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uSize = (image.width * image.height) ~/ 4;
    final vSize = (image.width * image.height) ~/ 4;

    final yuvBytes = Uint8List(ySize + uSize + vSize);

    // Copy Y plane with stride handling
    _copyPlaneWithStride(yPlane, yuvBytes, 0, image.width, image.height);

    // Copy U plane with stride handling
    _copyPlaneWithStride(
      uPlane,
      yuvBytes,
      ySize,
      image.width ~/ 2,
      image.height ~/ 2,
    );

    // Copy V plane with stride handling
    _copyPlaneWithStride(
      vPlane,
      yuvBytes,
      ySize + uSize,
      image.width ~/ 2,
      image.height ~/ 2,
    );

    dev.log('✅ Enhanced YUV420 bytes created: ${yuvBytes.length} total bytes');
    return yuvBytes;
  }

  /// Helper method to copy plane data with proper stride handling
  void _copyPlaneWithStride(
    Plane plane,
    Uint8List destination,
    int destOffset,
    int width,
    int height,
  ) {
    final srcBytes = plane.bytes;
    final srcStride = plane.bytesPerRow;

    for (int y = 0; y < height; y++) {
      final srcOffset = y * srcStride;
      final destStart = destOffset + y * width;
      final copyLength = min(width, srcBytes.length - srcOffset);

      if (copyLength > 0) {
        destination.setRange(
          destStart,
          destStart + copyLength,
          srcBytes,
          srcOffset,
        );
      }
    }
  }

  /// Enhanced dynamic image rotation calculation (DeepSeek's approach)
  InputImageRotation _getImageRotationDynamic() {
    try {
      // For front camera on most Android devices, we need 270 degrees
      // This accounts for the camera sensor orientation
      // We'll use a fixed value for now since cameraDescription isn't available
      dev.log('📐 Using fixed rotation: 270° for front camera');
      return InputImageRotation.rotation270deg;
    } catch (e) {
      dev.log('⚠️ Error getting sensor orientation: $e, using 270deg');
      return InputImageRotation.rotation270deg; // Fallback for front camera
    }
  }

  /// Legacy method - now optimized for Poco M4 Pro
  Future<void> detectFaces(CameraImage image) async {
    return detectFacesOptimized(image);
  }

  /// Legacy debug method - kept for compatibility
  Future<void> detectFacesDebug(CameraImage image) async {
    return detectFacesOptimized(image);
  }

  // Add this test method to validate ML Kit setup
  Future<void> testMLKitSetup() async {
    try {
      dev.log('🧪 Testing ML Kit setup...');

      // Test with a simple detector creation
      final testDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
          minFaceSize: 0.1,
        ),
      );

      dev.log('✅ Face detector created successfully');
      await testDetector.close();
      dev.log('✅ Face detector disposed successfully');
      dev.log('🎉 ML Kit setup is working!');
    } catch (e) {
      dev.log('💥 ML Kit setup error: $e');
      dev.log('❌ ML Kit may not be properly configured');
    }
  }

  /// Update face detection results with comprehensive data
  void updateFaceDetectionResults(Face face, int imageWidth, int imageHeight) {
    if (mounted) {
      setState(() {
        smilingProbability = face.smilingProbability;
        leftEyeOpenProbability = face.leftEyeOpenProbability;
        rightEyeOpenProbability = face.rightEyeOpenProbability;
        headEulerAngleY = face.headEulerAngleY; // Left/Right rotation
        headEulerAngleX = face.headEulerAngleX; // Up/Down rotation
        headEulerAngleZ = face.headEulerAngleZ; // Tilt
        faceBoundingBox = face.boundingBox;
        faceConfidence = face.trackingId
            ?.toDouble(); // Use tracking ID as confidence
      });
    }
  }

  /// Enhanced face positioning detection with production-optimized thresholds
  void checkFacePositioning(Face face, int imageWidth, int imageHeight) {
    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;
    final centerY = box.top + box.height / 2;

    // Check if face is in frame with improved boundary detection
    final inFrame =
        box.left >= 0 &&
        box.top >= 0 &&
        box.right <= imageWidth &&
        box.bottom <= imageHeight;

    // Enhanced centering check with production-optimized tolerance
    final screenCenterX = imageWidth / 2;
    final screenCenterY = imageHeight / 2;
    final centerThresholdX = imageWidth * centerTolerance;
    final centerThresholdY = imageHeight * centerTolerance;

    final centered =
        (centerX - screenCenterX).abs() < centerThresholdX &&
        (centerY - screenCenterY).abs() < centerThresholdY;

    // Enhanced head angle validation with precise thresholds
    final lookingStraight =
        (face.headEulerAngleY?.abs() ?? 0) < angleTolerance &&
        (face.headEulerAngleX?.abs() ?? 0) < angleTolerance &&
        (face.headEulerAngleZ?.abs() ?? 0) < angleTolerance;

    // Enhanced face size validation with optimal range
    final faceArea = box.width * box.height;
    final imageArea = imageWidth * imageHeight;
    final faceSizeRatio = faceArea / imageArea;

    final goodSize =
        faceSizeRatio >= minFaceSize && faceSizeRatio <= maxFaceSize;

    // Enhanced quality assessment with weighted scoring
    final qualityScore = _calculateQualityScore(
      inFrame: inFrame,
      centered: centered,
      lookingStraight: lookingStraight,
      goodSize: goodSize,
      faceSizeRatio: faceSizeRatio,
    );

    if (mounted) {
      setState(() {
        isFaceInFrame = inFrame;
        isFaceCentered = centered;
        isFaceLookingStraight = lookingStraight;
        isFaceQualityGood = qualityScore >= 0.8; // 80% quality threshold
        isPositionedCorrectly =
            inFrame && centered && lookingStraight && goodSize;

        // Enhanced user feedback with specific guidance
        facePositionFeedback = _getPositioningFeedback(
          face: face,
          inFrame: inFrame,
          centered: centered,
          lookingStraight: lookingStraight,
          goodSize: goodSize,
          faceSizeRatio: faceSizeRatio,
          centerX: centerX,
          screenCenterX: screenCenterX,
          centerY: centerY,
          screenCenterY: screenCenterY,
        );
      });
    }
  }

  /// Calculate quality score based on positioning factors
  double _calculateQualityScore({
    required bool inFrame,
    required bool centered,
    required bool lookingStraight,
    required bool goodSize,
    required double faceSizeRatio,
  }) {
    if (!inFrame) return 0.0;

    double score = 0.0;

    // Centering weight: 30%
    if (centered) score += 0.3;

    // Head angle weight: 25%
    if (lookingStraight) score += 0.25;

    // Face size weight: 25%
    if (goodSize) score += 0.25;

    // Optimal size bonus: 20%
    final optimalSize = (minFaceSize + maxFaceSize) / 2;
    final sizeDeviation = (faceSizeRatio - optimalSize).abs() / optimalSize;
    if (sizeDeviation < 0.2) score += 0.2; // Within 20% of optimal

    return score;
  }

  /// Enhanced positioning feedback with specific guidance
  String _getPositioningFeedback({
    required Face face,
    required bool inFrame,
    required bool centered,
    required bool lookingStraight,
    required bool goodSize,
    required double faceSizeRatio,
    required double centerX,
    required double screenCenterX,
    required double centerY,
    required double screenCenterY,
  }) {
    if (!inFrame) {
      return 'Face not in frame - please move into view';
    }

    if (!centered) {
      final horizontalDirection = centerX < screenCenterX ? 'right' : 'left';
      final verticalDirection = centerY < screenCenterY ? 'down' : 'up';

      if ((centerX - screenCenterX).abs() > (centerY - screenCenterY).abs()) {
        return 'Move $horizontalDirection to center your face';
      } else {
        return 'Move $verticalDirection to center your face';
      }
    }

    if (!lookingStraight) {
      if ((face.headEulerAngleY?.abs() ?? 0) > angleTolerance) {
        return 'Look straight at the camera';
      } else if ((face.headEulerAngleX?.abs() ?? 0) > angleTolerance) {
        return 'Keep your head level';
      } else {
        return 'Don\'t tilt your head';
      }
    }

    if (!goodSize) {
      if (faceSizeRatio < minFaceSize) {
        return 'Move closer to the camera';
      } else {
        return 'Move further from the camera';
      }
    }

    return 'Perfect! Ready for verification';
  }

  /// Optimized challenge action validation for Poco M4 Pro
  bool _validateChallengeAction(Face face, String action) {
    // Poco M4 Pro optimized thresholds (more lenient for testing)
    const double smileThreshold = 0.6; // Lower threshold for easier detection
    const double eyeClosedThreshold = 0.4; // More lenient blink detection

    switch (action) {
      case 'smile':
        return face.smilingProbability != null &&
            face.smilingProbability! > smileThreshold;

      case 'blink':
        return _detectEnhancedBlink(face, eyeClosedThreshold);

      default:
        return false;
    }
  }

  /// Enhanced blink detection with consecutive frame validation
  bool _detectEnhancedBlink(Face face, double threshold) {
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;

    // Check if either eye is closed
    final isBlinking = leftEye < threshold || rightEye < threshold;

    if (isBlinking && !wasBlinking) {
      // Start of blink
      wasBlinking = true;
      blinkCount++;
      lastBlinkTime = DateTime.now();
    } else if (!isBlinking && wasBlinking) {
      // End of blink
      wasBlinking = false;
    }

    // Require at least one complete blink
    return blinkCount >= 1;
  }

  /// Enhanced challenge checking with production-optimized thresholds
  void checkChallenge(Face face) async {
    // Wait for neutral position if required
    if (waitingForNeutral) {
      if (isNeutralPosition(face)) {
        if (mounted) {
          setState(() {
            waitingForNeutral = false;
          });
        }
      } else {
        return; // Still waiting for neutral
      }
    }

    // Get current action
    String currentAction = challengeActions[currentActionIndex];

    // Initialize action start time if not set
    if (!actionStartTimes.containsKey(currentAction)) {
      actionStartTimes[currentAction] = DateTime.now();
    }

    // Enhanced timeout handling (15 seconds with warning)
    final actionStartTime = actionStartTimes[currentAction]!;
    final elapsedSeconds = DateTime.now().difference(actionStartTime).inSeconds;

    if (elapsedSeconds > 15) {
      // Reset action if timeout
      actionStartTimes.remove(currentAction);
      if (mounted) {
        setState(() {
          facePositionFeedback = 'Action timeout - please try again';
        });
      }
      return;
    }

    // Enhanced action validation with consecutive frame requirements
    bool actionCompleted = _validateChallengeAction(face, currentAction);

    // Handle action completion with enhanced feedback
    if (actionCompleted && !completedActions[currentAction]!) {
      if (mounted) {
        setState(() {
          completedActions[currentAction] = true;
          actionCompleted = true;
          facePositionFeedback = 'Great! Action completed successfully';
        });
      }

      // Enhanced transition with better UX
      await Future.delayed(const Duration(milliseconds: 800));

      if (currentActionIndex < challengeActions.length - 1) {
        if (mounted) {
          setState(() {
            currentActionIndex++;
            waitingForNeutral = true;
            actionCompleted = false;
          });
        }
      } else {
        // All challenges completed
        if (mounted) {
          setState(() {
            challengeCompleted = true;
          });

          // Return success
          Navigator.pop(context, true);
        }
      }
    }
  }

  /// Enhanced blink detection with state tracking
  bool detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    // Detect blink transition (eyes closed then opened)
    if (avgEyeOpen < 0.3 && !wasBlinking) {
      // Eyes just closed
      wasBlinking = true;
      lastBlinkTime = DateTime.now();
    } else if (avgEyeOpen > 0.7 && wasBlinking) {
      // Eyes opened after being closed
      wasBlinking = false;
      blinkCount++;

      // Consider blink detected if it was recent
      if (lastBlinkTime != null &&
          DateTime.now().difference(lastBlinkTime!).inMilliseconds < 1000) {
        return true;
      }
    }

    return false;
  }

  /// Check if face is in neutral position
  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.2) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.6) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.6) &&
        (face.headEulerAngleY == null || face.headEulerAngleY!.abs() < 10) &&
        (face.headEulerAngleX == null || face.headEulerAngleX!.abs() < 10) &&
        (face.headEulerAngleZ == null || face.headEulerAngleZ!.abs() < 10);
  }

  @override
  void dispose() {
    // Clean up resources
    _animationController.dispose();
    if (isCameraInitialized) {
      cameraController.stopImageStream();
      cameraController.dispose();
    }
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text("Verify Your Identity"),
      ),
      body: isCameraInitialized
          ? Stack(
              children: [
                // Camera preview
                Positioned.fill(child: CameraPreview(cameraController)),

                // Enhanced face mask overlay with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: HeadMaskPainter(
                        animationValue: _animationController.value,
                        isFaceQualityGood: isFaceQualityGood,
                        faceBoundingBox: faceBoundingBox,
                      ),
                      child: Container(),
                    );
                  },
                ),

                // Top instruction panel
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Face positioning feedback
                        Text(
                          facePositionFeedback,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Challenge instruction
                        if (isFaceQualityGood)
                          Text(
                            'Please ${getActionDescription(challengeActions[currentActionIndex])}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 4),

                        // Enhanced progress indicator
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (
                                  int i = 0;
                                  i < challengeActions.length;
                                  i++
                                )
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < currentActionIndex
                                          ? Colors.green
                                          : i == currentActionIndex
                                          ? Colors.amberAccent
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step ${currentActionIndex + 1} of ${challengeActions.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom debug panel
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Face quality indicators
                        Row(
                          children: [
                            Icon(
                              isFaceInFrame ? Icons.check_circle : Icons.cancel,
                              color: isFaceInFrame ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'In Frame',
                              style: TextStyle(
                                color: isFaceInFrame
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              isFaceCentered
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isFaceCentered ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Centered',
                              style: TextStyle(
                                color: isFaceCentered
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              isFaceLookingStraight
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isFaceLookingStraight
                                  ? Colors.green
                                  : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Looking Straight',
                              style: TextStyle(
                                color: isFaceLookingStraight
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Face detection values
                        Text(
                          'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(1) : 'N/A'}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Eyes: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(1) : 'N/A'}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Head Y: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(1) : 'N/A'}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Head X: ${headEulerAngleX != null ? headEulerAngleX!.toStringAsFixed(1) : 'N/A'}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  /// Get user-friendly description of challenge action
  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile naturally';
      case 'blink':
        return 'blink your eyes';
      default:
        return '';
    }
  }
}

/// Enhanced custom painter for animated face mask overlay
class HeadMaskPainter extends CustomPainter {
  final double animationValue;
  final bool isFaceQualityGood;
  final Rect? faceBoundingBox;

  HeadMaskPainter({
    required this.animationValue,
    required this.isFaceQualityGood,
    this.faceBoundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);

    // Animated radius based on face quality
    final baseRadius = size.width * 0.35;
    final animatedRadius = baseRadius + (animationValue * 15);

    // Draw background mask
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: animatedRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    // Draw animated guide circle
    final guidePaint = Paint()
      ..color = isFaceQualityGood
          ? Colors.green.withValues(alpha: 0.3 + animationValue * 0.2)
          : Colors.orange.withValues(alpha: 0.3 + animationValue * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, animatedRadius, guidePaint);

    // Draw positioning arrows if face is not centered
    if (faceBoundingBox != null) {
      _drawPositioningArrows(canvas, size, center, animatedRadius);
    }

    // Draw corner guides
    _drawCornerGuides(canvas, center, animatedRadius);
  }

  void _drawPositioningArrows(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final faceCenter = Offset(
      faceBoundingBox!.left + faceBoundingBox!.width / 2,
      faceBoundingBox!.top + faceBoundingBox!.height / 2,
    );

    // Horizontal positioning arrow
    if ((faceCenter.dx - center.dx).abs() > 20) {
      final arrowDirection = faceCenter.dx < center.dx ? 1.0 : -1.0;
      final arrowStart = Offset(
        center.dx + (radius * 0.8 * arrowDirection),
        center.dy,
      );
      final arrowEnd = Offset(
        center.dx + (radius * 1.2 * arrowDirection),
        center.dy,
      );

      _drawArrow(canvas, arrowStart, arrowEnd, arrowPaint);
    }

    // Vertical positioning arrow
    if ((faceCenter.dy - center.dy).abs() > 20) {
      final arrowDirection = faceCenter.dy < center.dy ? 1.0 : -1.0;
      final arrowStart = Offset(
        center.dx,
        center.dy + (radius * 0.8 * arrowDirection),
      );
      final arrowEnd = Offset(
        center.dx,
        center.dy + (radius * 1.2 * arrowDirection),
      );

      _drawArrow(canvas, arrowStart, arrowEnd, arrowPaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);

    // Draw arrowhead
    final arrowLength = 15.0;
    final arrowAngle = 0.5;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = atan2(dy, dx);

    final arrowPoint1 = Offset(
      end.dx - arrowLength * cos(angle - arrowAngle),
      end.dy - arrowLength * sin(angle - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowLength * cos(angle + arrowAngle),
      end.dy - arrowLength * sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  void _drawCornerGuides(Canvas canvas, Offset center, double radius) {
    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cornerLength = 20.0;
    final corners = [
      Offset(center.dx - radius, center.dy - radius), // Top-left
      Offset(center.dx + radius, center.dy - radius), // Top-right
      Offset(center.dx - radius, center.dy + radius), // Bottom-left
      Offset(center.dx + radius, center.dy + radius), // Bottom-right
    ];

    for (final corner in corners) {
      // Horizontal line
      canvas.drawLine(
        corner,
        Offset(corner.dx + cornerLength, corner.dy),
        cornerPaint,
      );
      // Vertical line
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + cornerLength),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}
