import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_handler.dart'; // Make sure to import BLEHandler

class BLEConnectionPage extends StatefulWidget {
  const BLEConnectionPage({Key? key}) : super(key: key);

  @override
  _BLEConnectionPageState createState() => _BLEConnectionPageState();
}

class _BLEConnectionPageState extends State<BLEConnectionPage> implements BLEHandlerDelegate {
  late BLEHandler bleHandler;
  String bleStatus = "Initializing...";
  bool isScanning = false;
  List<BluetoothDevice> availableDevices = [];

  @override
  void initState() {
    super.initState();
    bleHandler = BLEHandler()..delegate = this;
    bleHandler.initDevice();
  }

  @override
  void dispose() {
    bleHandler.dispose();
    super.dispose();
  }

  @override
  void bleStatusDidUpdate(String status) {
    setState(() {
      bleStatus = status;
    });
  }

  @override
  void bleDevicesDidUpdate(List<BluetoothDevice> devices) {
    setState(() {
      availableDevices = devices;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2DFFD),
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Bluetooth Status: $bleStatus',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isScanning ? null : startScan,
              child: Text(isScanning ? 'Scanning...' : 'Start Scan', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            if (availableDevices.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Available Devices:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...availableDevices.map((device) => ListTile(
                    title: Text(device.name),
                    onTap: () {
                      bleHandler.connectToDevice(device);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
