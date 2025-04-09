import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

//this file is meant to experinment with catcheing user markers so we dont have to wait for them to load
/// Generates a cache file path based on a key.
Future<String> _getCacheFilePath(String key) async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/$key.png';
}

/// Loads cached image bytes if they exist.
Future<Uint8List?> loadCachedImageBytes(String key) async {
  final filePath = await _getCacheFilePath(key);
  final file = File(filePath);
  if (await file.exists()) {
    return file.readAsBytes();
  }
  return null;
}

/// Caches the given image bytes using the provided key.
Future<void> cacheImageBytes(String key, Uint8List bytes) async {
  final filePath = await _getCacheFilePath(key);
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
}
