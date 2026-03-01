import 'package:flutter/material.dart';
import '../../../models/media_item.dart';
import 'photo_display.dart';
import 'video_display.dart';

class DualLandscapeDisplay extends StatelessWidget {
  final MediaItem primary;
  final MediaItem companion;

  const DualLandscapeDisplay({
    super.key,
    required this.primary,
    required this.companion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(child: _buildMedia(primary)),
          Expanded(child: _buildMedia(companion)),
        ],
      ),
    );
  }

  Widget _buildMedia(MediaItem item) {
    return switch (item.type) {
      MediaType.image => PhotoDisplay(
          key: ValueKey(item.remotePath),
          filePath: item.localCachePath!,
        ),
      MediaType.video => VideoDisplay(
          key: ValueKey(item.remotePath),
          filePath: item.localCachePath!,
        ),
    };
  }
}
