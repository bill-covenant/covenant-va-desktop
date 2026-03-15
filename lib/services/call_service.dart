import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'socket_service.dart';
import 'tone_service.dart';
import '../core/constants/api_constants.dart';

enum CallState { idle, calling, ringing, connected }

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SocketService _socket = SocketService();
  final http.Client _httpClient = http.Client();
  final ToneService _toneService = ToneService();

  // Auth token for HTTP polling
  String? _authToken;

  // State
  CallState _callState = CallState.idle;
  String _callType = 'video';
  String? _remoteUserId;
  String? _remoteUserName;
  bool _isCaller = false; // true if VA initiated the call
  bool _isMuted = false;
  bool _isCameraOff = false;
  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _pollTimer;
  Timer? _signalPollTimer;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isNegotiating = false; // Guard against duplicate offer/answer
  bool _showDeviceSelector = false;
  int _remoteStreamKey = 0; // Incremented when remote stream changes, used as widget key
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Global key for showing dialogs from anywhere
  GlobalKey<NavigatorState>? navigatorKey;

  // Device management
  List<MediaDeviceInfo> _audioInputs = [];
  List<MediaDeviceInfo> _audioOutputs = [];
  List<MediaDeviceInfo> _videoInputs = [];
  String? _selectedAudioInput;
  String? _selectedAudioOutput;
  String? _selectedVideoInput;

  // Getters
  CallState get callState => _callState;
  String get callType => _callType;
  String? get remoteUserId => _remoteUserId;
  String? get remoteUserName => _remoteUserName;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  int get callDuration => _callDuration;
  bool get hasLocalVideo => _localStream?.getVideoTracks().isNotEmpty == true;
  int get remoteStreamKey => _remoteStreamKey;
  List<MediaDeviceInfo> get audioInputs => _audioInputs;
  List<MediaDeviceInfo> get audioOutputs => _audioOutputs;
  List<MediaDeviceInfo> get videoInputs => _videoInputs;
  String? get selectedAudioInput => _selectedAudioInput;
  String? get selectedAudioOutput => _selectedAudioOutput;
  String? get selectedVideoInput => _selectedVideoInput;
  bool get showDeviceSelector => _showDeviceSelector;

  void toggleDeviceSelector() {
    _showDeviceSelector = !_showDeviceSelector;
    if (_showDeviceSelector) refreshDevices();
    notifyListeners();
  }

  void hideDeviceSelector() {
    _showDeviceSelector = false;
    notifyListeners();
  }
  String get formattedDuration {
    final mins = _callDuration ~/ 60;
    final secs = _callDuration % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void setAuthToken(String token) {
    _authToken = token;
    print('📞 CallService: Auth token set');
  }

  Future<void> initialize() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e) {
      print('⚠️ Failed to initialize video renderers: $e');
    }
    _setupSocketListeners();
    _startCallPolling();
    await refreshDevices();
    print('📞 CallService initialized with HTTP polling');
  }

  Future<void> refreshDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
      _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
      _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
      print('📞 Devices: ${_audioInputs.length} mics, ${_audioOutputs.length} speakers, ${_videoInputs.length} cameras');
      notifyListeners();
    } catch (e) {
      print('⚠️ Failed to enumerate devices: $e');
    }
  }

  Future<void> switchAudioInput(String deviceId) async {
    _selectedAudioInput = deviceId;
    if (_localStream != null && _peerConnection != null) {
      try {
        final newStream = await navigator.mediaDevices.getUserMedia({
          'audio': {'deviceId': deviceId},
          'video': false,
        });
        final newTrack = newStream.getAudioTracks()[0];
        final senders = await _peerConnection!.getSenders();
        RTCRtpSender? audioSender;
        for (final s in senders) {
          if (s.track?.kind == 'audio') {
            audioSender = s;
            break;
          }
        }
        if (audioSender != null) {
          final oldTrack = _localStream!.getAudioTracks().isNotEmpty
              ? _localStream!.getAudioTracks()[0]
              : null;
          await audioSender.replaceTrack(newTrack);
          oldTrack?.stop();
          _localStream!.getAudioTracks().forEach((t) => _localStream!.removeTrack(t));
          _localStream!.addTrack(newTrack);
          print('📞 Switched mic to: $deviceId');
        }
      } catch (e) {
        print('❌ Failed to switch mic: $e');
      }
    }
    notifyListeners();
  }

  Future<void> switchAudioOutput(String deviceId) async {
    _selectedAudioOutput = deviceId;
    // flutter_webrtc on desktop: set sink ID on the renderer
    try {
      await remoteRenderer.audioOutput(deviceId);
      print('📞 Switched speaker to: $deviceId');
    } catch (e) {
      print('⚠️ Failed to switch speaker: $e');
    }
    notifyListeners();
  }

  Future<void> switchVideoInput(String deviceId) async {
    _selectedVideoInput = deviceId;
    if (_localStream != null && _peerConnection != null) {
      try {
        final newStream = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': {'deviceId': deviceId, 'width': 1280, 'height': 720},
        });
        final newTrack = newStream.getVideoTracks()[0];
        final senders = await _peerConnection!.getSenders();
        RTCRtpSender? videoSender;
        for (final s in senders) {
          if (s.track?.kind == 'video') {
            videoSender = s;
            break;
          }
        }
        if (videoSender != null) {
          final oldTrack = _localStream!.getVideoTracks().isNotEmpty
              ? _localStream!.getVideoTracks()[0]
              : null;
          await videoSender.replaceTrack(newTrack);
          oldTrack?.stop();
          _localStream!.getVideoTracks().forEach((t) => _localStream!.removeTrack(t));
          _localStream!.addTrack(newTrack);
          localRenderer.srcObject = _localStream;
          print('📞 Switched camera to: $deviceId');
        }
      } catch (e) {
        print('❌ Failed to switch camera: $e');
      }
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════
  // HTTP Polling for incoming calls
  // ═══════════════════════════════════════

  void _startCallPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_authToken == null) return;
      if (_callState == CallState.connected) return;

      try {
        final url = '${ApiConstants.baseUrl}/calls/pending';
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['hasCall'] == true && _callState == CallState.idle) {
            final call = data['call'];
            print('📞 ========== INCOMING CALL (HTTP) ==========');
            print('📞 From: ${call['callerName']} (${call['callerId']})');
            print('📞 Type: ${call['callType']}');

            _remoteUserId = call['callerId'];
            _remoteUserName = call['callerName'];
            _callType = call['callType'] ?? 'audio';
            _isCaller = false;
            _callState = CallState.ringing;
            _toneService.playRingtone();
            notifyListeners();
          }
        }
      } catch (e) {
        // Silently ignore polling errors
      }
    });
  }

  void _startSignalPolling() {
    _signalPollTimer?.cancel();
    _signalPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_authToken == null) return;
      if (_callState == CallState.idle) {
        _signalPollTimer?.cancel();
        return;
      }

      try {
        final url = '${ApiConstants.baseUrl}/calls/signals';
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final signals = data['signals'] as List? ?? [];

          for (final signal in signals) {
            final type = signal['type'];
            final signalData = signal['data'] ?? {};

            print('📨 Signal received (HTTP): $type');

            switch (type) {
              case 'call-accepted':
                if (!_isCaller) {
                  print('📞 Ignoring call-accepted signal (VA is the accepter)');
                  break;
                }
                _toneService.stop();
                _callState = CallState.connected;
                _startDurationTimer();
                notifyListeners();
                await _createAndSendOffer();
                break;
              case 'call-declined':
                _cleanup();
                _callState = CallState.idle;
                notifyListeners();
                break;
              case 'call-ended':
                _cleanup();
                _callState = CallState.idle;
                notifyListeners();
                break;
              case 'webrtc-offer':
                if (signalData['offer'] != null) {
                  await _handleReceiveOffer(Map<String, dynamic>.from(signalData['offer']));
                }
                break;
              case 'webrtc-answer':
                if (signalData['answer'] != null && _peerConnection != null) {
                  final answer = Map<String, dynamic>.from(signalData['answer']);
                  await _peerConnection!.setRemoteDescription(
                    RTCSessionDescription(answer['sdp'], answer['type']),
                  );
                }
                break;
              case 'webrtc-ice-candidate':
                if (signalData['candidate'] != null && _peerConnection != null) {
                  final candidate = Map<String, dynamic>.from(signalData['candidate']);
                  try {
                    await _peerConnection!.addCandidate(
                      RTCIceCandidate(
                        candidate['candidate'],
                        candidate['sdpMid'],
                        candidate['sdpMLineIndex'],
                      ),
                    );
                  } catch (e) {
                    print('Error adding ICE candidate: $e');
                  }
                }
                break;
            }
          }
        }
      } catch (e) {
        // Silently ignore signal polling errors
      }
    });
  }

  // ═══════════════════════════════════════
  // HTTP Call Actions
  // ═══════════════════════════════════════

  Future<void> _httpAcceptCall() async {
    if (_authToken == null) return;
    try {
      final url = '${ApiConstants.baseUrl}/calls/accept';
      await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      print('✅ Call accepted via HTTP');
    } catch (e) {
      print('❌ Error accepting call via HTTP: $e');
    }
  }

  Future<void> _httpDeclineCall() async {
    if (_authToken == null) return;
    try {
      final url = '${ApiConstants.baseUrl}/calls/decline';
      await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      print('❌ Call declined via HTTP');
    } catch (e) {
      print('❌ Error declining call via HTTP: $e');
    }
  }

  Future<void> _httpEndCall(String remoteUserId) async {
    if (_authToken == null) return;
    try {
      final url = '${ApiConstants.baseUrl}/calls/end';
      await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'remoteUserId': remoteUserId}),
      );
      print('📴 Call ended via HTTP');
    } catch (e) {
      print('❌ Error ending call via HTTP: $e');
    }
  }

  Future<void> _httpSendSignal(String remoteUserId, String signalType, Map<String, dynamic> data) async {
    if (_authToken == null) return;
    try {
      final url = '${ApiConstants.baseUrl}/calls/signal';
      await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'remoteUserId': remoteUserId,
          'signalType': signalType,
          'data': data,
        }),
      );
    } catch (e) {
      print('❌ Error sending signal via HTTP: $e');
    }
  }

  // ═══════════════════════════════════════
  // Socket listeners (kept as fallback)
  // ═══════════════════════════════════════

  void _setupSocketListeners() {
    _socket.onIncomingCall = (callerId, callerName, callType) {
      if (_callState != CallState.idle) return;
      _remoteUserId = callerId;
      _remoteUserName = callerName;
      _callType = callType;
      _isCaller = false;
      _callState = CallState.ringing;
      _toneService.playRingtone();
      notifyListeners();
    };

    _socket.onCallAccepted = () async {
      if (!_isCaller) {
        print('📞 Ignoring call-accepted echo (VA is the accepter, not caller)');
        return;
      }
      _toneService.stop();
      _callState = CallState.connected;
      _startDurationTimer();
      notifyListeners();
      await _createAndSendOffer();
    };

    _socket.onCallDeclined = () {
      _cleanup();
      _callState = CallState.idle;
      notifyListeners();
    };

    _socket.onCallEnded = () {
      _cleanup();
      _callState = CallState.idle;
      notifyListeners();
    };

    _socket.onCallUnavailable = (reason) {
      _cleanup();
      _callState = CallState.idle;
      notifyListeners();
    };

    _socket.onWebRTCOffer = (offer) async {
      await _handleReceiveOffer(offer);
    };

    _socket.onWebRTCAnswer = (answer) async {
      if (_peerConnection != null) {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
      }
    };

    _socket.onICECandidate = (candidate) async {
      if (_peerConnection != null) {
        try {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              candidate['candidate'],
              candidate['sdpMid'],
              candidate['sdpMLineIndex'],
            ),
          );
        } catch (e) {
          print('Error adding ICE candidate: $e');
        }
      }
    };
  }

  // ═══════════════════════════════════════
  // Call Actions
  // ═══════════════════════════════════════

  Future<void> startCall(String recipientId, String recipientName, String type) async {
    if (_callState != CallState.idle) return;

    _remoteUserId = recipientId;
    _remoteUserName = recipientName;
    _callType = type;
    _isCaller = true;
    _callState = CallState.calling;
    _isMuted = false;
    _isCameraOff = false;
    _callDuration = 0;
    notifyListeners();

    final vaName = 'VA';
    _socket.initiateCall(recipientId, vaName, type);
    _toneService.playRingback();
    _startSignalPolling();
  }

  Future<void> acceptCall() async {
    if (_remoteUserId == null) return;
    _toneService.stop();
    await _httpAcceptCall();
    _socket.acceptCall(_remoteUserId!);
    _startSignalPolling();
  }

  void declineCall() {
    if (_remoteUserId == null) return;
    _toneService.stop();
    _httpDeclineCall();
    _socket.declineCall(_remoteUserId!);
    _callState = CallState.idle;
    _remoteUserId = null;
    _remoteUserName = null;
    notifyListeners();
  }

  void endCall() {
    _toneService.stop();
    if (_remoteUserId != null) {
      _httpEndCall(_remoteUserId!);
      _socket.endCall(_remoteUserId!);
    }
    _cleanup();
    _callState = CallState.idle;
    notifyListeners();
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        audioTracks[0].enabled = !audioTracks[0].enabled;
        _isMuted = !audioTracks[0].enabled;
        notifyListeners();
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        videoTracks[0].enabled = !videoTracks[0].enabled;
        _isCameraOff = !videoTracks[0].enabled;
        notifyListeners();
      }
    }
  }

  // ═══════════════════════════════════════
  // WebRTC
  // ═══════════════════════════════════════

  Future<void> _getLocalStream() async {
    try {
      final audioConstraint = _selectedAudioInput != null
          ? {'deviceId': _selectedAudioInput}
          : true;
      final videoConstraint = _callType == 'video'
          ? (_selectedVideoInput != null
              ? {'deviceId': _selectedVideoInput, 'width': 1280, 'height': 720}
              : {'width': 1280, 'height': 720, 'facingMode': 'user'})
          : false;

      final constraints = {
        'audio': audioConstraint,
        'video': videoConstraint,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;
      print('📞 Local stream: ${_localStream!.getAudioTracks().length} audio, ${_localStream!.getVideoTracks().length} video tracks');
    } catch (e) {
      print('⚠️ getUserMedia failed: $e');
      // Fallback: try audio-only if video failed
      if (_callType == 'video') {
        print('⚠️ Retrying with audio only...');
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          localRenderer.srcObject = _localStream;
        } catch (e2) {
          print('❌ Audio-only also failed: $e2');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      if (_remoteUserId != null) {
        final candidateMap = candidate.toMap();
        _httpSendSignal(_remoteUserId!, 'webrtc-ice-candidate', {'candidate': candidateMap});
        _socket.sendICECandidate(_remoteUserId!, candidateMap);
      }
    };

    pc.onTrack = (event) {
      print('🎥 onTrack fired: kind=${event.track.kind}, streams=${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        _remoteStreamKey++;
        // Ensure audio tracks are enabled
        for (final track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
          print('🔊 Remote audio track enabled: ${track.id}');
        }
        for (final track in _remoteStream!.getVideoTracks()) {
          track.enabled = true;
          print('🎥 Remote video track enabled: ${track.id}');
        }
        print('🎥 Remote stream set with ${_remoteStream!.getTracks().length} tracks (key=$_remoteStreamKey)');
        // Set audio output device if selected
        if (_selectedAudioOutput != null) {
          remoteRenderer.audioOutput(_selectedAudioOutput!).catchError((e) {
            print('⚠️ Could not set audio output: $e');
          });
        }
        notifyListeners();
      } else {
        print('🎥 No streams in event, track kind: ${event.track.kind}');
        notifyListeners();
      }
    };

    // Also listen via onAddStream for broader compatibility
    pc.onAddStream = (stream) {
      print('🎥 onAddStream fired with ${stream.getTracks().length} tracks');
      _remoteStream = stream;
      remoteRenderer.srcObject = stream;
      _remoteStreamKey++;
      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
        print('🔊 onAddStream: audio track enabled: ${track.id}');
      }
      for (final track in stream.getVideoTracks()) {
        track.enabled = true;
        print('🎥 onAddStream: video track enabled: ${track.id}');
      }
      notifyListeners();
    };

    pc.onIceConnectionState = (state) {
      print('ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        endCall();
      }
    };

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    _peerConnection = pc;
    return pc;
  }

  Future<void> _createAndSendOffer() async {
    if (_isNegotiating) {
      print('⚠️ Already negotiating, skipping duplicate offer');
      return;
    }
    _isNegotiating = true;
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_callState == CallState.idle) { _isNegotiating = false; return; }

      await _getLocalStream();
      final pc = await _createPeerConnection();
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      final offerMap = {'sdp': offer.sdp, 'type': offer.type};
      _httpSendSignal(_remoteUserId!, 'webrtc-offer', {'offer': offerMap});
      _socket.sendWebRTCOffer(_remoteUserId!, offerMap);
    } catch (e) {
      print('Error creating offer: $e');
      _isNegotiating = false;
      _cleanup();
      _callState = CallState.idle;
      notifyListeners();
    }
  }

  Future<void> _handleReceiveOffer(Map<String, dynamic> offer) async {
    if (_callState == CallState.idle) return;
    if (_isNegotiating) {
      print('⚠️ Already negotiating, skipping duplicate offer handling');
      return;
    }
    _isNegotiating = true;
    try {
      // Small delay to let UI settle before accessing media devices
      await Future.delayed(const Duration(milliseconds: 300));
      if (_callState == CallState.idle) { _isNegotiating = false; return; }

      await _getLocalStream();
      final pc = await _createPeerConnection();
      await pc.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      final answerMap = {'sdp': answer.sdp, 'type': answer.type};
      _httpSendSignal(_remoteUserId!, 'webrtc-answer', {'answer': answerMap});
      _socket.sendWebRTCAnswer(_remoteUserId!, answerMap);

      _callState = CallState.connected;
      _isNegotiating = false;
      _startDurationTimer();
      notifyListeners();
    } catch (e) {
      print('Error handling offer: $e');
      // Don't call endCall() here to avoid potential recursive crash
      _cleanup();
      _callState = CallState.idle;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════

  void _cleanup() {
    _toneService.stop();
    _isNegotiating = false;
    _isCaller = false;
    _signalPollTimer?.cancel();
    _signalPollTimer = null;

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _remoteStream = null;

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    _remoteUserId = null;
    _remoteUserName = null;
    _isMuted = false;
    _isCameraOff = false;
    _stopDurationTimer();
    _callDuration = 0;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _signalPollTimer?.cancel();
    _cleanup();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
