import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../lobby/presentation/pages/pre_join_lobby_screen.dart';
import '../cubit/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.pendingAccess != current.pendingAccess &&
          current.pendingAccess != null,
      listener: (context, state) async {
        final access = state.pendingAccess!;
        context.read<HomeCubit>().clearNavigation();

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PreJoinLobbyScreen(access: access),
          ),
        );
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF030712),
              Color(0xFF08111F),
              Color(0xFF0B1F33),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 820;

                    return Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: wide ? 28 : 0,
                              bottom: wide ? 0 : 24,
                            ),
                            child: _HeroPanel(theme: theme),
                          ),
                        ),
                        const Expanded(child: _LaunchCard()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              color: Colors.white.withOpacity(0.08),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(label),
    );
  }
}

class _LaunchCard extends StatelessWidget {
  const _LaunchCard();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.status == HomeStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();
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
                  onChanged: cubit.updateName,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Add your display name',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: busy ? null : cubit.createMeeting,
                  child: busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Meeting'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.12)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR'),
                    ),
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.12)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: cubit.updateMeetingCode,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Code',
                    hintText: 'Enter 9-character code',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: busy ? null : cubit.joinMeeting,
                  child: const Text('Join Meeting'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
