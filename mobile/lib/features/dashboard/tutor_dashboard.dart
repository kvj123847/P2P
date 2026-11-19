import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../content/content_upload_screen.dart';
import '../content/my_content_screen.dart';
import '../payments/tutor_earnings_screen.dart';
import '../sessions/create_session_sheet.dart';
import '../sessions/group_session_screen.dart';
import '../sessions/live_video_screen.dart';
import 'learner_dashboard.dart';
import 'main_shell.dart';

class TutorDashboard extends StatelessWidget {
  final ValueChanged<int> onTab;

  const TutorDashboard({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final upcoming = state.upcomingSessions;
    final mine = state.mySubmissions;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          DashboardHeader(
            greeting: 'Hi, ${state.name}! ðŸŽ“',
            subtitle: 'Ready to teach today?',
          ),
          const SizedBox(height: 18),
          const ModeToggle(),
          // Earnings banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available balance',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        'â‚¹${state.tutorBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text('+ â‚¹720 this week',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TutorEarningsScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text('Earnings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Stat(value: '4.8', label: 'Rating', icon: Icons.star_rounded)),
              SizedBox(width: 10),
              Expanded(child: _Stat(value: '56', label: 'Learners', icon: Icons.people)),
              SizedBox(width: 10),
              Expanded(child: _Stat(value: '32', label: 'Sessions', icon: Icons.videocam)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Teaching Tools'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              QuickAction(
                icon: Icons.add_box_rounded,
                label: 'Create Course',
                color: AppColors.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContentUploadScreen())),
              ),
              QuickAction(
                icon: Icons.event_rounded,
                label: 'Schedule Session',
                color: AppColors.success,
                onTap: () => showCreateSessionSheet(context),
              ),
              QuickAction(
                icon: Icons.folder_copy_rounded,
                label: 'My Content',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyContentScreen())),
              ),
              QuickAction(
                icon: Icons.forum_rounded,
                label: 'Learner Doubts',
                color: const Color(0xFFF97316),
                onTap: () => onTab(3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
              title: 'Upcoming Sessions', action: 'See all', onAction: () => onTab(2)),
          if (upcoming.isEmpty)
            const AppCard(child: Text('No sessions scheduled yet.'))
          else
            for (final s in upcoming.take(3)) ...[
              SessionCard(
                session: s,
                onJoin: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => s.type == SessionType.group
                        ? GroupSessionScreen(session: s)
                        : LiveVideoScreen(session: s),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          SectionHeader(
            title: 'Review Status',
            action: 'See all',
            onAction: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MyContentScreen())),
          ),
          if (mine.isEmpty)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                        'Create a course and submit it. A mentor reviews it before it goes live.'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContentUploadScreen())),
                    child: const Text('Create'),
                  ),
                ],
              ),
            )
          else
            for (final s in mine.take(3)) ...[
              SubmissionTile(submission: s),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A tutor's submitted course with its mentor-review status.
class SubmissionTile extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;

  const SubmissionTile({super.key, required this.submission, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = submission;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.type == CourseType.video
                    ? Icons.play_circle_outline
                    : Icons.article_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              StatusChip(label: s.status.label, color: s.status.color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.subject} â€¢ ${s.lessonTitles.length} lessons â€¢ ${Fmt.money(s.price)} â€¢ '
            'submitted ${Fmt.ago(s.submittedAt)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (s.feedback != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: s.status.color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Mentor feedback: ${s.feedback}',
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
