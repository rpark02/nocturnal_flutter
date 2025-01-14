import 'dart:async';
import 'dart:convert';

class BatchFileHandler {
  final List<String> dataBuffer = [];
  // final DateFormat dateFormatter = DateFormat('dd_MM_yyyyTHH_mm_ssZ');
  final String baseURL = 'https://batch-collection.nocturnal.health';
  Timer? disconnectionTimer;
  bool isDisconnected = false;
  final Duration disconnectionTimeout = const Duration(seconds: 10);


  String dataToHexString(List<int> data) {
    return data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  String generateFileName() {
    final DateFormat formatter = DateFormat('HH_mm');
    return 'session_${formatter.format(DateTime.now())}.csv';
  }

  Future<void> saveAndUploadData() async {
    if (dataBuffer.isEmpty) return;

    final fileName = generateFileName();
    final headers = 'timestamp,uuid,data\n';
    final content = headers + dataBuffer.join();
    
    try {
      
    }

  } 
}