import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data'; // handles binary data
import 'dart:async'; // Stream and StreamSubscription

abstract class BLEHandlerDelegate {
  void bleStatusDidUpdate(String status);
  void bleDevicesDidUpdate(List<BluetoothDevice> devices); // Add this delegate
}

class BLEHandler {
  BluetoothDevice? _peripheral; // BLE device
  BluetoothCharacteristic? sendCharacteristic; // send data to device
  bool loadedService = true;
  bool isConnected = false;

  BLEHandlerDelegate? delegate;

  static const String NAME = "Nocturnal";
  static const String UUID_PROX_SERVICE = "19B10000-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_IMU_SERVICE = "19B10001-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_STATUS_SERVICE = "19B10002-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_WRITE_SERVICE = "19B10003-E8F2-537E-4F6C-D104768A1214";
  
  static const String UUID_PROX_UUID = "19B10000-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_CURR_UUID = "19B10001-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_IMU_UUID = "19B10002-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_STATUS_UUID = "19B10003-E8F2-537E-4F6C-D104768A1215";

  static const String UUID_WRITE = "19B10004-E8F2-537E-4F6C-D104768A1215";

  List<int> writeArr = [65, 0, 0, 0];

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;

  // Device initialization and scanning
  Future<void> initDevice() async {
    print("Initiating Bluetooth");

    try {
      // Check bluetooth adapter state
      final state = await FlutterBluePlus.adapterState.first;
      print('Initial Bluetooth adapter state: $state');

      if (state == BluetoothAdapterState.on) {
        print("Bluetooth is on. Starting scan.");
        FlutterBluePlus.startScan();
      } else {
        delegate?.bleStatusDidUpdate("Bluetooth is ${state.toString()}");
        print("Bluetooth state is off. State: $state");
      }

      adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        print("Bluetooth adapter state changed: $state");
        if (state == BluetoothAdapterState.on) {
          print("Bluetooth turned on, starting scan.");
          FlutterBluePlus.startScan();
        } else {
          delegate?.bleStatusDidUpdate("Bluetooth is ${state.toString()}");
          print("Bluetooth state changed to: $state");
        }
      });

      if (await FlutterBluePlus.isSupported) {
        print("Bluetooth is supported.");
      } else {
        delegate?.bleStatusDidUpdate("Bluetooth not supported");
        print("Bluetooth is not supported on this device.");
      }
    } catch (e) {
      print('Error initializing Bluetooth: $e');
      delegate?.bleStatusDidUpdate("Error initializing Bluetooth");
    }
  }


  // Device connection and searching for services
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.stopScan();
      scanSubscription?.cancel();

      List<BluetoothDevice> foundDevices = [];
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.platformName.contains(NAME)) {
            foundDevices.add(r.device);
          }
        }
        delegate?.bleDevicesDidUpdate(foundDevices); // Send found devices to delegate
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('Error scanning: $e');
      delegate?.bleStatusDidUpdate("Error scanning for devices");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      scanSubscription?.cancel();

      await device.connect(timeout: const Duration(seconds: 4), autoConnect: false);
      delegate?.bleStatusDidUpdate("Connected to ${device.platformName}");

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            await characteristic.read();
          }

          if (characteristic.uuid.toString() == UUID_WRITE) {
            if (characteristic.properties.write) {
              sendCharacteristic = characteristic;
              loadedService = true;
            }
          }

          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristicSubscription = characteristic.lastValueStream.listen(
              (value) => _handleCharacteristicValue(characteristic, value),
              onError: (error) => print('Characteristic notification error: $error'),
            );
          }
        }
      }

      isConnected = true;
      device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          handleDisconnect();
        }
      });
    } catch (e) {
      print('Failed to connect: $e');
      delegate?.bleStatusDidUpdate("Failed to connect");
      handleDisconnect();
    }
  }

  void handleDisconnect() {
    isConnected = false;
    loadedService = false;
    delegate?.bleStatusDidUpdate("Disconnected from device");

    characteristicSubscription?.cancel();
    initDevice();
  }

  void _handleCharacteristicValue(BluetoothCharacteristic characteristic, List<int> value) {
    String timestamp = DateTime.now().toIso8601String();
  }

  Future<void> updateSettings() async {
    if (loadedService && isConnected && sendCharacteristic != null) {
      try {
        await sendCharacteristic!.write(writeArr, withoutResponse: false);
      } catch (e) {
        print('Failed to write characteristic: $e');
        delegate?.bleStatusDidUpdate("Failed to update settings");
      }
    }
  }

  Future<void> turnOnStim({required bool isActive, required int strength, required int freq}) async {
    if (isActive) {
      writeArr = [strength, 66, 66, freq];
      await updateSettings();
    } else {
      writeArr = [65, 0, 0, 0];
      await updateSettings();
    }
  }

  Future<void> turnOffStim() async {
    writeArr = [65, 0, 0, 0];
    await updateSettings();
  }

  Future<void> modifyStim({required bool isActive, required int strength, required int freq}) async {
    writeArr = [65, 0, 0, 0];
    await updateSettings();

    if (!isActive) return;

    writeArr = [strength, 66, 66, freq];
    await updateSettings();
  }

  Future<void> dispose() async {
    try {
      scanSubscription?.cancel();
      adapterStateSubscription?.cancel();
      characteristicSubscription?.cancel();

      if (_peripheral != null && isConnected) {
        await _peripheral!.disconnect();
      }

      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error during disposal: $e');
    }
  }
}
