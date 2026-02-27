import 'dart:io';
import 'package:flutter/material.dart';

class PhotoDisplay extends StatelessWidget {
  final String filePath;

  const PhotoDisplay({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Image.file(
          File(filePath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load image\n$filePath\n$error',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
