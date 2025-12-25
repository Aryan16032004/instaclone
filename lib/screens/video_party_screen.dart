import 'package:flutter/material.dart';
import 'package:flutter_prj/services/video_party_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class VideoPartyScreen extends StatefulWidget {
  final String? partyId;

  const VideoPartyScreen({super.key, this.partyId});

  @override
  State<VideoPartyScreen> createState() => _VideoPartyScreenState();
}

class _VideoPartyScreenState extends State<VideoPartyScreen> {
  final VideoPartyService _partyService = VideoPartyService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _activeParties = [];
  List<Map<String, dynamic>> _filteredParties = [];
  Map<String, dynamic>? _currentParty;
  List<Map<String, dynamic>> _participants = [];
  RtcEngine? _agoraEngine;
  bool _isLoading = true;
  bool _isHost = false;
  bool _isMuted = true;
  bool _isCameraOn = true;
  int _maxParticipants = 10;
  Set<int> _remoteUids = {};
  int? _localUid;

  static const String agoraAppId = 'a28397338e544f5c91192b5b586d03a4';

  @override
  void initState() {
    super.initState();
    if (widget.partyId != null) {
      _joinParty(widget.partyId!);
    } else {
      _loadActiveParties();
    }
  }

  Future<void> _initializeAgora(String channelName) async {
    await [Permission.camera, Permission.microphone].request();

    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine!.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _agoraEngine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Joined video channel: ${connection.channelId}');
          setState(() => _localUid = connection.localUid);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUids.add(remoteUid));
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              setState(() => _remoteUids.remove(remoteUid));
            },
      ),
    );

    await _agoraEngine!.enableVideo();
    await _agoraEngine!.startPreview();

    await _agoraEngine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );

    setState(() {
      _isCameraOn = true;
      _isMuted = false;
    });
  }

  Future<void> _loadActiveParties() async {
    setState(() => _isLoading = true);
    final parties = await _partyService.getActiveParties();
    setState(() {
      _activeParties = parties;
      _filteredParties = parties;
      _isLoading = false;
    });

    // Set up real-time subscription for party updates
    _partyService.supabase
        .from('video_parties')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .listen((data) {
          if (mounted) {
            setState(() {
              _activeParties = List<Map<String, dynamic>>.from(data);
              _filterParties();
            });
          }
        });
  }

  void _filterParties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredParties = _activeParties;
      } else {
        _filteredParties = _activeParties.where((party) {
          final title = (party['title'] ?? '').toString().toLowerCase();
          final description = (party['description'] ?? '')
              .toString()
              .toLowerCase();
          return title.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _createParty() async {
    if (_titleController.text.isEmpty) {
      _showMessage('Please enter a title', isError: true);
      return;
    }

    final party = await _partyService.createVideoParty(
      title: _titleController.text,
      description: _descriptionController.text,
      maxParticipants: _maxParticipants,
    );

    if (party != null) {
      _showMessage('Party created!');
      Navigator.pop(context);
      _joinParty(party['id']);
    } else {
      _showMessage('Failed to create party', isError: true);
    }
  }

  Future<void> _joinParty(String partyId) async {
    final success = await _partyService.joinParty(partyId);
    if (success) {
      _loadPartyDetails(partyId);
    } else {
      _showMessage('Party is full or failed to join', isError: true);
    }
  }

  Future<void> _loadPartyDetails(String partyId) async {
    setState(() => _isLoading = true);

    _partyService.streamParty(partyId).listen((party) {
      if (party != null && mounted) {
        setState(() {
          _currentParty = party;
          _isHost =
              party['host_id'] == _partyService.supabase.auth.currentUser?.id;
        });

        if (_agoraEngine == null && party['agora_channel_name'] != null) {
          _initializeAgora(party['agora_channel_name']);
        }
      }
    });

    _partyService.streamParticipants(partyId).listen((participants) {
      if (mounted) {
        setState(() => _participants = participants);
      }
    });

    setState(() => _isLoading = false);
  }

  Future<void> _toggleMute() async {
    await _agoraEngine?.muteLocalAudioStream(_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleCamera() async {
    if (_agoraEngine == null) return;

    final newCameraState = !_isCameraOn;
    await _agoraEngine!.muteLocalVideoStream(!newCameraState);

    setState(() {
      _isCameraOn = newCameraState;
    });
  }

  Future<void> _switchCamera() async {
    await _agoraEngine?.switchCamera();
  }

  Future<void> _leaveParty() async {
    if (_currentParty != null) {
      // Leave party in database first
      await _partyService.leaveParty(_currentParty!['id']);

      // Then clean up Agora
      await _agoraEngine?.leaveChannel();
      await _agoraEngine?.release();
      _agoraEngine = null;

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Clean up when screen is disposed
    if (_currentParty != null) {
      _partyService.leaveParty(_currentParty!['id']);
    }
    _agoraEngine?.leaveChannel();
    _agoraEngine?.release();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppTheme.gradientContainer(
        child: SafeArea(
          child: _currentParty == null ? _buildPartyList() : _buildPartyRoom(),
        ),
      ),
    );
  }

  Widget _buildPartyList() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryPink),
                )
              : _activeParties.isEmpty
              ? _buildEmptyState()
              : _buildPartiesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Icons.videocam, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Video Parties', style: AppTheme.headingMedium),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
            onPressed: _showCreatePartyDialog,
            tooltip: 'Create Party',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient.scale(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('No active video parties', style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          const Text(
            'Create one and watch together!',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          AppTheme.gradientButton(
            text: 'Create Party',
            icon: Icons.add,
            onPressed: _showCreatePartyDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _filterParties(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search parties...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _filterParties();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Party list
        Expanded(
          child: _filteredParties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredParties.length,
                  itemBuilder: (context, index) =>
                      _buildPartyCard(_filteredParties[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(Map<String, dynamic> party) {
    final currentCount = party['current_participants'] ?? 0;
    final maxCount = party['max_participants'] ?? 10;
    final isFull = currentCount >= maxCount;

    // Get host info - handle both nested and flat structures
    final host = party['host'];
    final hostName = host is Map ? (host['username'] ?? 'Unknown') : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isFull ? null : () => _joinParty(party['id']),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.darkBackground,
                        backgroundImage:
                            host is Map && host['avatar_url'] != null
                            ? NetworkImage(host['avatar_url'])
                            : null,
                        child: host is Map && host['avatar_url'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party['title'] ?? 'Untitled Party',
                            style: AppTheme.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'by $hostName',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button for host
                    if (party['host_id'] ==
                        _partyService.supabase.auth.currentUser?.id)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.darkBackground,
                              title: const Text(
                                'Delete Party?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'This will permanently delete this party for everyone.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // Delete from database
                            await _partyService.endParty(party['id']);

                            // Immediately remove from local list
                            setState(() {
                              _activeParties.removeWhere(
                                (p) => p['id'] == party['id'],
                              );
                              _filterParties();
                            });

                            _showMessage('Party deleted');
                          }
                        },
                        tooltip: 'Delete Party',
                      ),
                  ],
                ),
                if (party['description'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    party['description'],
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isFull
                            ? Colors.red.withOpacity(0.2)
                            : AppTheme.primaryPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFull ? Colors.red : AppTheme.primaryPink,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: isFull ? Colors.red : AppTheme.primaryPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentCount/$maxCount',
                            style: TextStyle(
                              color: isFull ? Colors.red : AppTheme.primaryPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'FULL',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      AppTheme.gradientButton(
                        text: 'Join',
                        icon: Icons.login,
                        onPressed: () => _joinParty(party['id']),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyRoom() {
    return Column(
      children: [
        _buildRoomHeader(),
        Expanded(child: _buildVideoGrid()),
        _buildControlBar(),
      ],
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _leaveParty,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentParty?['title'] ?? '',
                  style: AppTheme.headingSmall,
                ),
                if (_currentParty?['description'] != null)
                  Text(
                    _currentParty!['description'],
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_currentParty?['current_participants']}/${_currentParty?['max_participants']}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isHost) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: () async {
                await _partyService.endParty(_currentParty!['id']);
                _leaveParty();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    final allUids = [if (_localUid != null) _localUid!, ..._remoteUids];

    if (allUids.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPink),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: allUids.length == 1 ? 1 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: allUids.length,
      itemBuilder: (context, index) {
        final uid = allUids[index];
        final isLocal = uid == _localUid;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocal
                  ? AppTheme.primaryPink
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                isLocal
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _agoraEngine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _agoraEngine!,
                          canvas: VideoCanvas(uid: uid),
                          connection: RtcConnection(
                            channelId: _currentParty!['agora_channel_name'],
                          ),
                        ),
                      ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLocal ? 'You' : 'User $uid',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: _toggleMute,
            gradient: _isMuted ? null : AppTheme.primaryGradient,
            color: _isMuted ? Colors.grey : null,
          ),
          _buildControlButton(
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
            label: _isCameraOn ? 'Camera On' : 'Camera Off',
            onTap: _toggleCamera,
            gradient: _isCameraOn ? AppTheme.primaryGradient : null,
            color: _isCameraOn ? null : Colors.grey,
          ),
          _buildControlButton(
            icon: Icons.flip_camera_android,
            label: 'Flip',
            onTap: _switchCamera,
            color: AppTheme.darkPurple,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            onTap: _leaveParty,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Gradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                if (gradient != null)
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  void _showCreatePartyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Video Party', style: AppTheme.headingSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration('Party Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: AppTheme.inputDecoration('Description (optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Max Participants', style: AppTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxParticipants.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      activeColor: AppTheme.primaryPink,
                      inactiveColor: Colors.white.withOpacity(0.2),
                      label: _maxParticipants.toString(),
                      onChanged: (value) {
                        setState(() => _maxParticipants = value.toInt());
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _maxParticipants.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          AppTheme.gradientButton(text: 'Create', onPressed: _createParty),
        ],
      ),
    );
  }
}
