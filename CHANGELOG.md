# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `CoordinateUtils` utility class for coordinate transformations
  - `convertImageRectToScreenRect()` - Converts ML Kit image coordinates to screen coordinates for UI overlays
  - `calculateTargetRect()` - Calculates target rectangle for face positioning guidance
- Comprehensive documentation in example app showing how to use the package
- Better inline documentation throughout codebase

## [2.0.0] - 2025-10-04

### Changed (Breaking)
- **Complete refactor** - Package is now logic-focused, developers handle UI
- Removed all UI widgets (`LivenessDetectionWidget`, `SimpleLivenessWidget`)
- Removed all preset configs (`.minimal()`, `.passive()`, `.basic()`, `.secure()`, `.performance()`)
- Removed theme system - developers build their own UI
- Simplified configuration - just essential options, no presets

### Added
- Simple `LivenessDetector` class with stream-based state updates
- Exposed `cameraController` for custom UI integration
- Stream-based `LivenessState` for reactive UI
- Simplified `LivenessConfig` with direct properties (no nested configs)
- Clean file structure: `detector/`, `challenges/`, `anti_spoofing/`, `models/`, `utils/`
- Test structure for core components

### Removed
- All UI widgets and painters
- Theme system
- Preset configurations
- Complex nested configuration classes
- UI-related models and utilities

### Migration Guide

**Old API (removed):**
```dart
LivenessDetectionWidget(
  config: LivenessConfig.secure(),
  onLivenessDetected: (result) => ...,
)
```

**New API:**
```dart
final detector = LivenessDetector(const LivenessConfig());
await detector.initialize();
await detector.start();

detector.stateStream.listen((state) {
  // Handle state updates
});

// Use detector.cameraController for UI
CameraPreview(detector.cameraController!)
```

## [1.0.0] - 2025-08-31

### Added
- Initial release of facial_liveness_verification package
- Real-time face detection using Google ML Kit
- Advanced anti-spoofing protection with motion analysis
- Interactive challenge system (smile, blink, head turns, nod)
- Customizable UI and theming for brand consistency
- Comprehensive error handling with recovery options
- Performance optimized for various device capabilities
- Easy integration with callback-based API
- Multiple built-in configurations (minimal, passive, basic, secure, performance)
- Ultra-simple one-liner integration with `showLivenessCheck()`
- Simple widget integration with `SimpleLivenessWidget`
- Complete theme customization system
- Custom overlay painter for face guidance
- iOS camera permissions configuration
- Cross-platform support (Android, iOS, Windows, macOS, Linux)
- Comprehensive documentation and examples
