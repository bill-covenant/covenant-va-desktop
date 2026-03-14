import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'socket_service.dart';
import '../core/constants/api_constants.dart';

enum CallState { idle, calling, ringing, connected }

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SocketService _socket = SocketService();
  final http.Client _httpClient = http.Client();

  // Auth token for HTTP polling
  String? _authToken;

  // State
  CallState _callState = CallState.idle;
  String _callType = 'video';
  String? _remoteUserId;
  String? _remoteUserName;
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
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Global key for showing dialogs from anywhere
  GlobalKey<NavigatorState>? navigatorKey;

  // Getters
  CallState get callState => _callState;
  String get callType => _callType;
  String? get remoteUserId => _remoteUserId;
  String? get remoteUserName => _remoteUserName;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  int get callDuration => _callDuration;
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
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _setupSocketListeners();
    _startCallPolling();
    print('📞 CallService initialized with HTTP polling');
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
            _callState = CallState.ringing;
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
      _callState = CallState.ringing;
      notifyListeners();
    };

    _socket.onCallAccepted = () async {
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
    _callState = CallState.calling;
    _isMuted = false;
    _isCameraOff = false;
    _callDuration = 0;
    notifyListeners();

    final vaName = 'VA';
    _socket.initiateCall(recipientId, vaName, type);
    _startSignalPolling();
  }

  Future<void> acceptCall() async {
    if (_remoteUserId == null) return;
    await _httpAcceptCall();
    _socket.acceptCall(_remoteUserId!);
    _startSignalPolling();
  }

  void declineCall() {
    if (_remoteUserId == null) return;
    _httpDeclineCall();
    _socket.declineCall(_remoteUserId!);
    _callState = CallState.idle;
    _remoteUserId = null;
    _remoteUserName = null;
    notifyListeners();
  }

  void endCall() {
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
    final constraints = {
      'audio': true,
      'video': _callType == 'video'
          ? {'width': 1280, 'height': 720, 'facingMode': 'user'}
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
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
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        notifyListeners();
      }
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
    try {
      await _getLocalStream();
      final pc = await _createPeerConnection();
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      final offerMap = {'sdp': offer.sdp, 'type': offer.type};
      _httpSendSignal(_remoteUserId!, 'webrtc-offer', {'offer': offerMap});
      _socket.sendWebRTCOffer(_remoteUserId!, offerMap);
    } catch (e) {
      print('Error creating offer: $e');
      endCall();
    }
  }

  Future<void> _handleReceiveOffer(Map<String, dynamic> offer) async {
    try {
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
      _startDurationTimer();
      notifyListeners();
    } catch (e) {
      print('Error handling offer: $e');
      endCall();
    }
  }

  // ═══════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════

  void _cleanup() {
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
