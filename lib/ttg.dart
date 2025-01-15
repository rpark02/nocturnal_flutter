import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_handler.dart'; // Import the BLEHandler file

class BLEConnectionPage extends StatefulWidget {
  const BLEConnectionPage({super.key});

  @override
  State<BLEConnectionPage> createState() => _BLEConnectionPage();
}

class _BLEConnectionPage extends State<BLEConnectionPage> implements BLEHandlerDelegate {
  late BLEHandler bleHandler;
  String bleStatus = "Initializing...";
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Initialize BLEHandler and assign the delegate
    bleHandler = BLEHandler()..delegate = this;
    bleHandler.initDevice();
  }

  @override
  void dispose() {
    // Dispose BLEHandler to clean up resources
    bleHandler.dispose();
    super.dispose();
  }

  @override
  void bleStatusDidUpdate(String status) {
    // Update BLE status in the UI
    setState(() {
      bleStatus = status;
    });
  }

  void startScan() async {
    setState(() {
      isScanning = true;
    });
    await bleHandler.startScan();
    setState(() {
      isScanning = false;
    });
  }

  void updateSettings() async {
    await bleHandler.updateSettings();
    setState(() {
      bleStatus = "Settings updated!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE2DFFD),
      appBar: AppBar(
        title: Text('Bluetooth Connection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Bluetooth Status: $bleStatus',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: isScanning
                  ? null
                  : () {
                      startScan();
                    },
              child: Text(
                isScanning ? 'Scanning...' : 'Start Scan',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: updateSettings,
              child: Text(
                'Update Settings',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                print('I\'m Connected!');
              },
              child: Text(
                'I\'m Connected!',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
