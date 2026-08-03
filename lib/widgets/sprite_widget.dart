import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;

class SpriteWidget extends StatefulWidget {
  final String imagePath;
  final int frameCount;
  final int spriteWidth;
  final int spriteHeight;
  final Duration animationDuration;
  final double scale;
  final bool loop;
  final bool isVertical;

  const SpriteWidget({
    super.key,
    required this.imagePath,
    required this.frameCount,
    required this.spriteWidth,
    required this.spriteHeight,
    this.animationDuration = const Duration(milliseconds: 600),
    this.scale = 1.0,
    this.loop = true,
    this.isVertical = false,
  });

  @override
  State<SpriteWidget> createState() => _SpriteWidgetState();
}

class _SpriteWidgetState extends State<SpriteWidget> {
  int currentFrame = 0;
  Timer? timer;
  ui.Image? _image;
  bool _loading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
    startAnimation();
  }

  void _loadImage() async {
    final ImageProvider provider = AssetImage(widget.imagePath);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _image = info.image;
          _loading = false;
        });
      }
    }));
  }

  void startAnimation() {
    final frameDuration = widget.animationDuration ~/ widget.frameCount;
    timer = Timer.periodic(frameDuration, (timer) {
      if (mounted) {
        setState(() {
          if (!widget.loop && currentFrame == widget.frameCount - 1) {
            _isFinished = true;
            timer.cancel();
          } else {
            currentFrame = (currentFrame + 1) % widget.frameCount;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(SpriteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
    if (oldWidget.imagePath != widget.imagePath || oldWidget.frameCount != widget.frameCount || oldWidget.loop != widget.loop) {
      timer?.cancel();
      currentFrame = 0;
      _isFinished = false;
      startAnimation();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _image == null || _isFinished) {
      return SizedBox(
        width: widget.spriteWidth * widget.scale,
        height: widget.spriteHeight * widget.scale,
      );
    }

    return CustomPaint(
      size: Size(widget.spriteWidth * widget.scale, widget.spriteHeight * widget.scale),
      painter: _SpritePainter(
        image: _image!,
        currentFrame: currentFrame,
        frameCount: widget.frameCount,
        isVertical: widget.isVertical,
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int currentFrame;
  final int frameCount;
  final bool isVertical;

  _SpritePainter({
    required this.image,
    required this.currentFrame,
    required this.frameCount,
    this.isVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    bool vertical = isVertical || (image.height > image.width && frameCount > 1);

    double srcFrameWidth;
    double srcFrameHeight;
    Rect srcRect;

    if (vertical) {
      srcFrameWidth = image.width.toDouble();
      srcFrameHeight = image.height / frameCount;
      srcRect = Rect.fromLTWH(
        0,
        currentFrame * srcFrameHeight,
        srcFrameWidth,
        srcFrameHeight,
      );
    } else {
      srcFrameWidth = image.width / frameCount;
      srcFrameHeight = image.height.toDouble();
      srcRect = Rect.fromLTWH(
        currentFrame * srcFrameWidth,
        0,
        srcFrameWidth,
        srcFrameHeight,
      );
    }

    Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    Paint paint = Paint()..filterQuality = FilterQuality.none;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.currentFrame != currentFrame ||
        oldDelegate.image != image ||
        oldDelegate.isVertical != isVertical;
  }
}
