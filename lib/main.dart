import 'core.dart';
import 'view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestCameraPermission();
  runApp(const MyApp());
}

Future<void> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    runApp(const PermDenied());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Face Verification',
      home: HomeView(),
    );
  }
}