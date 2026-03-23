import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

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
  bool _cameraEnabled = false;
  bool _busy = false;
  String? _cameraPreviewMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposePreview();
    super.dispose();
  }

  Future<void> _preparePreview() async {
    setState(() {
      _busy = true;
      _cameraPreviewMessage = null;
    });

    if (!_cameraEnabled) {
      await _disposePreview();
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
      return;
    }

    try {
      final permissionResult =
          await context.read<PermissionService>().requestMediaPermissions(
            microphoneEnabled: false,
            cameraEnabled: true,
          );

      if (!permissionResult.cameraGranted) {
        throw Exception('camera-not-granted');
      }
      await _restartPreview();
    } on Object catch (error) {
      setState(() {
        _cameraEnabled = false;
        _cameraPreviewMessage =
            error.toString().contains('camera-not-granted')
                ? 'Camera permission denied. You can still join with audio-only.'
                : 'Camera preview is unavailable on this device or simulator. You can still join with audio.';
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
    if (_cameraEnabled) {
      await _disposePreview();
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraEnabled = false;
        _cameraPreviewMessage = null;
        _busy = false;
      });
      return;
    }

    setState(() {
      _cameraEnabled = true;
      _busy = true;
      _cameraPreviewMessage = null;
    });

    try {
      await _preparePreview();
    } on Object {
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

    if (mounted && _cameraEnabled) {
      await _preparePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compact = viewportHeight < 780;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Join Lobby')),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1080,
                  minHeight: viewportConstraints.maxHeight - 40,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 860;

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: compact ? 500 : 560,
                              child: LobbyPreviewCard(
                                track: _previewTrack,
                                isBusy: _busy,
                                cameraEnabled: _cameraEnabled,
                                compact: compact,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: LobbySettingsCard(
                              access: widget.access,
                              microphoneEnabled: _microphoneEnabled,
                              cameraEnabled: _cameraEnabled,
                              errorMessage: _cameraPreviewMessage,
                              compact: compact,
                              onToggleMicrophone: () {
                                setState(() {
                                  _microphoneEnabled = !_microphoneEnabled;
                                });
                              },
                              onToggleCamera: _busy ? null : _handleToggleCamera,
                              onJoin: _busy ? null : _handleJoin,
                            ),
                          ),
                        ],
                      );
                    }

                    final previewHeight = compact
                        ? (constraints.maxWidth * 0.72).clamp(220.0, 300.0)
                        : (constraints.maxWidth * 0.9).clamp(280.0, 380.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: previewHeight,
                          child: LobbyPreviewCard(
                            track: _previewTrack,
                            isBusy: _busy,
                            cameraEnabled: _cameraEnabled,
                            compact: compact,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        LobbySettingsCard(
                          access: widget.access,
                          microphoneEnabled: _microphoneEnabled,
                          cameraEnabled: _cameraEnabled,
                          errorMessage: _cameraPreviewMessage,
                          compact: compact,
                          onToggleMicrophone: () {
                            setState(() {
                              _microphoneEnabled = !_microphoneEnabled;
                            });
                          },
                          onToggleCamera: _busy ? null : _handleToggleCamera,
                          onJoin: _busy ? null : _handleJoin,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
