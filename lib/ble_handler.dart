import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data'; // handles binary data
import 'dart:async'; // Stream and StreamSubscription


abstract class BLEHandlerDelegate {
  void bleStatusDidUpdate(String status);
}

class BLEHandler {
  BluetoothDevice? _peripheral; // BLE device
  BluetoothCharacteristic? sendCharacteristic; // send data to device
  bool loadedService = true;
  bool isConnected = false;

  BLEHandlerDelegate? delegate;
  // BatchFileHandler batchManager = BatchFileHandler();

  // Device services
  static const String NAME = "Nocturnal";
  static const String UUID_PROX_SERVICE = "19B10000-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_IMU_SERVICE = "19B10001-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_STATUS_SERVICE = "19B10002-E8F2-537E-4F6C-D104768A1214";
  static const String UUID_WRITE_SERVICE = "19B10003-E8F2-537E-4F6C-D104768A1214";
  
  // Device characteristics
  static const String UUID_PROX_UUID = "19B10000-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_CURR_UUID = "19B10001-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_IMU_UUID = "19B10002-E8F2-537E-4F6C-D104768A1215";
  static const String UUID_STATUS_UUID = "19B10003-E8F2-537E-4F6C-D104768A1215";

  static const String UUID_WRITE = "19B10004-E8F2-537E-4F6C-D104768A1215";

  List<int> writeArr = [65, 0, 0, 0];

  // Subscription management
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;


  // Device initialization and scanning
  Future<void> initDevice() async {
    print("Initiating Bluetooth");

    try {
      // Check bluetooth adapter state
      await FlutterBluePlus.adapterState.first;

      adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          FlutterBluePlus.startScan();
        } else {
          delegate?.bleStatusDidUpdate("Bluetooth is ${state.toString()}");
        }
      });

      if (await FlutterBluePlus.isSupported) {
        FlutterBluePlus.startScan();
      } else {
        delegate?.bleStatusDidUpdate("Bluetooth not supported");
      }

    } catch (e) {
      print('Error initializing Bluetooth: $e');
      delegate?.bleStatusDidUpdate("Error initializing Bluetooth");
    }
  }

  // Device connection and searching for services
  Future<void> startScan() async {
    try {
      // Stop any existing scan
      await FlutterBluePlus.stopScan();
      
      // Start scanning
      scanSubscription?.cancel();
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.platformName.contains(NAME)) {
            _peripheral = r.device;
            connectToDevice(r.device);
          }
        }
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

  // Device connection
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Cancel scanning
      await FlutterBluePlus.stopScan();
      scanSubscription?.cancel();

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 4),
        autoConnect: false,
      );
      
      delegate?.bleStatusDidUpdate("Connected to ${device.platformName}");
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Check for the read property
          if (characteristic.properties.read) {
            print("${characteristic.uuid}: properties contains read");
            await characteristic.read();
          }

          // Check for the write property
          if (characteristic.uuid.toString() == UUID_WRITE) {
            if (characteristic.properties.write) {
              print("${characteristic.uuid}: properties contains write");
              sendCharacteristic = characteristic;
              loadedService = true;
            } else {
              print("${characteristic.uuid}: found matching UUID but characteristic is not writable");
            } 
          }
          
          // Check for and set up notifications
          if (characteristic.properties.notify) {
            print("${characteristic.uuid}: properties contains notify");
            await characteristic.setNotifyValue(true);
            
            // Cancel any existing subscription
            characteristicSubscription?.cancel();
            characteristicSubscription = characteristic.lastValueStream.listen(
              (value) => _handleCharacteristicValue(characteristic, value),
              onError: (error) => print('Characteristic notification error: $error'),
            );
          }
        }
      }
      
      isConnected = true;

      // Listen for disconnection
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

  // Manage disconnection to device
  void handleDisconnect() {
    isConnected = false;
    loadedService = false;
    delegate?.bleStatusDidUpdate("Disconnected from device");
    
    // Clean up subscriptions
    characteristicSubscription?.cancel();
    
    // Attempt to reconnect
    initDevice();
  }

  // Process incoming data using batch manager
  void _handleCharacteristicValue(BluetoothCharacteristic characteristic, List<int> value) {
    String timestamp = DateTime.now().toIso8601String();
    // batchManager.processData(Uint8List.fromList(value), characteristic.uuid.toString(), timestamp);
  }

  // Update settings and get data
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

  // STIMULATION CONTROL METHODS
  Future<void> turnOnStim({required bool isActive, required int strength, required int freq}) async {
    if (isActive) {
      writeArr = [strength, 66, 66, freq];
      await updateSettings();
    } else {
      writeArr = [65, 0, 0, 0];
      await updateSettings();
    }
    createStartMarker();
  }

  Future<void> turnOffStim() async {
    writeArr = [65, 0, 0, 0];
    await updateSettings();
    createStopMarker();
  }

  Future<void> modifyStim({required bool isActive, required int strength, required int freq}) async {
    writeArr = [65, 0, 0, 0];
    await updateSettings();
    
    if (!isActive) return;
    
    writeArr = [strength, 66, 66, freq];
    await updateSettings();
    
    createModifyMarker();
  }

  // MARKER CREATION
  void createStartMarker() {
    String dataStr = writeArr.join(',');
    String timestamp = DateTime.now().toIso8601String();
    // batchManager.processDataMarker(dataStr, "START", timestamp);
  }

  void createStopMarker() {
    String dataStr = writeArr.join(',');
    String timestamp = DateTime.now().toIso8601String();
    // batchManager.processDataMarker(dataStr, "STOP", timestamp);
  }

  void createModifyMarker() {
    String dataStr = writeArr.join(',');
    String timestamp = DateTime.now().toIso8601String();
    // batchManager.processDataMarker(dataStr, "CHANGE", timestamp);
  }

  // CLEANUP METHOD for when disposing of BLE Handler
  Future<void> dispose() async {
    try {
      // Cancel all subscriptions
      scanSubscription?.cancel();
      adapterStateSubscription?.cancel();
      characteristicSubscription?.cancel();
      
      // Disconnect from peripheral if connected
      if (_peripheral != null && isConnected) {
        await _peripheral!.disconnect();
      }
      
      // Stop scanning if still scanning
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error during disposal: $e');
    }
  }
}
