import 'package:flutter/material.dart';

void main() {
  runApp(const RyanGunshopApp());
}

/// Kerangka awal aplikasi RyanGunshop.
class RyanGunshopApp extends StatelessWidget {
  const RyanGunshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RyanGunshop',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('RyanGunshop'))),
    );
  }
}
