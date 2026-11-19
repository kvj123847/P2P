import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../sessions/live_video_screen.dart';

/// Chat-based doubt solving between a learner and a tutor.
/// For a real backend use WebSockets (Flask-SocketIO) or Firebase.
class ChatScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatScreen({super.key, required this.thread});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  Timer? _replyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).markChatRead(widget.thread);
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send({String? attachment}) {
    final text = _controller.text.trim();
    if (text.isEmpty && attachment == null) return;
    final state = AppScope.read(context);
    state.sendMessage(widget.thread, text, attachment: attachment);
    _controller.clear();
    _scrollToEnd();

    // Simulated tutor reply with a typing indicator.
    setState(() => _typing = true);
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _typing = false);
      state.receiveAutoReply(widget.thread);
      _scrollToEnd();
    });
  }

  void _attach() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: AppColors.primary),
              title: const Text('Photo of question'),
              onTap: () {
                Navigator.pop(ctx);
                _send(attachment: 'question_photo.jpg');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
              title: const Text('Document / PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _send(attachment: 'notes.pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.success),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _send(attachment: 'camera_capture.jpg');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startCall() {
    final t = widget.thread;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveVideoScreen(
          session: Session(
            id: 'call_${t.id}',
            title: 'Quick doubt call',
            tutorName: t.name,
            subject: t.subtitle,
            type: SessionType.oneToOne,
            dateTime: DateTime.now(),
            durationMinutes: 15,
            participants: 2,
            status: SessionStatus.upcoming,
            price: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // rebuild when messages change
    final t = widget.thread;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(name: t.name, color: t.color, radius: 20, online: t.online),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 16)),
                  Text(
                    _typing ? 'typingâ€¦' : (t.online ? 'Online' : t.subtitle),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _typing || t.online ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: _startCall),
          PopupMenuButton<String>(
            onSelected: (v) => showSnack(context, '$v (demo)'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Report user', child: Text('Report user')),
              PopupMenuItem(value: 'Block user', child: Text('Block user')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'Chats are monitored for safety. Never share personal contact details.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: t.messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == t.messages.length) return const _TypingBubble();
                return MessageBubble(message: t.messages[i]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                    onPressed: _attach,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type your doubtâ€¦',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final me = message.isMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: me ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(me ? 16 : 4),
            bottomRight: Radius.circular(me ? 4 : 16),
          ),
          border: me ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.attachmentName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: me ? Colors.white.withAlpha(40) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.attachmentName!.endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: me ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(message.attachmentName!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: me ? Colors.white : AppColors.textPrimary,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (message.text.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  message.text,
                  style: TextStyle(color: me ? Colors.white : AppColors.textPrimary),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Fmt.time(message.time),
                  style: TextStyle(
                      fontSize: 10, color: me ? Colors.white70 : AppColors.textSecondary),
                ),
                if (me) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('â€¢ â€¢ â€¢',
            style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2)),
      ),
    );
  }
}
