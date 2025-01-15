
  // Retrieve device services (for testing)
  Future<List<String>> getDeviceServices() async {
    List<String> serviceNames = [];
    if (_peripheral == null) return serviceNames;

    try {
      List<BluetoothService> services = await _peripheral!.discoverServices();
      for (BluetoothService service in services) {
        serviceNames.add(service.uuid.toString());
      }
    } catch (e) {
      print('Error getting services: $e');
    }
    return serviceNames;
  }

  // Retrieve characteristics of a service (for testing)
  Future<List<String>> getServiceCharacteristics(String serviceUuid) async {
    List<String> characteristicUuids = [];
    if (_peripheral == null) return characteristicUuids;

    try {
      List<BluetoothService> services = await _peripheral!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            characteristicUuids.add(characteristic.uuid.toString());
          }
        }
      }
    } catch (e) {
      print('Error getting characteristics: $e');
    }
    return characteristicUuids;
  }

  // Subscribe to a characteristic for notifications (for testing)
  Future<void> subscribeToCharacteristic(String serviceUuid, String characteristicUuid) async {
    if (_peripheral == null) return;

    try {
      List<BluetoothService> services = await _peripheral!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUuid) {
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                characteristicSubscription = characteristic.lastValueStream.listen(
                  (value) => _handleCharacteristicValue(characteristic, value),
                  onError: (error) => print('Characteristic notification error: $error'),
                );
                delegate?.bleStatusDidUpdate("Subscribed to $characteristicUuid");
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error subscribing to characteristic: $e');
      delegate?.bleStatusDidUpdate("Failed to subscribe to characteristic");
    }
  }