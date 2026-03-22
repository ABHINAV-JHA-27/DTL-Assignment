import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/permission_service.dart';
import '../../../meeting/data/models/meeting_access.dart';
import '../../../meeting/data/services/livekit_service.dart';
import '../../../meeting/data/services/meeting_api_service.dart';
import '../../../meeting/presentation/cubit/meeting_cubit.dart';
import '../../../meeting/presentation/pages/meeting_room_page.dart';

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
  LocalVideoTrack? _previewTrack;
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

    final track = await LocalVideoTrack.createCameraTrack();
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
                  child: _PreviewCard(
                    track: _previewTrack,
                    isBusy: _busy,
                    cameraEnabled: _cameraEnabled,
                  ),
                ),
                SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 20),
                Expanded(
                  flex: 2,
                  child: _LobbySettings(
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.track,
    required this.isBusy,
    required this.cameraEnabled,
  });

  final LocalVideoTrack? track;
  final bool isBusy;
  final bool cameraEnabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040B14), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: isBusy
              ? const CircularProgressIndicator()
              : !cameraEnabled || track == null
                  ? const _PreviewPlaceholder()
                  : VideoTrackRenderer(
                      track!,
                      fit: VideoViewFit.cover,
                      mirrorMode: VideoViewMirrorMode.mirror,
                    ),
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, size: 72, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Camera preview is off',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Turn the camera back on to check framing before joining the room.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LobbySettings extends StatelessWidget {
  const _LobbySettings({
    required this.access,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.errorMessage,
    required this.onToggleMicrophone,
    required this.onToggleCamera,
    required this.onJoin,
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
