import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../lobby/presentation/pages/pre_join_lobby_screen.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_hero_panel.dart';
import '../widgets/home_launch_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.pendingAccess != current.pendingAccess ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) async {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
        }

        final access = state.pendingAccess;
        if (access == null) {
          return;
        }

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
                            child: const HomeHeroPanel(),
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

class _LaunchCard extends StatelessWidget {
  const _LaunchCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();
        return HomeLaunchCard(
          state: state,
          onNameChanged: cubit.updateName,
          onMeetingCodeChanged: cubit.updateMeetingCode,
          onCreateMeeting: cubit.createMeeting,
          onJoinMeeting: cubit.joinMeeting,
        );
      },
    );
  }
}
