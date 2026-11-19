import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'call_widgets.dart';

class _Participant {
  final String name;
  final Color color;
  bool muted;
  bool handRaised;
  final String? badge;

  _Participant(this.name, this.color, {this.muted = true, this.handRaised = false, this.badge});
}

/// Group live-session UI: participant grid, raise hand, chat, participants list.
class GroupSessionScreen extends StatefulWidget {
  final Session session;

  const GroupSessionScreen({super.key, required this.session});

  @override
  State<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends State<GroupSessionScreen> {
  late final List<_Participant> _others;
  bool _micOn = false;
  bool _camOn = true;
  bool _handRaised = false;
  int _seconds = 0;
  int _speaker = 0;
  Timer? _timer;
  final List<CallMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _others = [
      _Participant(widget.session.tutorName, AppColors.secondary, muted: false, badge: 'Host'),
      _Participant('Nikhil', const Color(0xFF10B981)),
      _Participant('Anjali', const Color(0xFFEC4899), handRaised: true),
      _Participant('Rohan', const Color(0xFFF97316)),
      _Participant('Diya', const Color(0xFF8B5CF6)),
    ];
    _messages.addAll([
      CallMessage(widget.session.tutorName, 'Welcome everyone! We start in a minute.'),
      CallMessage('Anjali', 'Can we cover last year\'s question 4?'),
    ]);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
        if (_seconds % 4 == 0) _speaker = (_speaker + 1) % _others.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    _timer?.cancel();
    await showSessionFeedback(context, widget.session.tutorName);
    if (mounted) Navigator.pop(context);
  }

  void _showParticipants(String me) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Participants (${_others.length + 1})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('$me (You)'),
            trailing: Icon(_micOn ? Icons.mic : Icons.mic_off),
          ),
          for (final p in _others)
            ListTile(
              leading: Icon(p.badge == 'Host' ? Icons.star : Icons.person),
              title: Text(p.badge == null ? p.name : '${p.name} (${p.badge})'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.handRaised) const Text('âœ‹  '),
                  Icon(p.muted ? Icons.mic_off : Icons.mic),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).name;
    final tiles = <Widget>[
      for (var i = 0; i < _others.length; i++)
        ParticipantTile(
          name: _others[i].name,
          color: _others[i].color,
          muted: _others[i].muted,
          handRaised: _others[i].handRaised,
          speaking: i == _speaker,
          badge: _others[i].badge,
        ),
      ParticipantTile(
        name: me,
        color: AppColors.primary,
        muted: !_micOn,
        cameraOff: !_camOn,
        handRaised: _handRaised,
        badge: 'You',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.callBackground,
        appBar: AppBar(
          backgroundColor: AppColors.callBackground,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Group session â€¢ ${Fmt.duration(_seconds)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showParticipants(me),
              icon: Badge(
                label: Text('${tiles.length}'),
                child: const Icon(Icons.people_alt_outlined),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: tiles.length,
                itemBuilder: (_, i) => tiles[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CallControl(
                    icon: _micOn ? Icons.mic : Icons.mic_off,
                    label: _micOn ? 'Mute' : 'Unmute',
                    active: _micOn,
                    onTap: () => setState(() => _micOn = !_micOn),
                  ),
                  CallControl(
                    icon: _camOn ? Icons.videocam : Icons.videocam_off,
                    label: 'Camera',
                    active: _camOn,
                    onTap: () => setState(() => _camOn = !_camOn),
                  ),
                  CallControl(
                    icon: Icons.back_hand_outlined,
                    label: _handRaised ? 'Lower' : 'Raise hand',
                    active: !_handRaised,
                    onTap: () => setState(() => _handRaised = !_handRaised),
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
                    label: 'Leave',
                    color: AppColors.error,
                    onTap: _leave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
