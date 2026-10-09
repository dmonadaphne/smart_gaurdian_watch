import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as Math;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SmartGuardianWatch());
}

class SmartGuardianWatch extends StatelessWidget {
  const SmartGuardianWatch({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Guardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = "Monitoring";
  int fallCount = 0;
  bool isFallDetected = false;
  
  double accelX = 0, accelY = 0, accelZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;
  
  int fallConfidence = 0;
  final int fallThreshold = 3;
  final double impactThreshold = 20.0;

  // Emergency contact (CHANGE THIS TO YOUR NUMBER)
  String emergencyContact = "+91XXXXXXXXXX";

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    accelerometerEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        accelX = event.x;
        accelY = event.y;
        accelZ = event.z;
      });
      _detectFall(event.x, event.y, event.z);
    });
    
    gyroscopeEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        gyroX = event.x;
        gyroY = event.y;
        gyroZ = event.z;
      });
    });
  }

  void _detectFall(double x, double y, double z) {
    if (isFallDetected) return;
    double magnitude = Math.sqrt(x * x + y * y + z * z);
    
    if (magnitude > impactThreshold) {
      fallConfidence++;
      if (fallConfidence >= fallThreshold) {
        _triggerFall();
      }
    } else {
      if (fallConfidence > 0) fallConfidence--;
    }
  }

  void _triggerFall() {
    setState(() {
      isFallDetected = true;
      status = "🚨FALL!";
      fallCount++;
      fallConfidence = 0;
    });
    _showConfirmationDialog();
  }

void _showConfirmationDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        title: const Text(
          '🚨 FALL!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Are you OK?',
          style: TextStyle(fontSize: 13, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        actionsPadding: const EdgeInsets.all(4),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      status = "Monitoring";
                      isFallDetected = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'YES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendSOS();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'HELP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

void _sendSOS() async {
  setState(() {
    status = "📤SOS...";
  });

  String message = "🚨 EMERGENCY! Fall detected!\n";
  message += "📍 Location: GPS unavailable\n";
  message += "⏰ Time: ${DateTime.now().toLocal()}";
  
  try {
    // Method 1: Try SMS intent
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyContact,
      queryParameters: {'body': message},
    );
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      setState(() {
        status = "✅SOS SENT!";
      });
    } else {
      // Method 2: Try without contact number
      final Uri fallbackUri = Uri(
        scheme: 'sms',
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        setState(() {
          status = "✅SMS OPENED";
        });
      } else {
        // Method 3: Just show the message
        _showMessageDialog(message);
        setState(() {
          status = "✅SMS READY";
        });
      }
    }
  } catch (e) {
    // If all else fails, show message in dialog
    _showMessageDialog(message);
    setState(() {
      status = "✅MESSAGE READY";
    });
  }

  // Reset after 4 seconds
  await Future.delayed(const Duration(seconds: 4));
  if (mounted) {
    setState(() {
      status = "Monitoring";
      isFallDetected = false;
    });
  }
}

void _showMessageDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('🚨 SOS MESSAGE', style: TextStyle(fontSize: 14)),
        content: Text(message, style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 14)),
          ),
        ],
      );
    },
  );
}
  void resetStatus() {
    setState(() {
      status = "Monitoring";
      isFallDetected = false;
      fallConfidence = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SG', style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        toolbarHeight: 28,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isFallDetected ? Colors.red[900] : Colors.green[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFallDetected ? Colors.red[300] : Colors.green[300],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$fallCount',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 3),
            
            // Sensor data
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    'A:${accelX.toStringAsFixed(0)},${accelY.toStringAsFixed(0)},${accelZ.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                  Text(
                    'G:${gyroX.toStringAsFixed(0)},${gyroY.toStringAsFixed(0)},${gyroZ.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                  Text(
                    'C:$fallConfidence',
                    style: const TextStyle(fontSize: 8, color: Colors.blue),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 3),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _triggerFall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 22),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(fontSize: 8),
                  ),
                  child: const Text('FALL'),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: resetStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 22),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(fontSize: 8),
                  ),
                  child: const Text('RESET'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}