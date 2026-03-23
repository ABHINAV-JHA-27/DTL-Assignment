import 'package:flutter/material.dart';

import '../cubit/home_cubit.dart';

class HomeLaunchCard extends StatelessWidget {
  const HomeLaunchCard({
    required this.state,
    required this.onNameChanged,
    required this.onMeetingCodeChanged,
    required this.onCreateMeeting,
    required this.onJoinMeeting,
    super.key,
  });

  final HomeState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onMeetingCodeChanged;
  final VoidCallback onCreateMeeting;
  final VoidCallback onJoinMeeting;

  @override
  Widget build(BuildContext context) {
    final busy = state.status == HomeStatus.submitting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start or join a meeting',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the existing Next.js backend for participant token generation and meeting validation.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: onNameChanged,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Add your display name',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : onCreateMeeting,
                child: busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Meeting'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.12)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR'),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: onMeetingCodeChanged,
              enabled: !busy,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Meeting Code',
                hintText: 'Enter 9-character code',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onJoinMeeting,
                child: const Text('Join Meeting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
