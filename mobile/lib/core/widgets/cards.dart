import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';

/// Coloured banner used in place of a course thumbnail image.
class CourseThumbnail extends StatelessWidget {
  final Course course;
  final double height;
  final double radius;

  const CourseThumbnail({
    super.key,
    required this.course,
    this.height = 110,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [course.color, course.color.withAlpha(170)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(child: Icon(course.icon, color: Colors.white, size: height * 0.4)),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    course.type == CourseType.video
                        ? Icons.play_circle_fill
                        : Icons.article,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    course.type == CourseType.video ? 'Video' : 'Text',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
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

/// Vertical course card for horizontal carousels.
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final double? progress;
  final double width;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.progress,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseThumbnail(course: course),
            const SizedBox(height: 10),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text('By ${course.tutorName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 4),
              Text('${(progress! * 100).round()}% complete',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ] else
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  Text(course.rating == 0 ? 'New' : course.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('  â€¢  ${course.lessons.length} lessons',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text(
                    Fmt.money(course.price),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: course.isFree ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal list-row course card.
class CourseListTile extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseListTile({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: 90, child: CourseThumbnail(course: course, height: 80)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${course.tutorName} â€¢ ${course.subject}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    Text(course.rating == 0 ? 'New' : course.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text(
                      Fmt.money(course.price),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: course.isFree ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tutor row card.
class TutorCard extends StatelessWidget {
  final Tutor tutor;
  final VoidCallback onTap;

  const TutorCard({super.key, required this.tutor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          InitialsAvatar(
              name: tutor.name, color: tutor.avatarColor, radius: 28, online: tutor.online),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutor.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(tutor.institution,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tutor.subjects
                      .map((s) => StatusChip(label: s, color: AppColors.primary))
                      .toList(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  Text(tutor.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tutor.pricePerHour == 0 ? 'Free' : 'â‚¹${tutor.pricePerHour.toInt()}/hr',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: tutor.pricePerHour == 0 ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Session row card.
class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const SessionCard({super.key, required this.session, this.onJoin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGroup = session.type == SessionType.group;
    final upcoming = session.status == SessionStatus.upcoming;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGroup ? AppColors.tutor : AppColors.learner,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGroup ? Icons.groups_rounded : Icons.person_rounded,
                  color: isGroup ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('with ${session.tutorName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              StatusChip(
                label: isGroup ? 'Group' : '1:1',
                color: isGroup ? AppColors.success : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${Fmt.dateTime(session.dateTime)} â€¢ ${session.durationMinutes} min',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              if (upcoming && onJoin != null)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Join', style: TextStyle(fontSize: 14)),
                  ),
                )
              else if (!upcoming)
                StatusChip(
                  label: session.status == SessionStatus.completed ? 'Completed' : 'Cancelled',
                  color: session.status == SessionStatus.completed
                      ? AppColors.textSecondary
                      : AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
