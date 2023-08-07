import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class WallpaperWithText extends StatelessWidget {
  final String wallpaperUrl;
  final String text;
  final double textOpacity;
  final double boxWidth;
  final double boxHeight;
  final double textScale;

  WallpaperWithText({
    required this.wallpaperUrl,
    required this.text,
    required this.textOpacity,
    required this.boxWidth,
    required this.boxHeight,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Display the wallpaper image
        wallpaperUrl.startsWith('http')
            ? Image.network(
          wallpaperUrl,
          fit: BoxFit.cover,
        )
            : Image.file(
          File(wallpaperUrl),
          fit: BoxFit.cover,
        ),
        // Display the text box on top of the image
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onScaleStart: (details) {
              // Store the initial text scale value before scaling
              var _textScaleStart = textScale;
            },
            onScaleUpdate: (details) {
              // Handle scaling and other update logic here
              // ...
            },
            child: Transform.scale(
              scale: textScale,
              child: Container(
                padding: EdgeInsets.all(16.0),
                // Wrap the container with Opacity and set the opacity only for the background color
                color: Colors.black.withOpacity(textOpacity),
                width: boxWidth,
                height: boxHeight,
                child: SizedBox(
                  width: 200.0,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
