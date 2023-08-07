import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'wallpaper_with_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDirectory = await getApplicationDocumentsDirectory();
  final assetsDirectory = Directory('${appDirectory.path}/assets');
  if (!assetsDirectory.existsSync()) {
    assetsDirectory.createSync();
  }
  runApp(WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blueGrey,
      ),
      home: WallpaperScreen(),
    );
  }
}

class WallpaperScreen extends StatefulWidget {
  @override
  _WallpaperScreenState createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  final List<String> wallpaperUrls = [
    'assets/Pic1.jpg', // Replace with your asset image paths
    'assets/Pic2.jpg',
    'assets/Pic3.jpg',
    'assets/Pic4.jpg',
    'assets/Pic5.jpg',
    'assets/Pic6.jpg',
    'assets/Pic7.jpg',
    'assets/Pic8.jpg',
    // Add other URLs here...
  ];

  final List<String> uploadedFiles = [];

  int _selectedItemIndex = 0;
  PageController _pageController = PageController(initialPage: 0);
  TextEditingController _textEditingController = TextEditingController();
  double _textOpacity = 0.6;
  double _boxWidth = 200.0;
  double _boxHeight = 100.0;
  double _textScale = 1.0;
  double _textScaleStart = 1.0;
  FocusNode _focusNode = FocusNode();
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Remove the cursor when losing focus
        _focusNode.canRequestFocus = false;
      }
    });
  }


  // Add this function for requesting storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
  }


  Future<Uint8List?> _captureWallpaperWithText() async {
    try {
      // Use the screenshot package to capture the PageView with the wallpaper and text
      final image = await screenshotController.capture(
        pixelRatio: 1.0,
        delay: Duration(milliseconds: 20),
      );
      return image;
    } catch (e) {
      debugPrint('Failed to capture wallpaper with text: $e');
      return null;
    }
  }

  // Modify this function for downloading and saving the wallpaper
  Future<void> _downloadWallpaper(List<String> allWallpapers) async {
    final isPermissionGranted = await _requestStoragePermission();
    if (!isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied!')),
      );
      return;
    }

    try {
      // Capture the wallpaper with text as an image
      final imageBytes = await _captureWallpaperWithText();
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture wallpaper with text!')),
        );
        return;
      }

      // Save the image to the gallery
      final result = await ImageGallerySaver.saveImage(Uint8List.fromList(imageBytes));
      if (result['isSuccess']) {
        // Show a snackbar indicating successful download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper downloaded successfully!')),
        );
      } else {
        // Handle download errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download wallpaper!')),
        );
      }
    } catch (e) {
      // Handle download errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download wallpaper!')),
      );
    }
  }


  void _shareWallpaper() {
    // Implement the share functionality here
  }

  void _deleteWallpaper(int index) {
    setState(() {
      if (index < wallpaperUrls.length) {
        // If the index is within the range of wallpaperUrls, it means it's a URL and not an uploaded image
        // So, remove it from wallpaperUrls list directly.
        wallpaperUrls.removeAt(index);
      } else {
        // If the index is equal to or greater than wallpaperUrls.length, it means it's an uploaded image
        // Calculate the actual index in the uploadedFiles list.
        int uploadedIndex = index - wallpaperUrls.length;
        // Check if the uploadedIndex is within the range of uploadedFiles list.
        if (uploadedIndex >= 0 && uploadedIndex < uploadedFiles.length) {
          // If yes, remove the image from uploadedFiles list.
          uploadedFiles.removeAt(uploadedIndex);
        }
      }

      // After removing the image, reset the selected item index to 0 (the first image).
      _selectedItemIndex = 0;
      // Jump to the first image page after deletion
      _pageController.jumpToPage(0);
    });


  }


  void _uploadImage() async {
    final filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
      final platformFile = filePickerResult.files.first;
      if (platformFile.path != null) {
        // The selected file is picked using the file picker
        final file = File(platformFile.path!);

        final appDirectory = await getApplicationDocumentsDirectory();
        final fileName = path.basename(file.path);
        final localFilePath = path.join(appDirectory.path, fileName);

        // Copy the selected file to the application documents directory
        await file.copy(localFilePath);

        setState(() {
          uploadedFiles.add(localFilePath);
          _selectedItemIndex = wallpaperUrls.length + uploadedFiles.length - 1;
          _pageController.animateToPage(
            _selectedItemIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      } else {
        // The selected file is an asset image
        final assetPath = platformFile.bytes!;
        setState(() {
          uploadedFiles.add('asset'); // Dummy value to indicate an asset image
          _selectedItemIndex = wallpaperUrls.length + uploadedFiles.length - 1;
          _pageController.animateToPage(
            _selectedItemIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final List<String> allWallpapers = [...wallpaperUrls, ...uploadedFiles];

    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(120.0, 16.0, 120.0, 16.0),
                  color: Colors.blue,
                  child: Text(
                    'Header',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(56.0, 0.0, 56.0, 0.0),
                    child: Screenshot(
                      controller: screenshotController,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: allWallpapers.length,
                        itemBuilder: (context, index) {
                          final wallpaper = allWallpapers[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // Display the wallpaper image
                              wallpaper.startsWith('http')
                                  ? CachedNetworkImage(
                                imageUrl: wallpaper,
                                fit: BoxFit.cover,
                              )
                                  : wallpaper.startsWith('asset')
                                  ? Image.asset(
                                wallpaper,
                                fit: BoxFit.cover,
                              )
                                  : Image.file(
                                File(wallpaper),
                                fit: BoxFit.cover,
                              ),
                              // Display the text box on top of the image
                              Align(
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  onScaleStart: (details) {
                                    // Store the initial text scale value before scaling
                                    _textScaleStart = _textScale;
                                  },
                                  onScaleUpdate: (details) {
                                    setState(() {
                                      // Calculate the new text scale value based on the initial text scale value and the scale update
                                      _textScale = (_textScaleStart * details.scale).clamp(0.5, 2.0);
                                      // Update the box width based on the new text scale value
                                      _boxWidth = 200.0 * _textScale;
                                      // Update the box height based on the new text scale value
                                      _boxHeight = 100.0 * _textScale;
                                    });
                                  },
                                  child: Transform.scale(
                                    scale: _textScale,
                                    child: Container(
                                      padding: EdgeInsets.all(16.0),
                                      // Wrap the container with Opacity and set the opacity only for the background color
                                      color: Colors.black.withOpacity(_textOpacity),
                                      width: _boxWidth,
                                      height: _boxHeight,
                                      child: SizedBox(
                                        width: 200.0,
                                        child: TextField(
                                          controller: _textEditingController,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,

                                            // Remove the cursor and underline
                                            border: InputBorder.none,
                                            hintText: 'Enter Text',
                                            hintStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            // Handle text changes here
                                          },
                                          // Set maxLines to null to allow text to wrap to the next line automatically
                                          maxLines: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        onPageChanged: (index) {
                          setState(() {
                            _selectedItemIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 0.0),
                    color: Colors.blue,
                    child: Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: RawMaterialButton(
                            onPressed: _shareWallpaper,
                            shape: CircleBorder(),
                            fillColor: Colors.black,
                            child: Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Flexible(
                          flex: 1,
                              child: IconButton(
                                icon: Icon(Icons.download),
                                onPressed: () => _downloadWallpaper(allWallpapers),
                                color: Colors.white,
                              )

                        ),
                        SizedBox(width: 8.0),
                        Flexible(
                          flex: 1,
                          child: RawMaterialButton(
                            onPressed: () => _deleteWallpaper(_selectedItemIndex),
                            shape: CircleBorder(),
                            fillColor: Colors.black,
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Flexible(
                          flex: 2,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2.0,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                              overlayShape: RoundSliderOverlayShape(
                                overlayRadius: 50.0,
                              ),
                            ),
                            child: Slider(
                              value: _textOpacity,
                              onChanged: (value) {
                                setState(() {
                                  _textOpacity = value;
                                });
                              },
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200.0,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allWallpapers.length + 1,
              itemBuilder: (context, index) {
                if (index == allWallpapers.length) {
                  return GestureDetector(
                    onTap: _uploadImage,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        onPressed: _uploadImage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(4.0),
                          shape: CircleBorder(),
                          primary: Colors.white,
                        ),
                        child: Icon(
                          Icons.upload,
                          size: 50.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                } else {
                  final wallpaper = allWallpapers[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedItemIndex = index;
                        _pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Display the wallpaper image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              width: 120.0,
                              height: 170.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedItemIndex == index
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: wallpaper.startsWith('http')
                                  ? CachedNetworkImage(
                                imageUrl: wallpaper,
                                fit: BoxFit.cover,
                              )
                                  : wallpaper.startsWith('asset')
                                  ? Image.asset(
                                wallpaper,
                                fit: BoxFit.cover,
                              )
                                  : Image.file(
                                File(wallpaper),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Display the delete button only on the selected image with opacity
                          if (_selectedItemIndex == index)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Opacity(
                                opacity: 0.6,
                                child: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteWallpaper(index),
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
              },
            )
          ),
        ],
      ),
    );
  }
}