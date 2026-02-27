import 'package:flutter/material.dart';

class MediaControlsOverlay extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Widget child;

  const MediaControlsOverlay({
    super.key,
    required this.onNext,
    required this.onPrevious,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Left half - previous
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.3,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onPrevious,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Right half - next
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.3,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onNext,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
