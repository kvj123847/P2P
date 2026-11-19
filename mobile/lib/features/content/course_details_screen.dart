import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../payments/checkout_screen.dart';
import '../tutors/tutor_profile_screen.dart';
import 'course_reader_screen.dart';
import 'video_course_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  static Widget playerFor(Course c, {int lesson = 0}) => c.type == CourseType.video
      ? VideoCourseScreen(course: c, startLesson: lesson)
      : CourseReaderScreen(course: c, startLesson: lesson);

  void _open(BuildContext context, {int lesson = 0}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => playerFor(course, lesson: lesson)));
  }

  void _buy(BuildContext context) {
    final state = AppScope.read(context);
    if (course.isFree) {
      state.enroll(course);
      showSnack(context, 'Enrolled! Enjoy learning.');
      _open(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          itemTitle: course.title,
          itemSubtitle: 'By ${course.tutorName} â€¢ ${course.lessons.length} lessons',
          amount: course.price,
          icon: course.icon,
          onPaid: (method) => state.enroll(course, method: method),
          successTitle: 'Purchase Successful!',
          successMessage: 'You now have lifetime access to "${course.title}".',
          afterSuccess: (_) => playerFor(course),
          afterSuccessLabel: 'START LEARNING',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final enrolled = state.isEnrolled(course);
    final tutor = state.tutorById(course.tutorId);
    final progress = state.progressOf(course);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showSnack(context, 'Share link copied'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          CourseThumbnail(course: course, height: 180, radius: 20),
          const SizedBox(height: 18),
          Wrap(
            spacing: 6,
            children: [
              StatusChip(label: course.subject, color: AppColors.primary),
              StatusChip(
                label: course.type == CourseType.video ? 'Video course' : 'Text course',
                color: const Color(0xFF7C3AED),
              ),
              const StatusChip(
                  label: 'Mentor approved', color: AppColors.success, icon: Icons.verified),
            ],
          ),
          const SizedBox(height: 12),
          Text(course.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              Text(course.rating == 0 ? 'New' : course.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${course.students} students',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.list_alt, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${course.lessons.length} lessons',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 18),
          AppCard(
            onTap: tutor == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: tutor)),
                    ),
            child: Row(
              children: [
                InitialsAvatar(
                    name: course.tutorName, color: tutor?.avatarColor ?? AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.tutorName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(tutor?.institution ?? 'Peer tutor',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (tutor != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
          if (enrolled) ...[
            const SizedBox(height: 18),
            Text('Your progress: ${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: progress, minHeight: 8, backgroundColor: AppColors.border),
            ),
          ],
          const SizedBox(height: 22),
          const SectionHeader(title: 'About this course'),
          Text(course.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Course content'),
          for (var i = 0; i < course.lessons.length; i++)
            _LessonRow(
              index: i,
              lesson: course.lessons[i],
              isVideo: course.type == CourseType.video,
              locked: !enrolled && i > 0,
              done: state.isLessonDone(course, i),
              preview: !enrolled && i == 0,
              onTap: () {
                if (enrolled || i == 0) {
                  _open(context, lesson: i);
                } else {
                  showSnack(context, 'Enroll to unlock this lesson');
                }
              },
            ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: enrolled
            ? PrimaryButton(
                label: progress == 0 ? 'START LEARNING' : 'CONTINUE LEARNING',
                icon: Icons.play_arrow_rounded,
                onPressed: () => _open(context),
              )
            : Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price', style: TextStyle(color: AppColors.textSecondary)),
                      Text(Fmt.money(course.price),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: course.isFree ? AppColors.success : AppColors.textPrimary,
                          )),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: PrimaryButton(
                      label: course.isFree ? 'ENROLL FREE' : 'BUY NOW',
                      onPressed: () => _buy(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final int index;
  final Lesson lesson;
  final bool isVideo;
  final bool locked;
  final bool done;
  final bool preview;
  final VoidCallback onTap;

  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.isVideo,
    required this.locked,
    required this.done,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: done ? AppColors.success : AppColors.primaryLight,
              child: done
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text('${index + 1}',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(lesson.duration,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (preview)
              const StatusChip(label: 'Preview', color: AppColors.success)
            else
              Icon(
                locked
                    ? Icons.lock_outline
                    : (isVideo ? Icons.play_circle_outline : Icons.article_outlined),
                color: locked ? AppColors.textSecondary : AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
