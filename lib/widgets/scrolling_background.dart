import 'package:flutter/material.dart';

class ScrollingBackground extends StatelessWidget {
  final String imagePath;
  final double bgX;
  final double? aspectRatio;

  const ScrollingBackground({
    super.key,
    required this.imagePath,
    required this.bgX,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback aspect ratio if not provided
        double ratio = aspectRatio ?? (1920 / 1080);
        double renderedWidth = constraints.maxHeight * ratio;
        
        // Normalize bgX to a negative offset based on renderedWidth
        double offset = bgX % renderedWidth;
        if (offset > 0) offset -= renderedWidth;

        // Calculate how many images we need to cover the screen width
        int imageCount = (constraints.maxWidth / renderedWidth).ceil() + 1;
        if (imageCount < 2) imageCount = 2;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: List.generate(imageCount, (index) {
            return Positioned(
              left: offset + (index * renderedWidth),
              top: 0,
              bottom: 0,
              width: renderedWidth,
              child: Image.asset(imagePath, fit: BoxFit.fitHeight, alignment: Alignment.centerLeft),
            );
          }),
        );
      },
    );
  }
}
