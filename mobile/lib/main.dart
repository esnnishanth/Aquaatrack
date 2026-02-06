import 'package:flutter/material.dart';
import 'pages/home.dart';

void main() {
  runApp(const AquaTrackApp());
}

class AquaTrackApp extends StatelessWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Track',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}
