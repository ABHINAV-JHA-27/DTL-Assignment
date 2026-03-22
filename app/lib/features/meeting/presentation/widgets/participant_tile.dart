import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    required this.participant,
    required this.isLocal,
    super.key,
  });

  final lk.Participant participant;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: participant,
      builder: (context, _) {
        final publication = participant.getTrackPublicationBySource(
              lk.TrackSource.camera,
            ) ??
            participant.getTrackPublicationBySource(
              lk.TrackSource.screenShareVideo,
            );
        final track = publication?.track;
        final participantName = participant.name.trim();
        final name =
            participantName.isNotEmpty ? participantName : participant.identity;
        final videoTrack = track is lk.VideoTrack ? track : null;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF102033), Color(0xFF07111B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (videoTrack != null && !(publication?.muted ?? true))
                  lk.VideoTrackRenderer(
                    videoTrack,
                    fit: lk.VideoViewFit.cover,
                    mirrorMode: isLocal
                        ? lk.VideoViewMirrorMode.mirror
                        : lk.VideoViewMirrorMode.off,
                  )
                else
                  _ParticipantPlaceholder(name: name),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isLocal ? '$name (You)' : name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                participant.isSpeaking
                                    ? Icons.graphic_eq_rounded
                                    : Icons.person_rounded,
                                size: 18,
                                color: participant.isSpeaking
                                    ? const Color(0xFF5EEAD4)
                                    : Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParticipantPlaceholder extends StatelessWidget {
  const _ParticipantPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF17324B),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
