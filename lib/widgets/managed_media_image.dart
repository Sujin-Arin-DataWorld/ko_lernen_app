import 'dart:io';

import 'package:flutter/material.dart';

import '../services/word_image_service.dart';

class ManagedMediaImage extends StatelessWidget {
  const ManagedMediaImage({
    super.key,
    required this.reference,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String reference;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: WordImageService.resolve(reference),
      builder: (context, snapshot) {
        final file = snapshot.data;
        final child = file == null
            ? SizedBox(
                width: width,
                height: height,
                child: const Icon(Icons.image_not_supported_outlined),
              )
            : Image.file(
                file,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: width,
                  height: height,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              );
        return borderRadius == null
            ? child
            : ClipRRect(borderRadius: borderRadius!, child: child);
      },
    );
  }
}
