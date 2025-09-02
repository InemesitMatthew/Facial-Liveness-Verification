import 'core.dart';

class PermDenied extends StatelessWidget {
  const PermDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission Denied')),
        body: Center(
          child: AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text('Camera access is required for verification.'),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
