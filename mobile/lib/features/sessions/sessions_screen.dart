import 'package:flutter/material.dart';

import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'create_session_sheet.dart';
import 'group_session_screen.dart';
import 'live_video_screen.dart';

/// Upcoming + past sessions (session schedule & history).
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  void _join(BuildContext context, Session s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => s.type == SessionType.group
            ? GroupSessionScreen(session: s)
            : LiveVideoScreen(session: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final upcoming = state.upcomingSessions;
    final past = state.pastSessions;
    final canTeach = state.role.canTeach;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Sessions'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              const Tab(text: 'History'),
            ],
          ),
        ),
        floatingActionButton: canTeach
            ? FloatingActionButton.extended(
                onPressed: () => showCreateSessionSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('New session'),
              )
            : null,
        body: TabBarView(
          children: [
            upcoming.isEmpty
                ? const EmptyState(
                    icon: Icons.event_busy,
                    title: 'No upcoming sessions',
                    message: 'Find a tutor in Explore and book a session.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: upcoming.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => SessionCard(
                      session: upcoming[i],
                      onJoin: () => _join(context, upcoming[i]),
                    ),
                  ),
            past.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'No past sessions',
                    message: 'Completed sessions will appear here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: past.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => SessionCard(
                      session: past[i],
                      onTap: () => showSnack(context, 'Session recording & notes open here'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
