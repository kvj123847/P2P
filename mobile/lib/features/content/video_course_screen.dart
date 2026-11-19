import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Recorded video course player.
///
/// The player area is a simulated player so the app runs with no packages.
/// To play real videos, add `video_player` and replace [_PlayerArea] with
/// `AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))`.
class VideoCourseScreen extends StatefulWidget {
  final Course course;
  final int startLesson;

  const VideoCourseScreen({super.key, required this.course, this.startLesson = 0});

  @override
  State<VideoCourseScreen> createState() => _VideoCourseScreenState();
}

class _VideoCourseScreenState extends State<VideoCourseScreen> {
  late int _index = widget.startLesson;
  bool _playing = false;
  double _position = 0; // seconds
  double _speed = 1.0;
  Timer? _timer;

  double get _length {
    final parts = widget.course.lessons[_index].duration.split(':');
    if (parts.length != 2) return 600;
    return (int.tryParse(parts[0]) ?? 10) * 60.0 + (int.tryParse(parts[1]) ?? 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _timer?.cancel();
    if (_playing) {
      // Fast-forward 20x so the demo finishes a lesson quickly.
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        setState(() {
          _position += 5 * _speed;
          if (_position >= _length) {
            _position = _length;
            _playing = false;
            _timer?.cancel();
            AppScope.read(context).markLessonDone(widget.course, _index);
          }
        });
      });
    }
  }

  void _select(int i) {
    final state = AppScope.read(context);
    if (!state.isEnrolled(widget.course) && i > 0) {
      showSnack(context, 'Enroll to unlock this lesson');
      return;
    }
    _timer?.cancel();
    setState(() {
      _index = i;
      _position = 0;
      _playing = false;
    });
  }

  String _fmt(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s.toInt() % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lessons = widget.course.lessons;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          _PlayerArea(
            course: widget.course,
            playing: _playing,
            position: _position,
            length: _length,
            speed: _speed,
            onPlay: _togglePlay,
            onSeek: (v) => setState(() => _position = v),
            onSpeed: (v) => setState(() => _speed = v),
            label: '${_fmt(_position)} / ${_fmt(_length)}',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Lesson ${_index + 1}: ${lessons[_index].title}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('By ${widget.course.tutorName}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showSnack(context, 'Lesson notes downloaded (demo)'),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Notes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showSnack(context, 'Ask a doubt from the Chat tab'),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Ask doubt'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Lessons',
                  action: '${(state.progressOf(widget.course) * 100).round()}% done',
                ),
                for (var i = 0; i < lessons.length; i++)
                  Card(
                    elevation: 0,
                    color: i == _index ? AppColors.primaryLight : Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      onTap: () => _select(i),
                      leading: Icon(
                        state.isLessonDone(widget.course, i)
                            ? Icons.check_circle
                            : (i == _index && _playing
                                ? Icons.equalizer
                                : Icons.play_circle_outline),
                        color: state.isLessonDone(widget.course, i)
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      title: Text(lessons[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(lessons[i].duration),
                      trailing: (!state.isEnrolled(widget.course) && i > 0)
                          ? const Icon(Icons.lock_outline)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  final Course course;
  final bool playing;
  final double position;
  final double length;
  final double speed;
  final VoidCallback onPlay;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeed;
  final String label;

  const _PlayerArea({
    required this.course,
    required this.playing,
    required this.position,
    required this.length,
    required this.speed,
    required this.onPlay,
    required this.onSeek,
    required this.onSpeed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, course.color.withAlpha(140)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(course.icon, size: 80, color: Colors.white.withAlpha(40)),
            ),
            Center(
              child: IconButton.filled(
                iconSize: 40,
                style: IconButton.styleFrom(backgroundColor: Colors.white.withAlpha(50)),
                onPressed: onPlay,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              child: Row(
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: position.clamp(0, length),
                      max: length,
                      onChanged: onSeek,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  PopupMenuButton<double>(
                    initialValue: speed,
                    onSelected: onSpeed,
                    itemBuilder: (_) => [0.5, 1.0, 1.25, 1.5, 2.0]
                        .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                        .toList(),
                    child: Text('${speed}x',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  IconButton(
                    onPressed: () => showSnack(context, 'Full screen (demo)'),
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
