import 'package:flutter/material.dart';
import 'pages/ble_connection_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: BLEConnectionPage()
    );
  }
}
