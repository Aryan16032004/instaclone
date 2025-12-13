import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/flying_heart.dart'; 

// ⚠️ YOUR AGORA APP ID
const appId = "a28397338e544f5c91192b5b586d03a4"; 

class LiveScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;

  const LiveScreen({super.key, required this.isBroadcaster, required this.channelId});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  // Agora Variables
  late RtcEngine _engine;
  bool _isReady = false;
  int? _remoteUid;
  
  // Chat & UI Variables
  final _commentCtrl = TextEditingController();
  final List<Widget> _hearts = []; 
  final _supabase = Supabase.instance.client;
  late StreamSubscription _chatSubscription;
  
  // 🔴 NEW: Viewer Tracking
  RealtimeChannel? _roomChannel;
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _subscribeToRealtime();
  }

  // 1. Setup Chat AND Viewer Tracking (FIXED FOR V2)
  void _subscribeToRealtime() {
    // A. Listen for Comments
    _chatSubscription = _supabase
        .from('live_comments')
        .stream(primaryKey: ['id'])
        .eq('channel_id', widget.channelId)
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final latest = data.last;
            if (latest['is_heart'] == true) {
              _triggerHeartAnimation();
            }
          }
        });

    // B. 🔴 Listen for Viewers (Presence) - FIXED CODE
    _roomChannel = _supabase.channel('room_${widget.channelId}');
    
    // Use onPresenceSync instead of ChannelFilter
    _roomChannel?.onPresenceSync((payload) {
      if (!mounted) return;
      
      // Get the current list of people in the room
      final presenceState = _roomChannel?.presenceState();
      
      setState(() {
        // The length of the map keys equals the number of unique users
        _viewerCount = presenceState?.length ?? 0;
      });
    }).subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // I have joined! Tell Supabase I am here.
        final myId = _supabase.auth.currentUser!.id;
        // Track my presence in the room
        await _roomChannel?.track({'user_id': myId});
      }
    });
  }

  // 2. Add a Heart to the screen
  void _triggerHeartAnimation() {
    setState(() {
      _hearts.add(Positioned(
        bottom: 100,
        right: 40,
        child: FlyingHeart(),
      ));
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_hearts.isNotEmpty) _hearts.removeAt(0);
        });
      }
    });
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();
    
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    
    await _engine.setClientRole(role: widget.isBroadcaster
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience);
        
    await _engine.enableVideo();
    await _engine.startPreview();
    
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) => setState(() => _isReady = true),
        onUserJoined: (_, uid, __) => setState(() => _remoteUid = uid),
        onUserOffline: (_, __, ___) {
          if (!widget.isBroadcaster) Navigator.pop(context);
        },
      ),
    );
    
    await _engine.joinChannel(
      token: "", 
      channelId: widget.channelId, 
      uid: 0, 
      options: const ChannelMediaOptions()
    );
  }

  void _sendMessage() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    await _supabase.from('live_comments').insert({
      'channel_id': widget.channelId,
      'user_id': _supabase.auth.currentUser!.id,
      'message': text,
      'is_heart': false,
    });
  }

  void _sendHeart() async {
    _triggerHeartAnimation(); 
    await _supabase.from('live_comments').insert({
      'channel_id': widget.channelId,
      'user_id': _supabase.auth.currentUser!.id,
      'is_heart': true, 
    });
  }

  @override
  void dispose() {
    // Clean up Agora and Supabase connections
    _engine.leaveChannel();
    _engine.release();
    _chatSubscription.cancel();
    _roomChannel?.unsubscribe(); // Stop tracking presence
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // A. Video Layer
          Center(child: _renderVideo()),

          // B. Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔴 NEW: Live Badge + Viewer Count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red, 
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text("$_viewerCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      // Close Button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // C. Comments Area
                Container(
                  height: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                        stops: [0.0, 0.3],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('live_comments')
                          .stream(primaryKey: ['id'])
                          .eq('channel_id', widget.channelId)
                          .order('created_at', ascending: false) 
                          .limit(50), 
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final msgs = snapshot.data!;
                        
                        return ListView.builder(
                          reverse: true,
                          itemCount: msgs.length,
                          itemBuilder: (context, index) {
                            final msg = msgs[index];
                            if (msg['is_heart'] == true) return const SizedBox.shrink(); 

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _supabase.from('profiles').select().eq('id', msg['user_id']).maybeSingle(),
                              builder: (context, userSnap) {
                                final username = userSnap.data?['username'] ?? 'User';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundImage: (userSnap.data != null && userSnap.data!['avatar_url'] != null)
                                            ? NetworkImage(userSnap.data!['avatar_url'])
                                            : null,
                                        child: userSnap.data?['avatar_url'] == null ? const Icon(Icons.person, size: 12) : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(text: "$username  ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                              TextSpan(text: msg['message'], style: const TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // D. Input & Heart Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Say something...",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendHeart,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // E. Floating Hearts Layer
          ..._hearts,
        ],
      ),
    );
  }

  Widget _renderVideo() {
    if (widget.isBroadcaster) {
      return _isReady ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine, canvas: const VideoCanvas(uid: 0))) : const CircularProgressIndicator();
    } else {
      return _remoteUid != null 
          ? AgoraVideoView(controller: VideoViewController.remote(rtcEngine: _engine, canvas: VideoCanvas(uid: _remoteUid), connection: RtcConnection(channelId: widget.channelId))) 
          : const Center(child: Text("Waiting for host...", style: TextStyle(color: Colors.white)));
    }
  }
}