import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;

  VideoCallScreen({required this.roomId});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  bool _remoteVideoReceived = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _requestPermissions();
      await _initRenderers();
      await _initWebSocket();
      await _createPeerConnection();
      print('Call initialized successfully');
    } catch (e) {
      print('Error initializing call: $e');
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    statuses.forEach((permission, status) {
      print('$permission: $status');
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    print('Renderers initialized');
  }

  Future<void> _initWebSocket() async {
    try {
      _channel = IOWebSocketChannel.connect(
        'ws://10.87.5.153:8080/reverb?appKey=g5t9hswh012cw43j3plr&appId=419548',
      );

      _channel!.stream.listen(
            (message) {
          print('Received WebSocket message: $message');
          _handleSignalingMessage(jsonDecode(message));
        },
        onError: (error) => print('WebSocket error: $error'),
        onDone: () => print('WebSocket connection closed'),
      );
      print('WebSocket initialized');
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
    }
  }

  void _handleSignalingMessage(dynamic message) {
    try {
      print('Handling signaling message: $message');
      if (message['event'] == 'signaling') {
        final data = jsonDecode(message['data']['message']);
        if (data['type'] == 'offer') {
          _handleOffer(data);
        } else if (data['type'] == 'answer') {
          _handleAnswer(data);
        } else if (data['type'] == 'ice_candidate') {
          _handleIceCandidate(data);
        }
      }
    } catch (e) {
      print('Error handling signaling message: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    try {
      print('Handling offer: $offer');
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _sendSignalingMessage({
        'type': 'answer',
        'sdp': answer.sdp,
      });
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    try {
      print('Handling answer: $answer');
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answer['sdp'], answer['type']),
      );
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidate) async {
    try {
      print('Handling ICE candidate: $candidate');
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  void _sendSignalingMessage(Map<String, dynamic> message) {
    try {
      print('Sending signaling message: $message');
      _channel?.sink.add(jsonEncode({
        'event': 'signaling',
        'channel': 'video-call.${widget.roomId}',
        'data': {
          'message': jsonEncode(message),
        },
      }));
    } catch (e) {
      print('Error sending signaling message: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': ['stun:stun.l.google.com:19302']}
      ]
    };

    try {
      _peerConnection = await createPeerConnection(config);

      _peerConnection!.onIceCandidate = (candidate) {
        print('ICE candidate: ${candidate.toMap()}');
        _sendSignalingMessage({
          'type': 'ice_candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      _peerConnection!.onIceConnectionState = (state) {
        print('ICE connection state change: $state');
      };

      _peerConnection!.onConnectionState = (state) {
        print('Connection state change: $state');
      };

      _peerConnection!.onTrack = (event) {
        print('Received track: ${event.track.kind}');
        if (event.track.kind == 'video') {
          _remoteRenderer.srcObject = event.streams[0];
          setState(() {
            _remoteVideoReceived = true;
          });
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _localRenderer.srcObject = _localStream;
      setState(() {});
      print('Peer connection created');
    } catch (e) {
      print('Error creating peer connection: $e');
    }
  }

  Future<void> _makeCall() async {
    try {
      print('Making call');
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _sendSignalingMessage({
        'type': 'offer',
        'sdp': offer.sdp,
      });
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('Error making call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebRTC Video Call')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
                Expanded(
                  child: _remoteVideoReceived
                      ? RTCVideoView(_remoteRenderer)
                      : Center(child: Text('Waiting for remote video...')),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isConnected ? null : _makeCall,
            child: Text(_isConnected ? 'Connected' : 'Start Call'),
          ),
        ],
      ),
    );
  }
}

