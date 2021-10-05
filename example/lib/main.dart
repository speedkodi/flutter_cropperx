import 'dart:html' as html;
import 'dart:io' as io;

import 'package:cropperx/cropperx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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

class CropperScreen extends StatefulWidget {
  const CropperScreen({Key? key}) : super(key: key);

  @override
  State<CropperScreen> createState() => _CropperScreenState();
}

class _CropperScreenState extends State<CropperScreen> {
  final GlobalKey _cropperKey = GlobalKey(debugLabel: 'cropperKey');
  var _croppedFile;
  OverlayType _overlayType = OverlayType.circle;
  int _rotationTurns = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 500,
                child: Cropper(
                  cropperKey: _cropperKey,
                  overlayType: _overlayType,
                  rotationTurns: _rotationTurns,
                  image: Image.network(
                    'https://i.pinimg.com/originals/6b/4d/18/6b4d18c0b756ab20c3591490dfc10090.jpg',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  ElevatedButton(
                    child: const Text('Switch overlay'),
                    onPressed: () {
                      setState(() {
                        _overlayType = _overlayType == OverlayType.circle
                            ? OverlayType.grid
                            : _overlayType == OverlayType.grid
                                ? OverlayType.rectangle
                                : OverlayType.circle;
                      });
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Crop image'),
                    onPressed: () async {
                      final imageBytes = await Cropper.crop(
                        cropperKey: _cropperKey,
                      );

                      final tempDir = await getTemporaryDirectory();
                      final path = tempDir.path;
                      final fileName =
                          'crop_${DateTime.now().millisecondsSinceEpoch}';

                      final file = kIsWeb
                          ? html.File(imageBytes, '$path/$fileName.png')
                          : await io.File('$path/$fileName.png')
                              .writeAsBytes(imageBytes);

                      setState(() {
                        _croppedFile = file;
                      });
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _rotationTurns--);
                    },
                    icon: const Icon(Icons.rotate_left),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _rotationTurns++);
                    },
                    icon: const Icon(Icons.rotate_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_croppedFile != null)
                Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Image.file(_croppedFile!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
