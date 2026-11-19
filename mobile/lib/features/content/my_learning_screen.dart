import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'course_details_screen.dart';

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final courses = state.enrolledCourses;
    final inProgress = courses.where((c) => state.progressOf(c) < 1).toList();
    final completed = courses.where((c) => state.progressOf(c) >= 1).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Learning'),
          bottom: TabBar(tabs: [
            Tab(text: 'In progress (${inProgress.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ]),
        ),
        body: TabBarView(
          children: [
            _list(context, inProgress, 'No courses yet',
                'Browse the content library and enroll in a course.'),
            _list(context, completed, 'Nothing completed yet',
                'Finish all lessons in a course to see it here.'),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Course> courses, String title, String msg) {
    final state = AppScope.of(context);
    if (courses.isEmpty) {
      return EmptyState(icon: Icons.auto_stories, title: title, message: msg);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = courses[i];
        final p = state.progressOf(c);
        return AppCard(
          padding: const EdgeInsets.all(10),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: c)),
          ),
          child: Row(
            children: [
              SizedBox(width: 90, child: CourseThumbnail(course: c, height: 80)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(c.tutorName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: p,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: p >= 1 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(p * 100).round()}% complete',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
