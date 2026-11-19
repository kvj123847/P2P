import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../state/app_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chats = state.chats
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Doubt Chats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: chats.isEmpty
                ? const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No conversations',
                    message: 'Open a tutor profile and tap the chat button to ask a doubt.',
                  )
                : ListView.separated(
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
                    itemBuilder: (_, i) {
                      final c = chats[i];
                      final last = c.messages.isEmpty ? null : c.messages.last;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: InitialsAvatar(
                            name: c.name, color: c.color, radius: 26, online: c.online),
                        title: Text(c.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          last == null
                              ? c.subtitle
                              : (last.attachmentName != null
                                  ? 'ðŸ“Ž ${last.attachmentName}'
                                  : (last.isMe ? 'You: ${last.text}' : last.text)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(last == null ? '' : Fmt.ago(last.time),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            if (c.unread > 0)
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.primary,
                                child: Text('${c.unread}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white)),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(thread: c)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
