// profile_picture.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:student_app/utils/cache_helper.dart'; // Contains loadCachedImageBytes and cacheImageBytes

// Function to download image bytes from a URL.
Future<Uint8List?> downloadImageBytes(String photoURL) async {
  try {
    final response = await http.get(Uri.parse(photoURL));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (e) {
    debugPrint('Error downloading image: $e');
  }
  return null;
}

// CachedProfileImage widget displays an image using a URL, falling back to initials if necessary.
class CachedProfileImage extends StatefulWidget {
  final String? photoURL;
  final double size;
  final String? fallbackText;
  final Color? fallbackBackgroundColor;

  const CachedProfileImage({
    super.key,
    required this.photoURL,
    this.size = 64,
    this.fallbackText,
    this.fallbackBackgroundColor,
  });

  @override
  CachedProfileImageState createState() => CachedProfileImageState();
}

class CachedProfileImageState extends State<CachedProfileImage> {
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.photoURL != null && widget.photoURL!.isNotEmpty) {
      _imageFuture = _getProfileImage(widget.photoURL!);
    }
  }

  // Retrieves the profile image bytes from cache or downloads and caches it.
  Future<Uint8List?> _getProfileImage(String photoURL) async {
    final key = 'circle_${photoURL.hashCode}_${widget.size}';
    // Try to load from cache
    Uint8List? bytes = await loadCachedImageBytes(key);
    if (bytes != null) {
      return bytes;
    }
    // If not in cache, download the image
    bytes = await downloadImageBytes(photoURL);
    if (bytes != null) {
      await cacheImageBytes(key, bytes);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    // If no valid photoURL, display fallback avatar with initials.
    if (widget.photoURL == null || widget.photoURL!.isEmpty) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
        child: widget.fallbackText != null
            ? Text(
                widget.fallbackText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size / 2.5,
                ),
              )
            : null,
      );
    }
    // Use a FutureBuilder to handle asynchronous image fetching.
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        }
        // In case of error or no data, show the fallback.
        return CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
          child: widget.fallbackText != null
              ? Text(
                  widget.fallbackText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size / 2.5,
                  ),
                )
              : null,
        );
      },
    );
  }
}
