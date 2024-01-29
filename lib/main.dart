import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageViewer(),
    );
  }
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({Key? key}) : super(key: key);

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  img.Image? image;
  img.Image? orig;

  @override
  void initState() {
    readImage().then((image) {
      orig = image;
      assert(image != null);
      final Uint8List bytes = getBytes(image!);
      final Uint8List inverted = invertColor(
        bytes: bytes,
        width: image.width,
        height: image.height,
      );
      final img.Image invertedImage = img.Image.fromBytes(
        bytes: inverted.buffer,
        width: image.width,
        height: image.height,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
        format: img.Format.uint8,
      );

      setState(() {
        this.image = invertedImage;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (orig != null) Image.memory(img.encodePng(orig!)),
          if (image != null) Image.memory(img.encodePng(image!)),
        ],
      ),
    );
  }
}

Future<img.Image?> readImage() async {
  final XFile? imageFile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 100,
  );
  final bytes = await imageFile?.readAsBytes();
  if (bytes == null) {
    return null;
  }

  return img.decodeImage(bytes)?.convert(numChannels: 4);
}

Uint8List getBytes(img.Image image) {
  return image.getBytes(order: img.ChannelOrder.rgba, alpha: 255);
}

int getIndex({
  required int x,
  required int y,
  required int width,
  required int height,
}) =>
    y * width * 4 + x * 4;

img.ColorUint8 getColor({
  required Uint8List bytes,
  required int index,
}) {
  final int r = bytes[index];
  final int g = bytes[index + 1];
  final int b = bytes[index + 2];
  final int a = bytes[index + 3];

  return img.ColorUint8.rgba(r, g, b, a);
}

Uint8List invertColor({
  required Uint8List bytes,
  required int width,
  required int height,
}) {
  Uint8List inverted = Uint8List(bytes.length);
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      final int index = getIndex(
        x: x,
        y: y,
        width: width,
        height: height,
      );

      final img.ColorUint8 color = getColor(
        bytes: bytes,
        index: index,
      );

      inverted[index] = 255 - color.r.toInt();
      inverted[index + 1] = 255 - color.g.toInt();
      inverted[index + 2] = 255 - color.b.toInt();
      inverted[index + 3] = color.a.toInt();
    }
  }
  return inverted;
}
