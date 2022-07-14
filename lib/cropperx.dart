import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Cropper extends StatefulWidget {
  /// The cropper's key to reference when calling the crop function.
  final GlobalKey? cropperKey;

  /// The background color of the cropper widget, visible when the image won't
  /// fill the entire widget. Defaults to a light grey color: Color(0xFFCECECE).
  final Color backgroundColor;

  /// The color of the cropper's overlay. Defaults to semi-transparent black
  /// Colors.black54
  final Color overlayColor;

  /// The type of semi-transparent overlay. Can either be an
  /// [OverlayType.circle] or [OverlayType.none] to hide the overlay. Defaults
  /// to none so no overlay is shown by default.
  final OverlayType overlayType;

  /// The maximum scale the user is able to zoom. Defaults to 2.5
  final double zoomScale;

  /// The aspect ratio to crop the image to. Defaults to a square (an aspect ratio of 1.0)
  final double aspectRatio;

  /// The number of clockwise quarter turns the image should be rotated. Defaults to 0.
  final int rotationTurns;

  /// The thickness of the grid lines. Defaults to 2.0.
  final double gridLineThickness;

  /// The image to crop.
  Image image;

  /// Backup initial image to reset method
  final Image initialImage;

  /// The called when scale start.
  final GestureScaleStartCallback? onScaleStart;

  /// The called when scale update.
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// The called when scale end.
  final GestureScaleEndCallback? onScaleEnd;

  Cropper({
    Key? key,
    this.backgroundColor = const Color(0xFFCECECE),
    this.overlayColor = Colors.black38,
    this.overlayType = OverlayType.none,
    this.zoomScale = 2.5,
    this.gridLineThickness = 2.0,
    this.aspectRatio = 1,
    this.rotationTurns = 0,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    required this.cropperKey,
    required this.image,
  })  : initialImage = image,
        super(key: key);

  @override
  State<Cropper> createState() => _CropperState();

  /// Crops the image as displayed in the cropper widget, converts it to PNG format and returns it
  /// as [Uint8List]. The cropper widget should be referenced using its key.
  static Future<Uint8List?> crop({
    required GlobalKey cropperKey,
    double pixelRatio = 3,
  }) async {
    // Get cropped image
    final renderObject = cropperKey.currentContext!.findRenderObject();
    final boundary = renderObject as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    // Convert image to bytes in PNG format and return
    final byteData = await image.toByteData(
      format: ImageByteFormat.png,
    );
    final pngBytes = byteData?.buffer.asUint8List();

    return pngBytes;
  }

  /// Reset the image to initial state
  static void reset({required GlobalKey cropperKey}) {
    final state =
        cropperKey.currentContext!.findAncestorStateOfType() as _CropperState;
    state.setImageToInitialState();
  }
}

class _CropperState extends State<Cropper> {
  late final TransformationController _transformationController;

  /// Boolean to indicate if the image has been updated after a state change. Used so we don't do
  /// any unnecessary refreshes.
  late bool _hasImageUpdated;

  /// Boolean to indicate whether we need to set the initial scale of an image.
  bool _shouldSetInitialScale = false;
  bool _shouldUpdateScale = false;

  /// The image configuration used to add the image stream listener to the image.
  final _imageConfiguration = const ImageConfiguration();

  /// Image stream listener which is used to indicate whether the image has finished loading. This
  /// is required to do the initial scaling of the [InteractiveViewer], where we'd like to fill the
  /// viewport by scaling the image down as much as possible.
  late final _imageStreamListener = ImageStreamListener(
    (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _shouldSetInitialScale = true;
        });
      });
    },
  );

  @override
  void initState() {
    super.initState();
    _hasImageUpdated = true;
    _transformationController = TransformationController();
  }

  @override
  void didUpdateWidget(covariant Cropper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasImageUpdated = oldWidget.image.image != widget.image.image;
    _shouldUpdateScale = oldWidget.rotationTurns != widget.rotationTurns;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              key: widget.cropperKey,
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: LayoutBuilder(
                  builder: (_, constraint) {
                    return InteractiveViewer(
                      clipBehavior: Clip.none,
                      transformationController: _transformationController,
                      constrained: false,
                      child: Builder(
                        builder: (context) {
                          final imageStream = widget.image.image.resolve(
                            _imageConfiguration,
                          );
                          if (_hasImageUpdated && _shouldSetInitialScale) {
                            imageStream.removeListener(_imageStreamListener);
                            _setInitialScale(context, constraint.biggest);
                          }

                          if (_hasImageUpdated && !_shouldSetInitialScale) {
                            imageStream.addListener(_imageStreamListener);
                          }

                          if (_shouldUpdateScale) {
                            _setInitialScale(context, constraint.biggest);
                            _shouldUpdateScale = false;
                          }

                          return RotatedBox(
                            quarterTurns: widget.rotationTurns,
                            child: widget.image,
                          );
                        },
                      ),
                      minScale: 0.1,
                      maxScale: widget.zoomScale,
                      onInteractionStart: widget.onScaleStart,
                      onInteractionUpdate: widget.onScaleUpdate,
                      onInteractionEnd: widget.onScaleEnd,
                    );
                  },
                ),
              ),
            ),
            if (widget.overlayType == OverlayType.circle ||
                widget.overlayType == OverlayType.rectangle)
              Positioned.fill(
                child: ClipPath(
                  clipper: _OverlayFrame(
                    aspectRatio: widget.aspectRatio,
                    isCircle: widget.overlayType == OverlayType.circle,
                  ),
                  child: Container(
                    color: widget.overlayColor,
                  ),
                ),
              ),
            if (widget.overlayType == OverlayType.grid ||
                widget.overlayType == OverlayType.gridHorizontal)
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Divider(
                      color: widget.overlayColor,
                      thickness: widget.gridLineThickness,
                    ),
                    Divider(
                      color: widget.overlayColor,
                      thickness: widget.gridLineThickness,
                    ),
                  ],
                ),
              ),
            if (widget.overlayType == OverlayType.grid ||
                widget.overlayType == OverlayType.gridVertical)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VerticalDivider(
                      color: widget.overlayColor,
                      thickness: widget.gridLineThickness,
                    ),
                    VerticalDivider(
                      color: widget.overlayColor,
                      thickness: widget.gridLineThickness,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void setImageToInitialState() {
    setState(() {
      widget.image = widget.initialImage;
    });
  }

  double _getCoverRatio(Size outside, Size inside) {
    return outside.width / outside.height > inside.width / inside.height
        ? outside.width / inside.width
        : outside.height / inside.height;
  }

  double _getTranslationX(Size outside, Size inside, coverRatio) {
    return (outside.width / coverRatio - inside.width) / 2;
  }

  double _getTranslationY(Size outside, Size inside, coverRatio) {
    return (outside.height / coverRatio - inside.height) / 2;
  }

  void _setInitialScale(BuildContext context, Size parentSize) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      final childSize = renderBox?.size ?? Size.zero;
      if (childSize != Size.zero) {
        final coverRatio = _getCoverRatio(parentSize, childSize);
        final value = Matrix4.identity() * coverRatio;

        // Center the image inside the InteractiveViewer
        value.translate(_getTranslationX(parentSize, childSize, coverRatio),
            _getTranslationY(parentSize, childSize, coverRatio), 0.0);

        _transformationController.value = value;
      }

      _shouldSetInitialScale = false;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

enum OverlayType { circle, rectangle, grid, gridHorizontal, gridVertical, none }

class _OverlayFrame extends CustomClipper<Path> {
  final double aspectRatio;
  final bool isCircle;

  _OverlayFrame({
    required this.aspectRatio,
    this.isCircle = false,
  });

  @override
  Path getClip(Size size) {
    double _height = aspectRatio >= 1 ? size.width / aspectRatio : size.height;
    double _width = aspectRatio <= 1 ? size.height * aspectRatio : size.width;

    final opening = Path();
    if (isCircle) {
      opening.addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: min(_height, _width) / 2,
        ),
      );
    } else {
      opening.addRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          height: _height,
          width: _width,
        ),
      );
    }

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      opening..close(),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) =>
      aspectRatio != (oldClipper as _OverlayFrame).aspectRatio;
}
