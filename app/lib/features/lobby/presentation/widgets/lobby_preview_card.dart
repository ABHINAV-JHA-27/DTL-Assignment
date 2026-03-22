import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class LobbyPreviewCard extends StatelessWidget {
  const LobbyPreviewCard({
    required this.track,
    required this.isBusy,
    required this.cameraEnabled,
    super.key,
  });

  final lk.LocalVideoTrack? track;
  final bool isBusy;
  final bool cameraEnabled;

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
                  ? const _PreviewPlaceholder()
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
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, size: 72, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Camera preview is off',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Turn the camera back on to check framing before joining the room.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
