import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cropperx/cropper.dart';
import 'package:path_provider/path_provider.dart';

class CropperScreen extends StatefulWidget {
  const CropperScreen({Key? key}) : super(key: key);

  @override
  State<CropperScreen> createState() => _CropperScreenState();
}

class _CropperScreenState extends State<CropperScreen> {
  final GlobalKey _cropperKey = GlobalKey(debugLabel: 'cropperKey');
  File? _croppedFile;
  OverlayType _overlayType = OverlayType.circle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(36.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Cropper(
                    cropperKey: _cropperKey,
                    overlayType: _overlayType,
                    image: Image.network(
                      'https://i.pinimg.com/originals/6b/4d/18/6b4d18c0b756ab20c3591490dfc10090.jpg',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text('Switch overlay'),
                    onPressed: () {
                      setState(() {
                        _overlayType = _overlayType == OverlayType.circle
                            ? OverlayType.grid
                            : OverlayType.circle;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    child: const Text('Crop image'),
                    onPressed: () async {
                      Directory tempDir = await getTemporaryDirectory();
                      final path = tempDir.path;
                      final fileName = 'crop_${DateTime.now().millisecondsSinceEpoch}.png';

                      final file = await Cropper.crop(
                        cropperKey: _cropperKey,
                        path: path,
                        fileName: fileName,
                      );
                      setState(() {
                        _croppedFile = file;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_croppedFile != null) Padding(
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
