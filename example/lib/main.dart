import 'dart:typed_data';

import 'package:cropperx/cropperx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _cropperKey = GlobalKey(debugLabel: 'cropperKey');
  Uint8List? _imageToCrop;
  Uint8List? _croppedImage;
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
                child: _imageToCrop != null
                    ? Cropper(
                        cropperKey: _cropperKey,
                        overlayType: _overlayType,
                        rotationTurns: _rotationTurns,
                        image: Image.memory(_imageToCrop!),
                      )
                    : const ColoredBox(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  ElevatedButton(
                    child: const Text('Pick image'),
                    onPressed: () async {
                      final image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image != null) {
                        final imageBytes = await image.readAsBytes();
                        setState(() {
                          _imageToCrop = imageBytes;
                        });
                      }
                    },
                  ),
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

                      if (imageBytes != null) {
                        setState(() {
                          _croppedImage = imageBytes;
                        });
                      }
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
              if (_croppedImage != null)
                Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Image.memory(_croppedImage!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
