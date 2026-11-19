import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';

/// Round control button used in the call toolbar.
class CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? color;

  const CallControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (active ? Colors.white.withAlpha(30) : Colors.white);
    final fg = color != null ? Colors.white : (active ? Colors.white : AppColors.callBackground);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: fg, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

/// A participant's "video" tile. Real video goes here when Agora / WebRTC
/// is integrated (replace the avatar with the SDK's video view widget).
class ParticipantTile extends StatelessWidget {
  final String name;
  final Color color;
  final bool muted;
  final bool cameraOff;
  final bool speaking;
  final bool handRaised;
  final String? badge;
  final double avatarRadius;

  const ParticipantTile({
    super.key,
    required this.name,
    required this.color,
    this.muted = false,
    this.cameraOff = false,
    this.speaking = false,
    this.handRaised = false,
    this.badge,
    this.avatarRadius = 34,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.callTile,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: speaking ? AppColors.success : Colors.transparent,
          width: 2.5,
        ),
        gradient: cameraOff
            ? null
            : LinearGradient(
                colors: [color.withAlpha(90), AppColors.callTile],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Stack(
        children: [
          Center(
            child: cameraOff
                ? const Icon(Icons.videocam_off, color: Colors.white38, size: 36)
                : InitialsAvatar(name: name, color: Colors.white, radius: avatarRadius),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 10,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(110),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (muted) ...[
                          const Icon(Icons.mic_off, size: 13, color: Colors.redAccent),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            badge == null ? name : '$name ($badge)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (handRaised)
            const Positioned(
              right: 10,
              top: 10,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.amber,
                child: Text('âœ‹', style: TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class CallMessage {
  final String sender;
  final String text;
  final DateTime time;
  CallMessage(this.sender, this.text) : time = DateTime.now();
}

/// In-call chat panel shown as a bottom sheet.
Future<void> showInCallChat(
  BuildContext context,
  List<CallMessage> messages,
  String myName,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          void send() {
            if (controller.text.trim().isEmpty) return;
            setSheet(() => messages.add(CallMessage(myName, controller.text.trim())));
            controller.clear();
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.55,
              child: Column(
                children: [
                  const Text('Session chat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${m.sender}  ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                TextSpan(
                                  text: Fmt.time(m.time),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                                TextSpan(text: '\n${m.text}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            onSubmitted: (_) => send(),
                            decoration: const InputDecoration(hintText: 'Message everyone'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(onPressed: send, icon: const Icon(Icons.send)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Ask for a rating after a session ends (feedback loop in the workflow).
Future<void> showSessionFeedback(BuildContext context, String tutorName) {
  int stars = 0;
  final comment = TextEditingController();
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('How was your session?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate your session with $tutorName',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setD(() => stars = i + 1),
                  icon: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                );
              }),
            ),
            TextField(
              controller: comment,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Write a short review (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
          FilledButton(
            onPressed: stars == 0
                ? null
                : () {
                    Navigator.pop(ctx);
                    showSnack(context, 'Thanks for your feedback!');
                  },
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}
