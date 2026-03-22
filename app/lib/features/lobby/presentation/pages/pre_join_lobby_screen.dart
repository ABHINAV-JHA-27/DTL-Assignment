import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/permission_service.dart';
import '../../../meeting/data/models/meeting_access.dart';
import '../../../meeting/data/services/livekit_service.dart';
import '../../../meeting/data/services/meeting_api_service.dart';
import '../../../meeting/presentation/cubit/meeting_cubit.dart';
import '../../../meeting/presentation/pages/meeting_room_page.dart';
import '../widgets/lobby_preview_card.dart';
import '../widgets/lobby_settings_card.dart';

class PreJoinLobbyScreen extends StatefulWidget {
  const PreJoinLobbyScreen({
    required this.access,
    super.key,
  });

  final MeetingAccess access;

  @override
  State<PreJoinLobbyScreen> createState() => _PreJoinLobbyScreenState();
}

class _PreJoinLobbyScreenState extends State<PreJoinLobbyScreen> {
  lk.LocalVideoTrack? _previewTrack;
  bool _microphoneEnabled = true;
  bool _cameraEnabled = true;
  bool _busy = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _preparePreview();
  }

  @override
  void dispose() {
    _disposePreview();
    super.dispose();
  }

  Future<void> _preparePreview() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await context.read<PermissionService>().ensureMediaPermissions();
      await _restartPreview();
    } on AppException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _restartPreview() async {
    await _disposePreview();

    if (!_cameraEnabled) {
      return;
    }

    final track = await lk.LocalVideoTrack.createCameraTrack();
    if (!mounted) {
      await track.dispose();
      return;
    }

    setState(() {
      _previewTrack = track;
    });
  }

  Future<void> _disposePreview() async {
    final previewTrack = _previewTrack;
    _previewTrack = null;
    await previewTrack?.dispose();
  }

  Future<void> _handleToggleCamera() async {
    setState(() {
      _cameraEnabled = !_cameraEnabled;
      _busy = true;
    });

    try {
      await _restartPreview();
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to start the camera preview.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleJoin() async {
    await _disposePreview();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (_) => MeetingCubit(
            apiService: context.read<MeetingApiService>(),
            liveKitService: context.read<LiveKitService>(),
            permissionService: context.read<PermissionService>(),
          )..connect(
              access: widget.access,
              microphoneEnabled: _microphoneEnabled,
              cameraEnabled: _cameraEnabled,
            ),
          child: MeetingRoomPage(roomCode: widget.access.roomCode),
        ),
      ),
    );

    if (mounted) {
      await _preparePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Join Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;

            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: LobbyPreviewCard(
                    track: _previewTrack,
                    isBusy: _busy,
                    cameraEnabled: _cameraEnabled,
                  ),
                ),
                SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 20),
                Expanded(
                  flex: 2,
                  child: LobbySettingsCard(
                    access: widget.access,
                    microphoneEnabled: _microphoneEnabled,
                    cameraEnabled: _cameraEnabled,
                    errorMessage: _errorMessage,
                    onToggleMicrophone: () {
                      setState(() {
                        _microphoneEnabled = !_microphoneEnabled;
                      });
                    },
                    onToggleCamera: _busy ? null : _handleToggleCamera,
                    onJoin: _busy || _errorMessage != null ? null : _handleJoin,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
