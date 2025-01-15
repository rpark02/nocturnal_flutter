import 'package:flutter/material.dart';
import '../ble_handler.dart';


class BLEConnectionPage extends StatefulWidget {
  const BLEConnectionPage({super.key});

  @override
  State<BLEConnectionPage> createState() => _BLEConnectionPage();
}

class _BLEConnectionPage extends State<BLEConnectionPage> implements BLEHandlerDelegate {
  late BLEHandler bleHandler;

  @override
  void initState() {
    super.initState();
    bleHandler = BLEHandler()..delegate = this;
    bleHandler.initDevice();
  }

  @override
  void bleStatusDidUpdate(String status) {
    print('BLE Status: $status');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status)),
    );
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
                'Click the button below to make sure your sleep mask is connected to your device. If connected, the mask should flash white lights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20, // Adjusted font size for better layout
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 40),
            FilledButton(
              onPressed: () {
                bleHandler.initDevice();
              },
              child: Text(
                'Test Connection',
                style: TextStyle(
                  fontSize: 16, // Adjusted font size for better layout
                ),
              ),
            ),
            SizedBox(height: 30),
            FilledButton(
              onPressed: () {
                print('I\'m Connected!');
              },
              child: Text(
                'I\'m Connected!',
                style: TextStyle(
                  fontSize: 16, // Adjusted font size for better layout
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
