import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FanControlApp());
}

class FanControlApp extends StatelessWidget {
  const FanControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Fan Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const FanControlScreen(),
    );
  }
}

class FanControlScreen extends StatefulWidget {
  const FanControlScreen({super.key});

  @override
  _FanControlScreenState createState() => _FanControlScreenState();
}

class _FanControlScreenState extends State<FanControlScreen> {
  double temperature = 0.0;
  bool fanStatus = false;
  bool manualOverride = false;
  final String esp32Ip = "http://192.168.4.1"; // Replace with your ESP32 IP address

  @override
  void initState() {
    super.initState();
    fetchTemperatureAndStatus();
  }

  Future<void> fetchTemperatureAndStatus() async {
    try {
      final response = await http.get(Uri.parse('$esp32Ip/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['temperature'];
          fanStatus = data['fanStatus'];
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> toggleFan(bool status) async {
    try {
      final response = await http.post(
        Uri.parse('$esp32Ip/toggleFan'),
        body: {'status': status ? 'on' : 'off'},
      );
      if (response.statusCode == 200) {
        setState(() {
          fanStatus = status;
          manualOverride = true;
        });
      }
    } catch (e) {
      print("Error toggling fan: $e");
    }
  }

  void handleAutoControl() {
    if (!manualOverride) {
      if (temperature > 22.0 && !fanStatus) {
        toggleFan(true);
      } else if (temperature <= 22.0 && fanStatus) {
        toggleFan(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    handleAutoControl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Fan Control'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Temperature: ${temperature.toStringAsFixed(1)}°C',
              style: TextStyle(fontSize: 24, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 20),
            Text(
              'Fan Status: ${fanStatus ? 'ON' : 'OFF'}',
              style: TextStyle(
                  fontSize: 24,
                  color: fanStatus ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                toggleFan(!fanStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 60), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: Text(
                fanStatus ? 'Turn Fan OFF' : 'Turn Fan ON',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  manualOverride = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 60), // Full-width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Disable Manual Override',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
