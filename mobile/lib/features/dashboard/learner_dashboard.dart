import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../mock_data/mock_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../content/course_details_screen.dart';
import '../content/my_learning_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sessions/live_video_screen.dart';
import '../tutors/tutor_profile_screen.dart';
import 'main_shell.dart';

class LearnerDashboard extends StatelessWidget {
  final ValueChanged<int> onTab;
  final void Function({String? subject, int tab}) onExplore;

  const LearnerDashboard({super.key, required this.onTab, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final upcoming = state.upcomingSessions;
    final enrolled = state.enrolledCourses;
    final courses = state.visibleCourses;
    final tutors = state.visibleTutors;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          DashboardHeader(
            greeting: 'Hi, ${state.name}! ðŸ‘‹',
            subtitle: 'What do you want to learn today?',
          ),
          const SizedBox(height: 18),
          const ModeToggle(),
          // Search bar (opens Explore)
          GestureDetector(
            onTap: () => onExplore(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Text('Search tutors, courses, subjects',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Quick Actions'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              QuickAction(
                icon: Icons.person_search_rounded,
                label: 'Find Tutors',
                color: AppColors.primary,
                onTap: () => onExplore(tab: 0),
              ),
              QuickAction(
                icon: Icons.video_call_rounded,
                label: 'Live Sessions',
                color: AppColors.success,
                onTap: () => onTab(2),
              ),
              QuickAction(
                icon: Icons.auto_stories_rounded,
                label: 'My Learning',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyLearningScreen())),
              ),
              QuickAction(
                icon: Icons.question_answer_rounded,
                label: 'Ask a Doubt',
                color: const Color(0xFFF97316),
                onTap: () => onTab(3),
              ),
            ],
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeader(title: 'Next Session', action: 'See all', onAction: () => onTab(2)),
            SessionCard(
              session: upcoming.first,
              onJoin: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LiveVideoScreen(session: upcoming.first)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionHeader(title: 'Popular Subjects'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(MockData.subjects[i]),
                onPressed: () => onExplore(subject: MockData.subjects[i], tab: 1),
              ),
            ),
          ),
          if (enrolled.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Continue Learning',
              action: 'See all',
              onAction: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const MyLearningScreen())),
            ),
            SizedBox(
              height: 268,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: enrolled.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => CourseCard(
                  course: enrolled[i],
                  progress: state.progressOf(enrolled[i]),
                  onTap: () => _openCourse(context, enrolled[i]),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SectionHeader(
              title: 'Recommended Courses',
              action: 'See all',
              onAction: () => onExplore(tab: 1)),
          SizedBox(
            height: 255,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => CourseCard(
                course: courses[i],
                onTap: () => _openCourse(context, courses[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Top Tutors', action: 'See all', onAction: () => onExplore()),
          for (final t in tutors.take(3)) ...[
            TutorCard(
              tutor: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: t)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  void _openCourse(BuildContext context, Course c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: c)),
    );
  }
}

/// Greeting row + notification bell. Shared by learner and tutor dashboards.
class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const DashboardHeader({super.key, required this.greeting, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        StatusChip(
          label: state.tier.short,
          color: state.tier == AgeTier.school ? const Color(0xFFF97316) : AppColors.primary,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Badge(
            isLabelVisible: state.unreadNotifications > 0,
            label: Text('${state.unreadNotifications}'),
            child: const Icon(Icons.notifications_none_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(22),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
