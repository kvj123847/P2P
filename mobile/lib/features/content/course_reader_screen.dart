import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Reader for text-based courses (chapters, progress, font size).
class CourseReaderScreen extends StatefulWidget {
  final Course course;
  final int startLesson;

  const CourseReaderScreen({super.key, required this.course, this.startLesson = 0});

  @override
  State<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends State<CourseReaderScreen> {
  late int _index = widget.startLesson;
  double _fontSize = 16;

  bool get _canAccess {
    final state = AppScope.read(context);
    return state.isEnrolled(widget.course) || _index == 0;
  }

  void _go(int i) {
    final state = AppScope.read(context);
    if (!state.isEnrolled(widget.course) && i > 0) {
      showSnack(context, 'Enroll to unlock the next chapters');
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lessons = widget.course.lessons;
    final lesson = lessons[_index];
    final done = state.isLessonDone(widget.course, _index);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12, 26)),
          ),
          IconButton(
            tooltip: 'Larger text',
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12, 26)),
          ),
          IconButton(
            tooltip: 'Chapters',
            icon: const Icon(Icons.list),
            onPressed: () => _showChapters(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + 1) / lessons.length,
            backgroundColor: AppColors.border,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        children: [
          Text('Chapter ${_index + 1} of ${lessons.length} â€¢ ${lesson.duration}',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(lesson.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          if (_canAccess)
            Text(
              lesson.body.isEmpty ? 'Content coming soon.' : lesson.body,
              style: TextStyle(fontSize: _fontSize, height: 1.7),
            )
          else
            const EmptyState(
                icon: Icons.lock, title: 'Locked', message: 'Enroll to read this chapter.'),
          const SizedBox(height: 28),
          if (_canAccess)
            OutlinedButton.icon(
              onPressed: done
                  ? null
                  : () {
                      state.markLessonDone(widget.course, _index);
                      showSnack(context, 'Chapter marked as complete');
                    },
              icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(done ? 'Completed' : 'Mark as complete'),
            ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _index == 0 ? null : () => _go(_index - 1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _index == lessons.length - 1 ? null : () => _go(_index + 1),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Next'), Icon(Icons.chevron_right)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapters(BuildContext context) {
    final state = AppScope.read(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (var i = 0; i < widget.course.lessons.length; i++)
            ListTile(
              leading: Icon(
                state.isLessonDone(widget.course, i)
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: state.isLessonDone(widget.course, i)
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              title: Text(widget.course.lessons[i].title),
              selected: i == _index,
              onTap: () {
                Navigator.pop(ctx);
                _go(i);
              },
            ),
        ],
      ),
    );
  }
}
