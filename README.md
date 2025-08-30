# Facial Liveness Verification

A Flutter-based application that provides facial liveness detection and verification using Google's ML Kit for face detection. This application helps verify that a real person is present during authentication by analyzing facial movements and responses to challenges.

## Features

- **Real-time Face Detection**: Uses Google ML Kit for accurate face detection and tracking
- **Liveness Challenges**: Multiple verification actions including smiling, blinking, and head movements
- **Visual Feedback**: Animated guides and real-time positioning assistance
- **Cross-Platform**: Works on Android and iOS devices
- **Permission Handling**: Proper camera permission requests and error handling

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0 or higher)
- Android Studio or Xcode (for device testing)
- A device with a front-facing camera

### Installation

1. Clone the repository:
```bash
git clone https://github.com/InemesitMatthew/Facial-Liveness-Verification.git
cd Facial-Liveness-Verification
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Usage

1. Launch the application
2. Grant camera permissions when prompted
3. Click the "Verify Now" button to begin
4. Follow the on-screen instructions to complete the liveness challenges:
   - Position your face within the guide circle
   - Perform the requested actions (smile, blink, etc.)
   - Complete all challenges to verify your identity

## Project Structure

```
lib/
├── core.dart          # Core exports and dependencies
├── main.dart          # Application entry point
├── home.dart          # Home screen with verification button
├── face_detect.dart   # Main face detection and liveness logic
├── perm_denied.dart   # Permission denied screen
└── view.dart          # View exports
```

## Dependencies

This project uses several key packages:

- `camera`: For accessing device cameras
- `permission_handler`: For managing camera permissions
- `google_mlkit_face_detection`: For face detection capabilities
- `flutter/material`: For UI components

## Technical Details

The application uses production-optimized thresholds for:
- Face positioning (15% tolerance)
- Head angle detection (12 degrees)
- Face size validation (30-80% of screen)
- Challenge validation with precise probability thresholds

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.

## Acknowledgments

- Google ML Kit for face detection capabilities
- Flutter team for the excellent framework
- The open-source community for various inspiration and solutions
