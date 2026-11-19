import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';

enum SessionConnectionState {
  idle,
  joining,
  connected,
  leaving,
  disconnected,
  error,
}

class SessionController extends ChangeNotifier {
  SessionController(this._api, {String appId = ApiConfig.agoraAppId})
      : _appId = appId;

  final ApiClient _api;
  final String _appId;
  RtcEngine? engine;
  int? remoteUid;
  bool reconnecting = false;
  SessionConnectionState state = SessionConnectionState.idle;
  String? sessionId;
  String? channelName;
  String? rtcToken;
  String? uid;
  DateTime? tokenExpiresAt;
  String? errorMessage;
  bool microphoneEnabled = true;
  bool cameraEnabled = true;

  Future<void> joinSession(String id) async {
    state = SessionConnectionState.joining;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.postSession('/sessions/$id/video-token');
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      sessionId = id;
      channelName = data['channel_name']?.toString();
      rtcToken = data['token']?.toString();
      uid = data['uid']?.toString();
      final expires = data['expires_at'];
      tokenExpiresAt = expires is num
          ? DateTime.fromMillisecondsSinceEpoch(expires.toInt() * 1000)
          : null;
      final channel = channelName;
      final token = rtcToken;
      final localUid = int.tryParse(uid ?? '');
      if (_appId.isEmpty || channel == null || token == null || localUid == null) {
        throw const ApiException(500, 'Video configuration was incomplete');
      }
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      if (!permissions.values.every((status) => status.isGranted)) {
        throw const ApiException(403, 'Camera and microphone permissions are required');
      }
      await _initializeEngine();
      await engine!.joinChannel(
        token: token,
        channelId: channel,
        uid: localUid,
        options: const ChannelMediaOptions(),
      );
      // The connected state is set by onJoinChannelSuccess, not by token retrieval.
    } on ApiException catch (error) {
      errorMessage = error.message;
      state = SessionConnectionState.error;
    } catch (error) {
      errorMessage = 'Unable to join video session: $error';
      state = SessionConnectionState.error;
    }
    notifyListeners();
  }

  Future<void> leaveSession() async {
    if (sessionId == null && engine == null) return;
    state = SessionConnectionState.leaving;
    notifyListeners();
    try {
      await engine?.leaveChannel();
      await engine?.release();
      engine = null;
      if (sessionId != null) {
        await _api.postSession('/sessions/$sessionId/leave');
      }
      state = SessionConnectionState.disconnected;
      sessionId = null;
      channelName = null;
      rtcToken = null;
      uid = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
      state = SessionConnectionState.error;
    }
    notifyListeners();
  }

  void toggleCamera() {
    cameraEnabled = !cameraEnabled;
    engine?.muteLocalVideoStream(!cameraEnabled);
    notifyListeners();
  }

  void toggleMicrophone() {
    microphoneEnabled = !microphoneEnabled;
    engine?.muteLocalAudioStream(!microphoneEnabled);
    notifyListeners();
  }

  Future<void> _initializeEngine() async {
    if (engine != null) return;
    final rtcEngine = createAgoraRtcEngine();
    await rtcEngine.initialize(RtcEngineContext(appId: _appId));
    rtcEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (_, __) {
        state = SessionConnectionState.connected;
        reconnecting = false;
        notifyListeners();
      },
      onUserJoined: (_, id, __) {
        remoteUid = id;
        notifyListeners();
      },
      onUserOffline: (_, id, __) {
        if (remoteUid == id) remoteUid = null;
        notifyListeners();
      },
      onTokenPrivilegeWillExpire: (_, __) => _renewToken(),
      onConnectionStateChanged: (_, connectionState, __) {
        reconnecting = connectionState == ConnectionStateType.connectionStateReconnecting;
        if (connectionState == ConnectionStateType.connectionStateFailed) {
          errorMessage = 'Video connection failed';
          state = SessionConnectionState.error;
        }
        notifyListeners();
      },
      onError: (code, message) {
        errorMessage = 'Agora error $code: $message';
        state = SessionConnectionState.error;
        notifyListeners();
      },
    ));
    await rtcEngine.enableVideo();
    await rtcEngine.startPreview();
    engine = rtcEngine;
  }

  Future<void> _renewToken() async {
    final id = sessionId;
    if (id == null || engine == null) return;
    try {
      final response = await _api.postSession('/sessions/$id/video-token');
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final token = data['token']?.toString();
      if (token == null) throw const ApiException(500, 'Token renewal response was incomplete');
      rtcToken = token;
      await engine!.renewToken(token);
    } on ApiException catch (error) {
      errorMessage = error.message;
      state = SessionConnectionState.error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    engine?.release();
    super.dispose();
  }
}
