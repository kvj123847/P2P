import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../authentication/login_screen.dart';
import 'content_review_screen.dart';

/// Mentor panel: review queue for tutor-submitted courses and sessions.
class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pending = state.pendingReviews;
    final reviewed = state.reviewedSubmissions;
    final approved = reviewed.where((s) => s.status == ReviewStatus.approved).length;
    final canGoBack = Navigator.of(context).canPop();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: canGoBack,
          title: const Text('Mentor Panel'),
          actions: [
            if (!canGoBack)
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  AppScope.read(context).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: 'Review queue (${pending.length})'),
            Tab(text: 'Reviewed (${reviewed.length})'),
          ]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  _stat('${pending.length}', 'Pending', AppColors.warning),
                  const SizedBox(width: 10),
                  _stat('$approved', 'Approved', AppColors.success),
                  const SizedBox(width: 10),
                  _stat('${reviewed.length - approved}', 'Rejected', AppColors.error),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(context, pending, 'Queue is clear ðŸŽ‰',
                      'New tutor submissions will appear here.'),
                  _list(context, reviewed, 'Nothing reviewed yet',
                      'Approved and rejected content appears here.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Submission> items, String title, String msg) {
    if (items.isEmpty) {
      return EmptyState(icon: Icons.fact_check_outlined, title: title, message: msg);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = items[i];
        return AppCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentReviewScreen(submission: s)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mentor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  s.type == CourseType.video
                      ? Icons.play_circle_outline
                      : Icons.article_outlined,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('by ${s.tutorName} â€¢ ${s.tier.short} â€¢ ${Fmt.ago(s.submittedAt)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(label: s.status.label, color: s.status.color),
            ],
          ),
        );
      },
    );
  }
}
