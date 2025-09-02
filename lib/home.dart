import 'core.dart';
import 'view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        toolbarHeight: 70,
        centerTitle: true,
                    title: const Text('Verify Your Identity'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please click the button below to start verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 29),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startVerification(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                foregroundColor: Colors.black,
                backgroundColor: Colors.amberAccent,
              ),
              child: const Text(
                'Verify Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startVerification(BuildContext context) async {
    final cameras = await availableCameras();
    if (!context.mounted || cameras.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceDetectionView(),
      ),
    );

    if (!context.mounted) return;

    final message = result == true ? 'Verification successful' : 'Camera not active!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
