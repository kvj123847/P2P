import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../chat/chat_screen.dart';
import '../content/course_details_screen.dart';
import 'booking_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  final Tutor tutor;

  const TutorProfileScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final courses = state.coursesByTutor(tutor.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report',
            onPressed: () => showSnack(context, 'Report sent to mentors for review'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Center(
            child: InitialsAvatar(
                name: tutor.name, color: tutor.avatarColor, radius: 48, online: tutor.online),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(tutor.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(tutor.institution,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 6,
              children: [
                const StatusChip(
                    label: 'Mentor verified', color: AppColors.success, icon: Icons.verified),
                StatusChip(
                    label: tutor.online ? 'Online now' : 'Offline',
                    color: tutor.online ? AppColors.success : AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat('${tutor.rating}', 'Rating'),
              _stat('${tutor.reviews}', 'Reviews'),
              _stat('${tutor.sessionsTaught}', 'Sessions'),
              _stat(tutor.pricePerHour == 0 ? 'Free' : 'â‚¹${tutor.pricePerHour.toInt()}',
                  'Per hour'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'About'),
          Text(tutor.bio, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Subjects'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tutor.subjects
                .map((s) => Chip(label: Text(s)))
                .toList(),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Availability'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['Mon 6-8 PM', 'Wed 6-8 PM', 'Sat 10 AM-1 PM', 'Sun 4-6 PM']
                .map((s) => Chip(
                      avatar: const Icon(Icons.schedule, size: 16),
                      label: Text(s),
                    ))
                .toList(),
          ),
          if (courses.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Courses'),
            for (final c in courses) ...[
              CourseListTile(
                course: c,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: c)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Reviews'),
          ..._reviews(),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(56, 52),
                ),
                onPressed: () {
                  final thread = AppScope.read(context).openChatWith(tutor);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(thread: thread)),
                  );
                },
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'BOOK SESSION',
                icon: Icons.event_available,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingScreen(tutor: tutor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _reviews() {
    const reviews = [
      ('Nikhil', 5, 'Explained everything so clearly. Booked again!'),
      ('Anjali', 5, 'Very patient and helpful with my doubts.'),
      ('Rohan', 4, 'Good session, slightly fast in the beginning.'),
    ];
    return [
      for (final r in reviews)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: r.$1, color: AppColors.secondary, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < r.$2 ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.$3, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
