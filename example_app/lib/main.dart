import 'package:flutter/material.dart';
import 'package:facial_liveness_verification/facial_liveness_verification.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facial Liveness Detection Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  LivenessResult? _lastResult;
  LivenessError? _lastError;
  bool _isVerificationInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liveness Detection Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Text(
              'Facial Liveness Detection Package Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a verification type to test different configurations:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Basic verification
            ElevatedButton.icon(
              onPressed: _isVerificationInProgress ? null : () => _startVerification(LivenessConfig()),
              icon: const Icon(Icons.face),
              label: const Text('Basic Verification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Default settings with standard challenges',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Quick verification
            ElevatedButton.icon(
              onPressed: _isVerificationInProgress ? null : () => _startVerification(LivenessConfig.basic()),
              icon: const Icon(Icons.speed),
              label: const Text('Quick Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Faster verification with fewer challenges',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Secure verification
            ElevatedButton.icon(
              onPressed: _isVerificationInProgress ? null : () => _startVerification(LivenessConfig.secure()),
              icon: const Icon(Icons.security),
              label: const Text('Secure Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Maximum security with all challenges',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Custom themed verification
            ElevatedButton.icon(
              onPressed: _isVerificationInProgress ? null : _startCustomVerification,
              icon: const Icon(Icons.palette),
              label: const Text('Custom Theme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Custom theme with purple colors',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Results section
            if (_lastResult != null || _lastError != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Last Result:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildResultWidget(),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_lastError != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Verification Failed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Error: ${_lastError!.message}'),
              Text('Code: ${_lastError!.code.name}'),
              Text('Recoverable: ${_lastError!.isRecoverable}'),
            ],
          ),
        ),
      );
    }

    if (_lastResult != null) {
      return Card(
        color: _lastResult!.isVerified ? Colors.green.shade50 : Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _lastResult!.isVerified ? Icons.check_circle : Icons.warning,
                    color: _lastResult!.isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _lastResult!.isVerified ? 'Verification Successful!' : 'Verification Incomplete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _lastResult!.isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Confidence: ${(_lastResult!.confidenceScore * 100).toStringAsFixed(1)}%'),
              Text('Total Time: ${_lastResult!.totalTime.inSeconds}s'),
              Text('Attempts: ${_lastResult!.attemptCount}'),
              Text('Completed Challenges: ${_lastResult!.completedChallenges.length}'),
              if (_lastResult!.completedChallenges.isNotEmpty)
                Text('Challenges: ${_lastResult!.completedChallenges.map((c) => c.actionName).join(', ')}'),
              Text('Anti-spoofing: ${_lastResult!.antiSpoofingResult.isLive ? "Passed" : "Failed"}'),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _startVerification(LivenessConfig config) {
    setState(() {
      _isVerificationInProgress = true;
      _lastResult = null;
      _lastError = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivenessDetectionWidget(
          config: config,
          onLivenessDetected: (result) {
            setState(() {
              _lastResult = result;
              _isVerificationInProgress = false;
            });
            Navigator.pop(context);
            _showResultDialog(result);
          },
          onError: (error) {
            setState(() {
              _lastError = error;
              _isVerificationInProgress = false;
            });
            Navigator.pop(context);
            _showErrorDialog(error);
          },
          onProgress: (challenge, progress) {
            debugPrint('Challenge: ${challenge.actionName}, Progress: ${progress.type.name}');
          },
          onCancel: () {
            setState(() {
              _isVerificationInProgress = false;
            });
            Navigator.pop(context);
          },
          showDebugInfo: true, // Enable debug info for demo
        ),
      ),
    );
  }

  void _startCustomVerification() {
    final customConfig = LivenessConfig(
      challengeTypes: const [
        ChallengeType.smile,
        ChallengeType.blink,
        ChallengeType.turnLeft,
      ],
      theme: LivenessTheme.dark().copyWith(
        primaryColor: Colors.purple,
        successColor: Colors.purpleAccent,
        challengeTextStyle: const TextStyle(
          color: Colors.purpleAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      sessionTimeout: const Duration(minutes: 3),
      challengeTimeout: const Duration(seconds: 15),
      customMessages: const InstructionMessages(
        facePositioned: 'Perfect! Ready for custom verification! 💜',
        verificationComplete: '🎉 Custom verification completed! 💜',
      ),
    );

    _startVerification(customConfig);
  }

  void _showResultDialog(LivenessResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isVerified ? Icons.check_circle : Icons.warning,
              color: result.isVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(result.isVerified ? 'Success!' : 'Incomplete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%'),
            Text('Total Time: ${result.totalTime.inSeconds} seconds'),
            Text('Challenges Completed: ${result.completedChallenges.length}'),
            if (result.completedChallenges.isNotEmpty)
              Text('Types: ${result.completedChallenges.map((c) => c.emoji).join(' ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(LivenessError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Verification Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: ${error.message}'),
            const SizedBox(height: 8),
            Text('Suggestion: ${error.code.userAction}'),
          ],
        ),
        actions: [
          if (error.isRecoverable)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Could retry here
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}