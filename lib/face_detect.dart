import 'dart:developer' as dev;
import 'dart:async';
import 'dart:math';
import 'core.dart';

class FaceDetectionView extends StatefulWidget {
  const FaceDetectionView({super.key});

  @override
  State<FaceDetectionView> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView>
    with SingleTickerProviderStateMixin {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.15,
      enableTracking: true,
      enableLandmarks: true,
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;

  bool isDetecting = false;
  int frameSkipCounter = 0;
  static const int frameSkipRate = 1;

  bool isFaceInFrame = false;
  bool isFaceCentered = false;
  bool isFaceLookingStraight = false;
  bool isFaceQualityGood = false;
  bool isPositionedCorrectly = false;
  String facePositionFeedback =
      'Position your face in the center - we\'ll guide you through this!';

  List<String> challengeActions = ['smile', 'blink', 'turn_left', 'turn_right'];
  int currentActionIndex = 0;
  bool waitingForNeutral = false;
  bool challengeCompleted = false;

  bool _isInTurnChallenge = false;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;
  double? headEulerAngleX;
  double? headEulerAngleZ;
  Rect? faceBoundingBox;
  Face? currentFace;
  DateTime? lastDetectionTime;
  bool isFaceDetected = false;

  final AntiSpoofingDetector _antiSpoofing = AntiSpoofingDetector();
  bool isLivenessVerified = false;
  String livenessStatus = 'Verifying liveness...';

  Map<String, bool> completedActions = {};
  Map<String, DateTime> actionStartTimes = {};

  late AnimationController _animationController;

  static const double centerTolerance = 0.2;
  static const double angleTolerance = 18.0;
  static const double minFaceSize = 0.2;
  static const double maxFaceSize = 0.85;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    await testMLKitSetup();
    await initializeCamera();
    _shuffleChallenges();
    _initializeActionTracking();
  }

  void _shuffleChallenges() {
    challengeActions.shuffle();
    if (!challengeActions.contains('smile')) {
      challengeActions[0] = 'smile';
    }
    if (!challengeActions.contains('blink')) {
      challengeActions[1] = 'blink';
    }
  }

  void _initializeActionTracking() {
    for (String action in challengeActions) {
      completedActions[action] = false;
    }
  }

  Future<void> initializeCamera() async {
    try {
      dev.log('📱 Initializing camera...');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController.initialize();

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        startFaceDetection();
      }
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  void startFaceDetection() {
    if (isCameraInitialized) {
      dev.log('🚀 Starting face detection stream...');
      cameraController.startImageStream(_processFrame);
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (frameSkipCounter % frameSkipRate != 0) {
      frameSkipCounter++;
      return;
    }
    frameSkipCounter++;

    if (!isDetecting && mounted) {
      isDetecting = true;
      try {
        await _detectFacesWithAntiSpoofing(image);
      } catch (e) {
        dev.log('⚠️ Frame processing error: $e');
      } finally {
        isDetecting = false;
      }
    }
  }

  Future<void> _detectFacesWithAntiSpoofing(CameraImage image) async {
    try {
      final startTime = DateTime.now();

      InputImage? inputImage = await _createOptimizedInputImage(image);
      if (inputImage == null) return;

      List<Face> faces = await faceDetector.processImage(inputImage);
      final validFaces = faces.where((face) => _isValidFace(face)).toList();

      if (validFaces.isEmpty) {
        _resetFaceState(
          'No valid face detected - please position your face in the center',
        );
        return;
      }

      final spoofingResult = await _antiSpoofing.analyzeFaces(
        validFaces,
        image,
        DateTime.now(),
      );

      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;
      dev.log('⚡ Processing time: ${processingTime}ms');

      if (faces.isNotEmpty && spoofingResult.isLive) {
        final face = faces.first;
        _updateFaceState(face, image.width, image.height);
        _checkFacePositioning(face, image.width, image.height);

        if (isPositionedCorrectly) {
          await _processChallenge(face);
        }
      } else {
        _resetFaceState(spoofingResult.reason);
      }
    } catch (e) {
      dev.log('💥 Detection error: $e');
      _resetFaceState('Detection error - please try again');
    }
  }

  void _updateFaceState(Face face, int imageWidth, int imageHeight) {
    if (!mounted) return;

    setState(() {
      currentFace = face;
      lastDetectionTime = DateTime.now();
      isFaceDetected = true;
      smilingProbability = face.smilingProbability;
      leftEyeOpenProbability = face.leftEyeOpenProbability;
      rightEyeOpenProbability = face.rightEyeOpenProbability;
      headEulerAngleY = face.headEulerAngleY;
      headEulerAngleX = face.headEulerAngleX;
      headEulerAngleZ = face.headEulerAngleZ;
      faceBoundingBox = face.boundingBox;
    });
  }

  void _resetFaceState(String feedback) {
    if (!mounted) return;

    setState(() {
      isFaceDetected = false;
      isPositionedCorrectly = false;
      facePositionFeedback = feedback;
      livenessStatus = 'Verifying liveness...';
    });
  }

  void _checkFacePositioning(Face face, int imageWidth, int imageHeight) {
    final box = face.boundingBox;
    final centerX = box.left + box.width / 2;
    final centerY = box.top + box.height / 2;

    final inFrame = _isInFrame(box, imageWidth, imageHeight);
    final centered = _isCentered(centerX, centerY, imageWidth, imageHeight);
    final lookingStraight = _isLookingStraight(face);
    final goodSize = _isGoodSize(box, imageWidth, imageHeight);

    final withinGuideCircle = _isWithinGuideCircle(
      centerX,
      centerY,
      imageWidth,
      imageHeight,
    );

    final isTurnChallenge = _isInTurnChallenge;
    final relaxedCentering = isTurnChallenge
        ? _isCenteredRelaxed(centerX, centerY, imageWidth, imageHeight)
        : centered;

    final qualityGood = isTurnChallenge
        ? inFrame && goodSize && withinGuideCircle
        : inFrame &&
              relaxedCentering &&
              lookingStraight &&
              goodSize &&
              withinGuideCircle;

    if (mounted) {
      setState(() {
        isFaceInFrame = inFrame;
        isFaceCentered = relaxedCentering;
        isFaceLookingStraight = lookingStraight;
        isFaceQualityGood = qualityGood;
        isPositionedCorrectly = qualityGood;

        facePositionFeedback = _getPositioningFeedback(
          face: face,
          inFrame: inFrame,
          centered: relaxedCentering,
          lookingStraight: lookingStraight,
          goodSize: goodSize,
          withinGuideCircle: withinGuideCircle,
          isTurnChallenge: isTurnChallenge,
          centerX: centerX,
          screenCenterX: imageWidth / 2,
          centerY: centerY,
          screenCenterY: imageHeight / 2,
        );
      });
    }
  }

  bool _isInFrame(Rect box, int width, int height) {
    return box.left >= 0 &&
        box.top >= 0 &&
        box.right <= width &&
        box.bottom <= height;
  }

  bool _isCentered(double centerX, double centerY, int width, int height) {
    final screenCenterX = width / 2;
    final screenCenterY = height / 2;
    final thresholdX = width * centerTolerance;
    final thresholdY = height * centerTolerance;

    return (centerX - screenCenterX).abs() < thresholdX &&
        (centerY - screenCenterY).abs() < thresholdY;
  }

  bool _isLookingStraight(Face face) {
    return (face.headEulerAngleY?.abs() ?? 0) < angleTolerance &&
        (face.headEulerAngleX?.abs() ?? 0) < angleTolerance &&
        (face.headEulerAngleZ?.abs() ?? 0) < angleTolerance;
  }

  bool _isGoodSize(Rect box, int width, int height) {
    final faceArea = box.width * box.height;
    final imageArea = width * height;
    final ratio = faceArea / imageArea;
    return ratio >= minFaceSize && ratio <= maxFaceSize;
  }

  bool _isValidFace(Face face) {
    final hasEyes =
        face.leftEyeOpenProbability != null ||
        face.rightEyeOpenProbability != null;
    final hasSmile = face.smilingProbability != null;
    final hasHeadAngles =
        face.headEulerAngleX != null ||
        face.headEulerAngleY != null ||
        face.headEulerAngleZ != null;

    final box = face.boundingBox;
    final aspectRatio = box.width / box.height;
    final reasonableAspectRatio = aspectRatio >= 0.5 && aspectRatio <= 2.0;

    final faceArea = box.width * box.height;
    final reasonableSize = faceArea > 1000;

    return hasEyes &&
        hasSmile &&
        hasHeadAngles &&
        reasonableAspectRatio &&
        reasonableSize;
  }

  bool _isWithinGuideCircle(
    double centerX,
    double centerY,
    int imageWidth,
    int imageHeight,
  ) {
    final screenCenterX = imageWidth / 2;
    final screenCenterY = imageHeight / 2 - 50;
    final guideRadius = imageWidth * 0.35;

    final distance = sqrt(
      pow(centerX - screenCenterX, 2) + pow(centerY - screenCenterY, 2),
    );

    return distance <= guideRadius;
  }

  bool _isCenteredRelaxed(
    double centerX,
    double centerY,
    int width,
    int height,
  ) {
    final screenCenterX = width / 2;
    final screenCenterY = height / 2;
    final relaxedThresholdX = width * (centerTolerance * 1.5);
    final relaxedThresholdY = height * (centerTolerance * 1.5);

    return (centerX - screenCenterX).abs() < relaxedThresholdX &&
        (centerY - screenCenterY).abs() < relaxedThresholdY;
  }

  void _setChallengeState(String action) {
    switch (action) {
      case 'turn_left':
      case 'turn_right':
        _isInTurnChallenge = true;
        break;
      default:
        _isInTurnChallenge = false;
        break;
    }
  }

  Future<void> _processChallenge(Face face) async {
    if (waitingForNeutral) {
      if (_isNeutralPosition(face)) {
        setState(() {
          waitingForNeutral = false;
          _isInTurnChallenge = false;
        });
      }
      return;
    }

    final currentAction = challengeActions[currentActionIndex];
    _setChallengeState(currentAction);
    actionStartTimes[currentAction] ??= DateTime.now();

    final elapsed = DateTime.now().difference(actionStartTimes[currentAction]!);
    if (elapsed.inSeconds > 15) {
      _resetCurrentAction();
      return;
    }

    if (_validateChallengeAction(face, currentAction)) {
      await _completeAction(currentAction);
    }
  }

  bool _validateChallengeAction(Face face, String action) {
    switch (action) {
      case 'smile':
        return (face.smilingProbability ?? 0) > 0.55;
      case 'blink':
        return _detectBlink(face);
      case 'turn_left':
        return (face.headEulerAngleY ?? 0) > 18;
      case 'turn_right':
        return (face.headEulerAngleY ?? 0) < -18;
      default:
        return false;
    }
  }

  bool _wasBlinking = false;
  DateTime? _lastBlinkTime;

  bool _detectBlink(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEye + rightEye) / 2;

    if (avgEyeOpen < 0.35 && !_wasBlinking) {
      _wasBlinking = true;
      _lastBlinkTime = DateTime.now();
    } else if (avgEyeOpen > 0.7 && _wasBlinking) {
      _wasBlinking = false;

      if (_lastBlinkTime != null &&
          DateTime.now().difference(_lastBlinkTime!).inMilliseconds < 1000) {
        return true;
      }
    }

    return false;
  }

  bool _isNeutralPosition(Face face) {
    return (face.smilingProbability ?? 0) < 0.35 &&
        (face.leftEyeOpenProbability ?? 1.0) > 0.65 &&
        (face.rightEyeOpenProbability ?? 1.0) > 0.65 &&
        (face.headEulerAngleY?.abs() ?? 0) < 12;
  }

  Future<void> _completeAction(String action) async {
    if (completedActions[action] == true) return;

    setState(() {
      completedActions[action] = true;
      facePositionFeedback = 'Great job! Action completed successfully! 🎉';
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (currentActionIndex < challengeActions.length - 1) {
      setState(() {
        currentActionIndex++;
        waitingForNeutral = true;
      });
    } else {
      _completeLivenessVerification();
    }
  }

  void _resetCurrentAction() {
    final currentAction = challengeActions[currentActionIndex];
    actionStartTimes.remove(currentAction);
    setState(() {
      facePositionFeedback = 'Action timeout - please try again';
      _isInTurnChallenge = false;
    });
  }

  void _completeLivenessVerification() {
    setState(() {
      challengeCompleted = true;
      livenessStatus = '🎉 Liveness verified successfully! 🎉';
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<InputImage?> _createOptimizedInputImage(CameraImage image) async {
    try {
      List<InputImageFormat> formatsToTry = [
        InputImageFormat.nv21,
        InputImageFormat.yuv420,
        InputImageFormat.bgra8888,
      ];

      for (InputImageFormat format in formatsToTry) {
        try {
          InputImage? inputImage = await _createInputImageWithFormat(
            image,
            format,
          );
          if (inputImage != null) {
            return inputImage;
          }
        } catch (e) {
          continue;
        }
      }
      return null;
    } catch (e) {
      dev.log('💥 InputImage creation error: $e');
      return null;
    }
  }

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
          rotation: _getImageRotationDynamic(),
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List _createNV21BytesEnhanced(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uvSize = (image.width * image.height) ~/ 4;
    final nv21Bytes = Uint8List(ySize + 2 * uvSize);

    _copyPlaneWithStride(yPlane, nv21Bytes, 0, image.width, image.height);

    int uvIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      final uvPixelIndex =
          i ~/ image.width * (uPlane.bytesPerRow ~/ 2) + i % image.width;

      if (uvPixelIndex < vPlane.bytes.length &&
          uvPixelIndex < uPlane.bytes.length) {
        nv21Bytes[uvIndex++] = vPlane.bytes[uvPixelIndex];
        nv21Bytes[uvIndex++] = uPlane.bytes[uvPixelIndex];
      } else {
        nv21Bytes[uvIndex++] = vPlane.bytes[i % vPlane.bytes.length];
        nv21Bytes[uvIndex++] = uPlane.bytes[i % uPlane.bytes.length];
      }
    }

    return nv21Bytes;
  }

  Uint8List _createYUV420BytesEnhanced(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final ySize = image.width * image.height;
    final uSize = (image.width * image.height) ~/ 4;
    final vSize = (image.width * image.height) ~/ 4;
    final yuvBytes = Uint8List(ySize + uSize + vSize);

    _copyPlaneWithStride(yPlane, yuvBytes, 0, image.width, image.height);
    _copyPlaneWithStride(
      uPlane,
      yuvBytes,
      ySize,
      image.width ~/ 2,
      image.height ~/ 2,
    );
    _copyPlaneWithStride(
      vPlane,
      yuvBytes,
      ySize + uSize,
      image.width ~/ 2,
      image.height ~/ 2,
    );

    return yuvBytes;
  }

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

  InputImageRotation _getImageRotationDynamic() {
    return InputImageRotation.rotation270deg;
  }

  Future<void> testMLKitSetup() async {
    try {
      final testDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
          minFaceSize: 0.1,
        ),
      );
      await testDetector.close();
      dev.log('✅ ML Kit setup verified');
    } catch (e) {
      dev.log('💥 ML Kit setup error: $e');
    }
  }

  String _getPositioningFeedback({
    required Face face,
    required bool inFrame,
    required bool centered,
    required bool lookingStraight,
    required bool goodSize,
    required bool withinGuideCircle,
    required bool isTurnChallenge,
    required double centerX,
    required double screenCenterX,
    required double centerY,
    required double screenCenterY,
  }) {
    if (!inFrame) return 'Face not in frame - please move into view 📱';

    if (!centered) {
      return centerX < screenCenterX
          ? 'Move right to center your face - you\'re almost there!'
          : 'Move left to center your face - you\'re almost there!';
    }

    if (!lookingStraight) return 'Look straight ahead - keep your head level!';

    if (!goodSize) {
      return face.boundingBox.width * face.boundingBox.height < 10000
          ? 'Move closer to the camera - we need a clear view!'
          : 'Move back from the camera - you\'re too close!';
    }

    if (!withinGuideCircle) {
      if (isTurnChallenge) {
        return 'Keep your face in the guide circle while turning - you\'re doing great!';
      }
      return 'Position your face within the guide circle - you\'re almost there!';
    }

    if (isTurnChallenge) {
      return 'Perfect! Now turn back to center when ready!';
    }

    return 'Perfect! You\'re all set for verification! ✨';
  }

  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile naturally - just a gentle smile!';
      case 'blink':
        return 'blink your eyes - one natural blink is enough!';
      case 'turn_left':
        return 'turn your head left - stay in frame and turn back to center!';
      case 'turn_right':
        return 'turn your head right - stay in frame and turn back to center!';
      default:
        return action;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (isCameraInitialized) {
      cameraController.stopImageStream();
      cameraController.dispose();
    }
    faceDetector.close();
    _antiSpoofing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verify Your Identity',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CameraPreview(cameraController),
                  ),
                ),

                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: EnhancedHeadMaskPainter(
                        animationValue: _animationController.value,
                        isFaceQualityGood: isFaceQualityGood,
                        faceBoundingBox: faceBoundingBox,
                        isLivenessVerified: isLivenessVerified,
                        isFaceDetected: isFaceDetected,
                      ),
                      child: Container(),
                    );
                  },
                ),

                _buildInstructionPanel(),

                _buildStatusPanel(),

                _buildAntiSpoofingIndicator(),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amberAccent),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionPanel() {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFaceQualityGood ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              facePositionFeedback,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            if (isFaceQualityGood) ...[
              const SizedBox(height: 12),
              Text(
                'Please ${getActionDescription(challengeActions[currentActionIndex])}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // Show turn challenge indicator
              if (_isInTurnChallenge) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔄 Turn Challenge Active - Centering Relaxed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 12),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < challengeActions.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < currentActionIndex
                      ? Colors.green
                      : i == currentActionIndex
                      ? Colors.amberAccent
                      : Colors.grey.shade600,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${currentActionIndex + 1} of ${challengeActions.length}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQualityIndicator('Frame', isFaceInFrame),
                _buildQualityIndicator('Center', isFaceCentered),
                _buildQualityIndicator('Straight', isFaceLookingStraight),
                _buildQualityIndicator('Size', _isGoodSizeFromState()),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetectionValue(
                  'Smile',
                  smilingProbability != null
                      ? '${(smilingProbability! * 100).toStringAsFixed(0)}%'
                      : 'N/A',
                ),
                _buildDetectionValue(
                  'Eyes',
                  leftEyeOpenProbability != null &&
                          rightEyeOpenProbability != null
                      ? '${(((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(0)}%'
                      : 'N/A',
                ),
                _buildDetectionValue(
                  'Angle',
                  headEulerAngleY != null
                      ? '${headEulerAngleY!.toStringAsFixed(0)}°'
                      : 'N/A',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityIndicator(String label, bool isGood) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isGood ? Icons.check_circle : Icons.cancel,
          color: isGood ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isGood ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionValue(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAntiSpoofingIndicator() {
    return Positioned(
      top: 120,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLivenessVerified
              ? Colors.green.withValues(alpha: 0.9)
              : Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLivenessVerified ? Icons.verified_user : Icons.security,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              livenessStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isGoodSizeFromState() {
    if (faceBoundingBox == null) return false;
    final screenSize = MediaQuery.of(context).size;
    final faceArea = faceBoundingBox!.width * faceBoundingBox!.height;
    final screenArea = screenSize.width * screenSize.height;
    final ratio = faceArea / screenArea;
    return ratio >= minFaceSize && ratio <= maxFaceSize;
  }
}

class AntiSpoofingDetector {
  final List<FaceHistoryEntry> _faceHistory = [];
  static const int maxHistoryLength = 30;
  static const int minHistoryForAnalysis = 10;

  static const double minMotionVariance = 0.3;
  static const double maxStaticFrames = 0.8;

  final List<double> _faceSizeHistory = [];
  static const double minDepthVariation = 0.015;

  DateTime? _firstDetection;
  static const int minVerificationTime = 2;

  Future<LivenessResult> analyzeFaces(
    List<Face> faces,
    CameraImage image,
    DateTime timestamp,
  ) async {
    if (faces.isEmpty) {
      return LivenessResult(false, 'No face detected');
    }

    final face = faces.first;

    _addToHistory(face, timestamp);

    if (_faceHistory.length < minHistoryForAnalysis) {
      return LivenessResult(false, 'Collecting data...');
    }

    if (!_detectNaturalMotion()) {
      return LivenessResult(false, 'Please move naturally');
    }

    if (!_detectDepthVariation()) {
      return LivenessResult(false, 'Move closer/further slightly');
    }

    if (!_validateTiming()) {
      return LivenessResult(false, 'Verifying authenticity...');
    }

    return LivenessResult(true, 'Live person detected');
  }

  void _addToHistory(Face face, DateTime timestamp) {
    _faceHistory.add(
      FaceHistoryEntry(
        face: face,
        timestamp: timestamp,
        headRotation: _calculateHeadRotation(face),
        faceSize: _calculateFaceSize(face),
      ),
    );

    if (_faceHistory.length > maxHistoryLength) {
      _faceHistory.removeAt(0);
    }

    _faceSizeHistory.add(_calculateFaceSize(face));
    if (_faceSizeHistory.length > maxHistoryLength) {
      _faceSizeHistory.removeAt(0);
    }

    _firstDetection ??= timestamp;
  }

  double _calculateHeadRotation(Face face) {
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    return sqrt(yaw * yaw + pitch * pitch + roll * roll);
  }

  double _calculateFaceSize(Face face) {
    final box = face.boundingBox;
    return sqrt(box.width * box.width + box.height * box.height);
  }

  bool _detectNaturalMotion() {
    if (_faceHistory.length < minHistoryForAnalysis) return false;

    final rotations = _faceHistory.map((e) => e.headRotation).toList();
    final mean = rotations.reduce((a, b) => a + b) / rotations.length;
    final variance =
        rotations.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) /
        rotations.length;

    if (variance < minMotionVariance) {
      return false;
    }

    int staticFrames = 0;
    for (int i = 1; i < _faceHistory.length; i++) {
      final prev = _faceHistory[i - 1];
      final curr = _faceHistory[i];
      if ((curr.headRotation - prev.headRotation).abs() < 0.1) {
        staticFrames++;
      }
    }

    final staticRatio = staticFrames / _faceHistory.length;
    return staticRatio < maxStaticFrames;
  }

  bool _detectDepthVariation() {
    if (_faceSizeHistory.length < minHistoryForAnalysis) return false;

    final minSize = _faceSizeHistory.reduce(min);
    final maxSize = _faceSizeHistory.reduce(max);
    final sizeVariation = (maxSize - minSize) / maxSize;

    return sizeVariation >= minDepthVariation;
  }

  bool _validateTiming() {
    if (_firstDetection == null) return false;
    final elapsed = DateTime.now().difference(_firstDetection!);
    return elapsed.inSeconds >= minVerificationTime;
  }

  void dispose() {
    _faceHistory.clear();
    _faceSizeHistory.clear();
  }
}

class FaceHistoryEntry {
  final Face face;
  final DateTime timestamp;
  final double headRotation;
  final double faceSize;

  FaceHistoryEntry({
    required this.face,
    required this.timestamp,
    required this.headRotation,
    required this.faceSize,
  });
}

class LivenessResult {
  final bool isLive;
  final String reason;

  LivenessResult(this.isLive, this.reason);
}

class EnhancedHeadMaskPainter extends CustomPainter {
  final double animationValue;
  final bool isFaceQualityGood;
  final Rect? faceBoundingBox;
  final bool isLivenessVerified;
  final bool isFaceDetected;

  EnhancedHeadMaskPainter({
    required this.animationValue,
    required this.isFaceQualityGood,
    this.faceBoundingBox,
    required this.isLivenessVerified,
    required this.isFaceDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final baseRadius = size.width * 0.35;
    final animatedRadius = baseRadius + (animationValue * 10);

    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: animatedRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    Color guideColor;
    double guideAlpha;

    if (isLivenessVerified) {
      guideColor = Colors.green;
      guideAlpha = 0.8 + animationValue * 0.2;
    } else if (isFaceQualityGood && faceBoundingBox != null) {
      guideColor = Colors.blue;
      guideAlpha = 0.6 + animationValue * 0.3;
    } else if (isFaceDetected) {
      guideColor = Colors.orange;
      guideAlpha = 0.4 + animationValue * 0.2;
    } else {
      guideColor = Colors.grey;
      guideAlpha = 0.3 + animationValue * 0.1;
    }

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: guideAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, animatedRadius, guidePaint);

    if (faceBoundingBox != null) {
      _drawPositioningStatus(canvas, size, center, animatedRadius, guideColor);
    }

    if (faceBoundingBox != null) {
      _drawFaceBoundingBox(canvas, guideColor);
    }

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
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(backgroundRect, backgroundPaint);

    textPainter.paint(canvas, textPosition);
  }

  void _drawFaceBoundingBox(Canvas canvas, Color color) {
    if (faceBoundingBox == null) return;

    final boxPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(faceBoundingBox!, boxPaint);

    final cornerLength = 15.0;
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 1.0)
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
          corner.dx +
              cornerLength * (corner.dx < faceBoundingBox!.center.dx ? 1 : -1),
          corner.dy,
        )
        ..moveTo(corner.dx, corner.dy)
        ..lineTo(
          corner.dx,
          corner.dy +
              cornerLength * (corner.dy < faceBoundingBox!.center.dy ? 1 : -1),
        );

      canvas.drawPath(path, cornerPaint);
    }

    final centerPaint = Paint()
      ..color = color.withValues(alpha: 1.0)
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
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerLength = 25.0;
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
