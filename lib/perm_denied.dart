import 'core.dart';

class PermDenied extends StatelessWidget {
  const PermDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission denied')),
        body: Center(
          child: AlertDialog(
            title: Text("Permission Denied"),
            content: Text("Camera access is required for verification."),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
