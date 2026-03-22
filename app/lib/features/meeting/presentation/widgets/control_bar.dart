import 'package:flutter/material.dart';

class MeetingControlBar extends StatelessWidget {
  const MeetingControlBar({
    required this.isMicrophoneEnabled,
    required this.isCameraEnabled,
    required this.onToggleMicrophone,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onOpenChat,
    required this.onDisconnect,
    super.key,
  });

  final bool isMicrophoneEnabled;
  final bool isCameraEnabled;
  final Future<void> Function() onToggleMicrophone;
  final Future<void> Function() onToggleCamera;
  final Future<void> Function() onSwitchCamera;
  final VoidCallback onOpenChat;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xCC07111B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionButton(
              icon: isMicrophoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: isMicrophoneEnabled ? 'Mute' : 'Unmute',
              onPressed: () => onToggleMicrophone(),
            ),
            _ActionButton(
              icon: isCameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: isCameraEnabled ? 'Stop Video' : 'Start Video',
              onPressed: () => onToggleCamera(),
            ),
            _ActionButton(
              icon: Icons.flip_camera_android_rounded,
              label: 'Switch Camera',
              onPressed: () => onSwitchCamera(),
            ),
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onPressed: onOpenChat,
            ),
            _ActionButton(
              icon: Icons.call_end_rounded,
              label: 'End Call',
              onPressed: () => onDisconnect(),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        backgroundColor: isDanger
            ? const Color(0x33F87171)
            : Colors.white.withValues(alpha: 0.08),
        foregroundColor: isDanger ? const Color(0xFFFDA4AF) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
