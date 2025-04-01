import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, NetworkAssetBundle;
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'cache_helper.dart';

/// Returns a small circular marker icon from a network image URL.
Future<BitmapDescriptor> getCircleMarkerIcon(
  String networkImageUrl, {
  double size = 100,
}) async {
  debugPrint("[getCircleMarkerIcon] Starting for URL: $networkImageUrl");

  // 1. Fetch the image from the network as bytes
  final imageBytes = await _loadNetworkImageBytes(networkImageUrl);
  debugPrint("[getCircleMarkerIcon] Fetched network image, size: ${imageBytes.lengthInBytes} bytes");

  // 2. Decode to ui.Image
  final ui.Codec codec = await ui.instantiateImageCodec(
    imageBytes,
    targetWidth: size.toInt(),
    targetHeight: size.toInt(),
  );
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ui.Image image = frameInfo.image;
  debugPrint("[getCircleMarkerIcon] Decoded image to ui.Image with size: "
      "${image.width}x${image.height}");

  // 3. Draw a circle
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..isAntiAlias = true;
  final double radius = size / 2;

  final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
  canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  final Rect imageRect = Rect.fromLTWH(0, 0, size, size);
  paint.filterQuality = FilterQuality.high;
  canvas.drawImageRect(image, imageRect, imageRect, paint);

  final ui.Picture picture = pictureRecorder.endRecording();
  final ui.Image clippedImage = await picture.toImage(size.toInt(), size.toInt());
  debugPrint("[getCircleMarkerIcon] Drew circle image: "
      "${clippedImage.width}x${clippedImage.height}");

  final ByteData? byteData =
      await clippedImage.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    debugPrint("[getCircleMarkerIcon] ERROR: byteData is null");
    throw Exception('Failed to convert circle marker image to ByteData.');
  }

  // 4. Convert to BitmapDescriptor
  final Uint8List pngBytes = byteData.buffer.asUint8List();
  debugPrint("[getCircleMarkerIcon] Successfully converted circle image to PNG bytes (length: ${pngBytes.length})");
  return BitmapDescriptor.fromBytes(pngBytes);
}

Future<BitmapDescriptor> getPinMarkerIcon(
  String networkImageUrl, {
  double pinWidth = 100,
  String pinAssetPath = 'assets/marker_asset.png',
}) async {
  final String cacheKey = 'pin_${networkImageUrl.hashCode}_$pinWidth';
  final cachedBytes = await loadCachedImageBytes(cacheKey);
  if (cachedBytes != null) {
    debugPrint("[getPinMarkerIcon] Loaded cached pin marker for key: $cacheKey");
    return BitmapDescriptor.fromBytes(cachedBytes);
  }
  
  debugPrint("[getPinMarkerIcon] Processing pin marker for URL: $networkImageUrl");

  // Load the pin asset image from assets.
  final Uint8List pinBytes = await _loadAssetBytes(pinAssetPath);
  final ui.Codec pinCodec = await ui.instantiateImageCodec(
    pinBytes,
    targetWidth: pinWidth.toInt(),
  );
  final ui.FrameInfo pinFrame = await pinCodec.getNextFrame();
  final ui.Image pinImage = pinFrame.image;

  // Create a circular version of the user’s photo.
  final double circleSize = pinWidth * 0.45;
  final Uint8List circleBytes = await createCircleImageBytes(networkImageUrl, circleSize);

  // Compose the pin and circle together.
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint paint = Paint()..isAntiAlias = true;
  
  // Draw the pin image.
  canvas.drawImage(pinImage, Offset.zero, paint);

  // Decode the circle image.
  final ui.Codec circleCodec = await ui.instantiateImageCodec(circleBytes);
  final ui.FrameInfo circleFrame = await circleCodec.getNextFrame();
  final ui.Image circleImg = circleFrame.image;
  
  // Position the circle in the center of the pin (adjust as needed).
  final double circleX = (pinImage.width - circleImg.width) / 2;
  final double circleY = (pinImage.height * 0.22);
  canvas.drawImage(circleImg, Offset(circleX, circleY), paint);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image finalImage = await picture.toImage(pinImage.width, pinImage.height);
  final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to convert pinned marker to ByteData.');
  }

  final Uint8List pngBytes = byteData.buffer.asUint8List();
  
  // Cache the composed pin marker.
  await cacheImageBytes(cacheKey, pngBytes);
  debugPrint("[getPinMarkerIcon] Cached pin marker with key: $cacheKey");
  
  return BitmapDescriptor.fromBytes(pngBytes);
}



Future<Uint8List> createCircleImageBytes(String url, double size) async {
  // Create a cache key based on URL and desired size.
  final String cacheKey = 'circle_${url.hashCode}_$size';
  
  // Check if we have a cached version.
  final cachedBytes = await loadCachedImageBytes(cacheKey);
  if (cachedBytes != null) {
    debugPrint("[createCircleImageBytes] Loaded cached image for key: $cacheKey");
    return cachedBytes;
  }

  debugPrint("[createCircleImageBytes] Processing image for URL: $url, size: $size");

  // Original processing: fetch the image bytes and create a circular marker.
  final imageBytes = await _loadNetworkImageBytes(url);
  final ui.Codec codec = await ui.instantiateImageCodec(
    imageBytes,
    targetWidth: size.toInt(),
    targetHeight: size.toInt(),
  );
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ui.Image image = frameInfo.image;

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..isAntiAlias = true;
  final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
  canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(size / 2)));
  final Rect imageRect = Rect.fromLTWH(0, 0, size, size);
  paint.filterQuality = FilterQuality.high;
  canvas.drawImageRect(image, imageRect, imageRect, paint);

  final ui.Picture picture = pictureRecorder.endRecording();
  final ui.Image clippedImage = await picture.toImage(size.toInt(), size.toInt());
  final ByteData? byteData = await clippedImage.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to convert circle image to ByteData.');
  }

  final Uint8List pngBytes = byteData.buffer.asUint8List();
  
  // Cache the processed image.
  await cacheImageBytes(cacheKey, pngBytes);
  debugPrint("[createCircleImageBytes] Cached image with key: $cacheKey");
  
  return pngBytes;
}

/// Load a network image into bytes.
Future<Uint8List> _loadNetworkImageBytes(String url) async {
  debugPrint("[_loadNetworkImageBytes] Loading network URL: $url");
  final Uri uri = Uri.parse(url);

  // If there's a problem (like an invalid URL), this could throw or return 0 bytes
  final ByteData data = await NetworkAssetBundle(uri).load(url);
  debugPrint("[_loadNetworkImageBytes] Successfully loaded $url");
  return data.buffer.asUint8List();
}

/// Load a local asset (the pin image).
Future<Uint8List> _loadAssetBytes(String assetPath) async {
  debugPrint("[_loadAssetBytes] Loading asset: $assetPath");
  final ByteData byteData = await rootBundle.load(assetPath);
  debugPrint("[_loadAssetBytes] Loaded asset: $assetPath, size: ${byteData.lengthInBytes} bytes");
  return byteData.buffer.asUint8List();
}

Future<BitmapDescriptor> getResizedMarkerIcon(String assetPath, int width, int height) async {
  final ByteData data = await rootBundle.load(assetPath);
  final ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
    targetHeight: height,
  );
  final ui.FrameInfo fi = await codec.getNextFrame();
  final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List resizedBytes = byteData!.buffer.asUint8List();
  return BitmapDescriptor.fromBytes(resizedBytes);
}