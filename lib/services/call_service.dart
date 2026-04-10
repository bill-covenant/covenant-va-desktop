import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'socket_service.dart';
import 'tone_service.dart';
import '../core/constants/api_constants.dart';
import 'call_service_web_helpers.dart' if (dart.library.io) 'call_service_web_helpers_stub.dart';

enum CallState { idle, calling, ringing, connected }

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SocketService _socket = SocketService();
  final http.Client _httpClient = http.Client();
  final ToneService _toneService = ToneService();
  Map<String, dynamic>? _cachedIceConfig;
  DateTime? _iceCacheTime;

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
  bool get hasLocalVideo {
    if (_localStream == null) return false;
    final vt = _localStream!.getVideoTracks();
    return vt.isNotEmpty && vt[0].enabled;
  }
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
          final oldTrack = audioSender.track;
          await audioSender.replaceTrack(newTrack);
          oldTrack?.stop();
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
          final oldTrack = videoSender.track;
          await videoSender.replaceTrack(newTrack);
          oldTrack?.stop();
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
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
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
                // Ignore stale call-ended from previous calls
                if (_callState == CallState.calling) {
                  print('⚠️ Ignoring stale call-ended signal (still in calling state)');
                  break;
                }
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
                  if (_peerConnection!.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
                    final answer = Map<String, dynamic>.from(signalData['answer']);
                    await _peerConnection!.setRemoteDescription(
                      RTCSessionDescription(answer['sdp'], answer['type']),
                    );
                    _remoteDescriptionSet = true;
                    await _flushPendingCandidates();
                  } else {
                    print('⚠️ Ignoring duplicate answer (state: ${_peerConnection!.signalingState})');
                  }
                }
                break;
              case 'webrtc-ice-candidate':
                if (signalData['candidate'] != null) {
                  final candidate = Map<String, dynamic>.from(signalData['candidate']);
                  final iceCandidate = RTCIceCandidate(
                    candidate['candidate'],
                    candidate['sdpMid'],
                    candidate['sdpMLineIndex'],
                  );
                  await _addOrQueueCandidate(iceCandidate);
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
        body: jsonEncode({'callerId': _remoteUserId}),
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
      _startSignalPolling(); // Start polling now that call is accepted
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
      if (_peerConnection != null &&
          _peerConnection!.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
        _remoteDescriptionSet = true;
        await _flushPendingCandidates();
      } else {
        print('⚠️ Ignoring duplicate answer via socket');
      }
    };

    _socket.onICECandidate = (candidate) async {
      final iceCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      await _addOrQueueCandidate(iceCandidate);
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
    // Don't start signal polling yet — wait for call-accepted via socket
    // This avoids picking up stale signals from previous calls
  }

  Future<void> acceptCall() async {
    if (_remoteUserId == null) return;
    _toneService.stop();
    _resumeAudioContext();
    // Start fetching stream immediately (user gesture enables camera permission)
    // Don't await — let it run in parallel with HTTP accept so we don't delay signaling
    final streamFuture = _getLocalStream().catchError((e) {
      print('⚠️ Pre-fetch stream failed, will retry in offer handler: $e');
    });
    // Send accept signals immediately so client starts sending offer
    await _httpAcceptCall();
    _socket.acceptCall(_remoteUserId!);
    _startSignalPolling();
    // Now wait for stream to be ready (needed before _handleReceiveOffer creates peer connection)
    await streamFuture;
  }

  void _resumeAudioContext() {
    if (!kIsWeb) return;
    resumeAudioContext();
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

  // Queue for ICE candidates that arrive before remote description is set
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;

  /// Add ICE candidate to peer connection if ready, otherwise queue it.
  Future<void> _addOrQueueCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null && _remoteDescriptionSet) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('📞 Added ICE candidate directly');
        return;
      } catch (e) {
        print('⚠️ Error adding ICE candidate: $e');
      }
    }
    print('📞 Queuing ICE candidate (remote description not set yet)');
    _pendingCandidates.add(candidate);
  }

  Future<void> _flushPendingCandidates() async {
    if (_peerConnection == null) return;
    for (final candidate in _pendingCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('📞 Flushed queued ICE candidate');
      } catch (e) {
        print('Error flushing ICE candidate: $e');
      }
    }
    _pendingCandidates.clear();
  }

  Future<Map<String, dynamic>> _getIceConfig() async {
    // Return cached config if fresh (< 10 minutes)
    if (_cachedIceConfig != null && _iceCacheTime != null &&
        DateTime.now().difference(_iceCacheTime!) < const Duration(minutes: 10)) {
      return _cachedIceConfig!;
    }

    try {
      if (_authToken != null) {
        final url = '${ApiConstants.baseUrl}/calls/ice-servers';
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _cachedIceConfig = {
            'iceServers': data['iceServers'],
            'iceCandidatePoolSize': 10,
          };
          _iceCacheTime = DateTime.now();
          return _cachedIceConfig!;
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch ICE servers, using fallback: $e');
    }

    // Fallback to static credentials
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun.relay.metered.ca:80'},
        {'urls': 'turn:global.relay.metered.ca:80', 'username': 'e8dd65c092d0109410299e70', 'credential': 'mHj+thls0x0TEtv3'},
        {'urls': 'turn:global.relay.metered.ca:80?transport=tcp', 'username': 'e8dd65c092d0109410299e70', 'credential': 'mHj+thls0x0TEtv3'},
        {'urls': 'turn:global.relay.metered.ca:443', 'username': 'e8dd65c092d0109410299e70', 'credential': 'mHj+thls0x0TEtv3'},
        {'urls': 'turns:global.relay.metered.ca:443?transport=tcp', 'username': 'e8dd65c092d0109410299e70', 'credential': 'mHj+thls0x0TEtv3'},
      ],
      'iceCandidatePoolSize': 10,
    };
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    // Close any existing connection first
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    _pendingCandidates.clear();

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun.relay.metered.ca:80'},
        {'urls': 'turn:global.relay.metered.ca:80', 'username': '1e8a2eed6c2a06031d3db848', 'credential': 'uDLx4lO/dbVFJB7a'},
        {'urls': 'turn:global.relay.metered.ca:80?transport=tcp', 'username': '1e8a2eed6c2a06031d3db848', 'credential': 'uDLx4lO/dbVFJB7a'},
        {'urls': 'turn:global.relay.metered.ca:443', 'username': '1e8a2eed6c2a06031d3db848', 'credential': 'uDLx4lO/dbVFJB7a'},
        {'urls': 'turns:global.relay.metered.ca:443?transport=tcp', 'username': '1e8a2eed6c2a06031d3db848', 'credential': 'uDLx4lO/dbVFJB7a'},
      ],
      'iceCandidatePoolSize': 10,
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

        // On web: attach stream to an HTML audio element as backup for audio playback
        if (kIsWeb) {
          attachStreamToAudioElement(_remoteStream!);
        }

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
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        endCall();
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print('⚠️ ICE disconnected — waiting for recovery...');
        Future.delayed(const Duration(seconds: 10), () {
          if (_peerConnection?.iceConnectionState ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              _peerConnection?.iceConnectionState ==
              RTCIceConnectionState.RTCIceConnectionStateFailed) {
            print('❌ ICE did not recover, ending call');
            endCall();
          }
        });
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
      _isNegotiating = false;
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
    // Skip if already connected or negotiating
    if (_peerConnection != null && _callState == CallState.connected) {
      print('⚠️ Already connected, skipping duplicate offer');
      return;
    }
    if (_isNegotiating) {
      print('⚠️ Already negotiating, skipping duplicate offer handling');
      return;
    }
    _isNegotiating = true;
    // Stop ringtone as soon as we start processing the offer
    _toneService.stop();
    try {
      if (_callState == CallState.idle) { _isNegotiating = false; return; }

      // Only get local stream if not already acquired (acceptCall pre-fetches for audio)
      if (_localStream == null) {
        await _getLocalStream();
      }
      final pc = await _createPeerConnection();
      await pc.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      _remoteDescriptionSet = true;
      await _flushPendingCandidates();

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      final answerMap = {'sdp': answer.sdp, 'type': answer.type};
      _httpSendSignal(_remoteUserId!, 'webrtc-answer', {'answer': answerMap});
      _socket.sendWebRTCAnswer(_remoteUserId!, answerMap);

      _callState = CallState.connected;
      _isNegotiating = false;
      _toneService.stop(); // Ensure ringtone is stopped
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
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();
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
