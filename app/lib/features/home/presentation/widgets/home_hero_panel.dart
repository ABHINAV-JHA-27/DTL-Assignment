import 'package:flutter/material.dart';

class HomeHeroPanel extends StatelessWidget {
  const HomeHeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          colors: [
            Color(0x2214B8A6),
            Color(0x221D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text('LiveKit + Flutter'),
          ),
          const SizedBox(height: 24),
          Text(
            'Launch secure video rooms with a mobile-first meeting flow.',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Create a meeting code, validate join requests through your Next.js backend, preview devices in the lobby, and enter a responsive LiveKit room shell.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _Badge(label: 'Dark meeting UI'),
              _Badge(label: 'Runtime permissions'),
              _Badge(label: 'In-room chat'),
              _Badge(label: 'Responsive participant grid'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(label),
    );
  }
}
