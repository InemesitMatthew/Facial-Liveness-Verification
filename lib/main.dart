import 'core.dart';
import 'view.dart';

void main() async {
  // Initialize the camera permission
  WidgetsFlutterBinding.ensureInitialized();
  await requestCameraPermission();

  runApp(const MyApp());
}

/// Requests camera permission from the user
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    // Handle permission denial
    runApp(const PermDenied());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Face Verification",
      home: HomeView(),
    );
  }
}

/**
 * void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await Permission.camera.request();
  runApp(MyApp(hasPermission: status.isGranted));
}

class MyApp extends StatelessWidget {
  final bool hasPermission;

  const MyApp({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: hasPermission ? const HomeView() : const PermDenied(),
    );
  }
}

 */