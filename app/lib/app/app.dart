import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/services/permission_service.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/pages/home_screen.dart';
import '../features/meeting/data/services/livekit_service.dart';
import '../features/meeting/data/services/meeting_api_service.dart';
import 'theme/app_theme.dart';

class MeetSpaceApp extends StatelessWidget {
  const MeetSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => MeetingApiService()),
        RepositoryProvider(create: (_) => LiveKitService()),
        RepositoryProvider(create: (_) => PermissionService()),
      ],
      child: BlocProvider(
        create: (context) => HomeCubit(
          apiService: context.read<MeetingApiService>(),
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MeetSpace',
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
