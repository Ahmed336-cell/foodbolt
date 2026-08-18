import 'dart:io';

import 'package:flutter/material.dart';

/// Shows the receipt photo for everyone: local file on the uploader,
/// signed URL for other members.
class ReceiptPhoto extends StatelessWidget {
  const ReceiptPhoto({
    super.key,
    this.localPath,
    this.imageUrl,
    this.height,
    this.empty,
  });

  final String? localPath;
  final String? imageUrl;
  final double? height;
  final Widget? empty;

  bool get hasImage {
    final url = imageUrl;
    if (url != null && url.startsWith('http')) return true;
    final path = localPath;
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('http')) return true;
    return path.startsWith('/') || path.startsWith('file:');
  }

  @override
  Widget build(BuildContext context) {
    if (!hasImage) {
      return empty ?? const SizedBox.shrink();
    }

    Widget image = _image();
    image = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: image,
    );

    if (height != null) {
      image = SizedBox(
        height: height,
        width: double.infinity,
        child: image,
      );
    } else {
      image = SizedBox.expand(child: image);
    }

    return GestureDetector(
      onTap: () => _openFull(context),
      child: image,
    );
  }

  Widget _image({BoxFit fit = BoxFit.contain}) {
    final path = localPath;
    if (path != null &&
        path.isNotEmpty &&
        !path.startsWith('http') &&
        (path.startsWith('/') || path.startsWith('file:'))) {
      return Image.file(
        File(path.startsWith('file:') ? Uri.parse(path).toFilePath() : path),
        fit: fit,
        errorBuilder: (_, _, _) => _network(fit) ?? const SizedBox.shrink(),
      );
    }
    return _network(fit) ?? const SizedBox.shrink();
  }

  Widget? _network(BoxFit fit) {
    final url = imageUrl;
    if (url == null || !url.startsWith('http')) return null;
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: _image(fit: BoxFit.contain),
        ),
      ),
    );
  }
}
