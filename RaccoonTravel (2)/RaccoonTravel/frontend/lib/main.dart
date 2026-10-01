import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const RaccoonTravelApp());
}

class RaccoonTravelApp extends StatelessWidget {
  const RaccoonTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaccoonTravel',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
