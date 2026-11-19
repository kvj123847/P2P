import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../dashboard/tutor_dashboard.dart';
import 'content_upload_screen.dart';

/// Tutor's submitted content grouped by review status.
class MyContentScreen extends StatelessWidget {
  const MyContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.mySubmissions;
    List<Submission> by(ReviewStatus s) => all.where((x) => x.status == s).toList();

    final tabs = [
      ('Pending', by(ReviewStatus.pending)),
      ('Approved', by(ReviewStatus.approved)),
      ('Rejected', by(ReviewStatus.rejected)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Content'),
          bottom: TabBar(
            tabs: [for (final t in tabs) Tab(text: '${t.$1} (${t.$2.length})')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ContentUploadScreen())),
          icon: const Icon(Icons.add),
          label: const Text('New course'),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs)
              t.$2.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open,
                      title: 'No ${t.$1.toLowerCase()} content',
                      message: 'Courses you submit for mentor review show up here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: t.$2.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => SubmissionTile(submission: t.$2[i]),
                    ),
          ],
        ),
      ),
    );
  }
}
