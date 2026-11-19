import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../sessions/sessions_screen.dart';
import '../tutors/explore_screen.dart';
import 'learner_dashboard.dart';
import 'tutor_dashboard.dart';

/// Bottom-navigation container: Home | Explore | Sessions | Chat | Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  String? _exploreSubject;
  int _exploreTab = 0;

  void _goTo(int index) => setState(() => _index = index);

  void _exploreWith({String? subject, int tab = 0}) {
    setState(() {
      _exploreSubject = subject;
      _exploreTab = tab;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final showTutorHome =
        state.role == UserRole.tutor || (state.role == UserRole.both && state.teachingMode);

    final pages = <Widget>[
      showTutorHome
          ? TutorDashboard(onTab: _goTo)
          : LearnerDashboard(onTab: _goTo, onExplore: _exploreWith),
      ExploreScreen(
        key: ValueKey('explore_${_exploreSubject}_$_exploreTab'),
        initialSubject: _exploreSubject,
        initialTab: _exploreTab,
      ),
      const SessionsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    final unread = state.unreadChats;

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.primary),
            label: 'Explore',
          ),
          const NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam, color: AppColors.primary),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// "Learning | Teaching" switch shown to users with the Both role.
class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.role != UserRole.both) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
              value: false, label: Text('Learning'), icon: Icon(Icons.menu_book)),
          ButtonSegment(value: true, label: Text('Teaching'), icon: Icon(Icons.school)),
        ],
        selected: {state.teachingMode},
        onSelectionChanged: (s) => AppScope.read(context).toggleTeachingMode(s.first),
      ),
    );
  }
}
