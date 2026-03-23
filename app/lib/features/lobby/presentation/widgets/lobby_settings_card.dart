import 'package:flutter/material.dart';

import '../../../meeting/data/models/meeting_access.dart';

class LobbySettingsCard extends StatelessWidget {
  const LobbySettingsCard({
    required this.access,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.errorMessage,
    this.compact = false,
    required this.onToggleMicrophone,
    required this.onToggleCamera,
    required this.onJoin,
    super.key,
  });

  final MeetingAccess access;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final String? errorMessage;
  final bool compact;
  final VoidCallback onToggleMicrophone;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final headingStyle = compact
        ? Theme.of(context).textTheme.headlineLarge
        : Theme.of(context).textTheme.headlineMedium;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              access.roomCode,
              style: headingStyle?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              'Joining as ${access.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 14 : 16,
              ),
            ),
            SizedBox(height: compact ? 16 : 24),
            SwitchListTile.adaptive(
              value: microphoneEnabled,
              onChanged: (_) => onToggleMicrophone(),
              title: const Text('Microphone'),
              subtitle: Text(microphoneEnabled ? 'Start unmuted' : 'Start muted'),
              contentPadding: EdgeInsets.zero,
              dense: compact,
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            ),
            SwitchListTile.adaptive(
              value: cameraEnabled,
              onChanged: onToggleCamera == null ? null : (_) => onToggleCamera!(),
              title: const Text('Camera'),
              subtitle: Text(cameraEnabled ? 'Join with video' : 'Join audio-only'),
              contentPadding: EdgeInsets.zero,
              dense: compact,
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            ),
            if (errorMessage != null) ...[
              SizedBox(height: compact ? 12 : 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 14 : 16),
                decoration: BoxDecoration(
                  color: const Color(0x33F87171),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(errorMessage!),
              ),
            ],
            SizedBox(height: compact ? 16 : 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onJoin,
                child: const Text('Join Meeting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
