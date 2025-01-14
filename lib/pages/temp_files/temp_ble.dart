import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEConnectionPage extends StatefulWidget {
  const BLEConnectionPage({super.key});

  @override
  State<BLEConnectionPage> createState() => _BLEConnectionPage();
}

class _BLEConnectionPage extends State<BLEConnectionPage> {
  final List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    // Start scanning for BLE devices
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((scanResults) {
      for (var result in scanResults) {
        if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectedDevice = device;
    });

    try {
      await device.connect();
      print('Connected to ${device.platformName}');
      discoverServices(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> discoveredServices = await device.discoverServices();
      setState(() {
        services = discoveredServices;
      });
    } catch (e) {
      print('Error discovering services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2DFFD),
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
      ),
      body: connectedDevice == null
          ? ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'),
                  subtitle: Text(device.remoteId.toString()),
                  onTap: () => connectToDevice(device),
                );
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Connected to ${connectedDevice?.platformName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return ExpansionTile(
                        title: Text('Service: ${service.uuid}'),
                        children: service.characteristics.map((characteristic) {
                          return ListTile(
                            title: Text('Characteristic: ${characteristic.uuid}'),
                            subtitle: Text('Properties: ${characteristic.properties}'),
                            onTap: () async {
                              if (characteristic.properties.read) {
                                var value = await characteristic.read();
                                print('Read value: $value');
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
