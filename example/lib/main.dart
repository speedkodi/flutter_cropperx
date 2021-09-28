import 'package:example/cropper_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropperX Example',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
      ),
      home: const CropperScreen(),
    );
  }
}