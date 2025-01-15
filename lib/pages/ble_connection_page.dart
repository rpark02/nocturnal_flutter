import 'package:flutter/material.dart';

class BLEConnectionPage extends StatefulWidget {
  const BLEConnectionPage({super.key});

  @override
  State<BLEConnectionPage> createState() => _BLEConnectionPage();
}

class _BLEConnectionPage extends State<BLEConnectionPage> {
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
              onPressed: () {
                print('Test Connection pressed');
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
