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
        title: Text('Verify Your Identity'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please click the button below to start verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 29),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final cameras = await availableCameras();
                if (context.mounted) {
                  if (cameras.isNotEmpty) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceDetectionView(),
                      ),
                    );
                    if (context.mounted) {
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verification successful')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Camera not active!')),
                        );
                      }
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                foregroundColor: Colors.black,
                backgroundColor: Colors.amberAccent,
              ),
              child: Text(
                'Verify Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
