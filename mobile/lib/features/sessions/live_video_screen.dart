import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_controller.dart';
import '../../state/app_state.dart';
import 'call_widgets.dart';

class LiveVideoScreen extends StatefulWidget {
  final Session session;

  const LiveVideoScreen({super.key, required this.session});

  @override
  State<LiveVideoScreen> createState() => _LiveVideoScreenState();
}

class _LiveVideoScreenState extends State<LiveVideoScreen> {
  bool _micOn = true;
  bool _camOn = true;
  bool _connecting = true;
  int _seconds = 0;
  Timer? _timer;
  Offset _pip = const Offset(16, 90);
  final List<CallMessage> _messages = [];
  late final SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController(ApiClient())..addListener(_onSessionChanged);
    _join();
  }

  Future<void> _join() async {
    await _sessionController.joinSession(widget.session.id);
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final connected = _sessionController.state == SessionConnectionState.connected;
    setState(() {
      _connecting = !connected;
      _micOn = _sessionController.microphoneEnabled;
      _camOn = _sessionController.cameraEnabled;
    });
    if (connected && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionController.removeListener(_onSessionChanged);
    _sessionController.leaveSession();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _end() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text('You can rejoin while the session is still running.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _timer?.cancel();
    await _sessionController.leaveSession();
    if (!mounted) return;
    await showSessionFeedback(context, widget.session.tutorName);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).name;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _end();
      },
      child: Scaffold(
        backgroundColor: AppColors.callBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Remote participant (full screen)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 70, 12, 120),
                  child: _connecting
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text('Connectingâ€¦', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : _remoteVideo(),
                ),
              ),
              // Top bar
              Positioned(
                left: 16,
                right: 16,
                top: 12,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _end,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                          Text('1:1 with ${widget.session.tutorName}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(Fmt.duration(_seconds),
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Self view (draggable picture-in-picture)
              if (!_connecting && _sessionController.engine != null)
                Positioned(
                  right: _pip.dx,
                  top: _pip.dy,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _pip = Offset(
                        (_pip.dx - d.delta.dx).clamp(8, size.width - 120),
                        (_pip.dy + d.delta.dy).clamp(70, size.height - 330),
                      );
                    }),
                    child: SizedBox(
                      width: 104,
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _sessionController.engine!,
                            canvas: const VideoCanvas(uid: 0),
                            useFlutterTexture: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallControl(
                      icon: _micOn ? Icons.mic : Icons.mic_off,
                      label: _micOn ? 'Mute' : 'Unmute',
                      active: _micOn,
                      onTap: () => _sessionController.toggleMicrophone(),
                    ),
                    CallControl(
                      icon: _camOn ? Icons.videocam : Icons.videocam_off,
                      label: 'Camera',
                      active: _camOn,
                      onTap: () => _sessionController.toggleCamera(),
                    ),
                    CallControl(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      onTap: () async {
                        await showInCallChat(context, _messages, me);
                        if (mounted) setState(() {});
                      },
                    ),
                    CallControl(
                      icon: Icons.call_end,
                      label: 'End',
                      color: AppColors.error,
                      onTap: _end,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    final engine = _sessionController.engine;
    final remoteUid = _sessionController.remoteUid;
    if (engine == null) {
      return _connectionMessage();
    }
    if (remoteUid == null) {
      return const Center(
        child: Text('Waiting for the other participantâ€¦',
            style: TextStyle(color: Colors.white70)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: remoteUid),
          connection: RtcConnection(channelId: _sessionController.channelName!),
        ),
      ),
    );
  }

  Widget _connectionMessage() {
    final message = _sessionController.errorMessage;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message == null) const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(message ?? 'Connectingâ€¦', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
