import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class LobbyPreviewCard extends StatelessWidget {
  const LobbyPreviewCard({
    required this.track,
    required this.isBusy,
    required this.cameraEnabled,
    this.compact = false,
    super.key,
  });

  final lk.LocalVideoTrack? track;
  final bool isBusy;
  final bool cameraEnabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040B14), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: isBusy
              ? const CircularProgressIndicator()
              : !cameraEnabled || track == null
                  ? _PreviewPlaceholder(compact: compact)
                  : lk.VideoTrackRenderer(
                      track!,
                      fit: lk.VideoViewFit.cover,
                      mirrorMode: lk.VideoViewMirrorMode.mirror,
                    ),
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? 20 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: compact ? 56 : 72,
            color: Colors.white54,
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            'Camera preview is off',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Turn the camera back on to check framing before joining the room.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: compact ? 15 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
