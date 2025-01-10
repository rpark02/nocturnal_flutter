import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import 'dart:async';


abstract class BLEHandlerDelegate {
  void bleStatusDidUpdate(String status);
}

class BleHandler {
  BluetoothDevice? _peripheral;
  BluetoothCharacteristic? sendCharacteristic;
  bool loadedService = true;
  bool isConnected = false;

  BLEHandlerDelegate? delegate;
  BatchFileHandler batchManager = BatchFileHandler();

  // Device services and characteristics
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

    } catch (e) {
      print('Error initializing Bluetooth: $e');
      delegate?.bleStatusDidUpdate("Error initializing Bluetooth");
    }
  }


  // Device connection and seraching for services


}