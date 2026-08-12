import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthenticatedAvatarImage extends StatefulWidget {
  final String imageUrl;
  final String token;
  final Widget fallback;
  final BoxFit fit;

  const AuthenticatedAvatarImage({
    super.key,
    required this.imageUrl,
    required this.token,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthenticatedAvatarImage> createState() =>
      _AuthenticatedAvatarImageState();
}

class _AuthenticatedAvatarImageState extends State<AuthenticatedAvatarImage> {
  Uint8List? _bytes;
  String? _loadedUrl;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.token != widget.token) {
      _bytes = null;
      _loadedUrl = null;
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.fallback;
    return Image.memory(bytes, fit: widget.fit);
  }

  Future<void> _loadImage() async {
    final imageUrl = widget.imageUrl.trim();
    final token = widget.token.trim();
    if (imageUrl.isEmpty || token.isEmpty) return;

    final loadVersion = ++_loadVersion;
    try {
      final response = await http
          .get(
            Uri.parse(imageUrl),
            headers: {'Accept': 'image/*', 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted ||
          loadVersion != _loadVersion ||
          widget.imageUrl.trim() != imageUrl ||
          widget.token.trim() != token ||
          _loadedUrl == imageUrl) {
        return;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _bytes = response.bodyBytes;
          _loadedUrl = imageUrl;
        });
      }
    } catch (_) {
      // Keep the fallback avatar if the image endpoint is unavailable.
    }
  }
}
