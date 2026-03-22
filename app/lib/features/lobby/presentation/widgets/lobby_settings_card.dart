import 'package:flutter/material.dart';

import '../../../meeting/data/models/meeting_access.dart';

class LobbySettingsCard extends StatelessWidget {
  const LobbySettingsCard({
    required this.access,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.errorMessage,
    required this.onToggleMicrophone,
    required this.onToggleCamera,
    required this.onJoin,
    super.key,
  });

  final MeetingAccess access;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final String? errorMessage;
  final VoidCallback onToggleMicrophone;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              access.roomCode,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Joining as ${access.username}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SwitchListTile.adaptive(
              value: microphoneEnabled,
              onChanged: (_) => onToggleMicrophone(),
              title: const Text('Microphone'),
              subtitle: Text(microphoneEnabled ? 'Start unmuted' : 'Start muted'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              value: cameraEnabled,
              onChanged: onToggleCamera == null ? null : (_) => onToggleCamera!(),
              title: const Text('Camera'),
              subtitle: Text(cameraEnabled ? 'Join with video' : 'Join audio-only'),
              contentPadding: EdgeInsets.zero,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x33F87171),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(errorMessage!),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: onJoin,
              child: const Text('Join Meeting'),
            ),
          ],
        ),
      ),
    );
  }
}
