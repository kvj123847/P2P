import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../mock_data/mock_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Tutor creates a text / video course and submits it for mentor review.
class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _lessonCtrl = TextEditingController();
  CourseType _type = CourseType.video;
  String _subject = MockData.subjects.first;
  final List<String> _lessons = [];
  final List<String> _files = [];
  bool _thumbnail = false;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _lessonCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addLesson() {
    final t = _lessonCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _lessons.add(t);
      _files.add(_type == CourseType.video
          ? 'lesson_${_lessons.length}.mp4'
          : 'chapter_${_lessons.length}.pdf');
    });
    _lessonCtrl.clear();
  }

  Future<void> _submit({required bool draft}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_lessons.isEmpty) {
      showSnack(context, 'Add at least one lesson');
      return;
    }
    if (draft) {
      showSnack(context, 'Saved as draft');
      Navigator.pop(context);
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    AppScope.read(context).submitForReview(
      title: _title.text.trim(),
      subject: _subject,
      type: _type,
      price: double.tryParse(_price.text) ?? 0,
      description: _desc.text.trim(),
      lessonTitles: List.of(_lessons),
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_top, color: AppColors.warning, size: 40),
        title: const Text('Submitted for review'),
        content: const Text(
          'A mentor will review your course for accuracy and quality. '
          'You\'ll be notified when it is approved or if changes are needed.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Workflow hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mentor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF7C3AED)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Create â†’ Submit â†’ Mentor review â†’ Live. '
                      'Only approved content is visible to learners.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Course type'),
            SegmentedButton<CourseType>(
              segments: const [
                ButtonSegment(
                    value: CourseType.video,
                    label: Text('Recorded video'),
                    icon: Icon(Icons.videocam_outlined)),
                ButtonSegment(
                    value: CourseType.text,
                    label: Text('Text / notes'),
                    icon: Icon(Icons.article_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _title,
              label: 'Course title',
              hint: 'e.g. Data Structures in C',
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Title should be at least 5 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _desc,
              label: 'Description',
              hint: 'What will learners be able to do after this course?',
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().length < 20) ? 'Write at least 20 characters' : null,
            ),
            const SizedBox(height: 16),
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _subject,
              items: MockData.subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v ?? _subject),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _price,
              label: 'Price (â‚¹) - enter 0 for a free course',
              hint: '0',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Thumbnail'),
            AppCard(
              color: _thumbnail ? AppColors.tutor : null,
              onTap: () {
                // Replace with image_picker.
                setState(() => _thumbnail = true);
              },
              child: Row(
                children: [
                  Icon(_thumbnail ? Icons.image : Icons.add_photo_alternate_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(_thumbnail ? 'thumbnail.png selected' : 'Upload a cover image'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: _type == CourseType.video ? 'Video lessons' : 'Chapters'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lessonCtrl,
                    onSubmitted: (_) => _addLesson(),
                    decoration: InputDecoration(
                      hintText: _type == CourseType.video
                          ? 'Lesson title (video will be attached)'
                          : 'Chapter title (PDF / text will be attached)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addLesson, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 10),
            if (_lessons.isEmpty)
              const Text('No lessons added yet.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                onReorder: (oldI, newI) {
                  setState(() {
                    if (newI > oldI) newI -= 1;
                    _lessons.insert(newI, _lessons.removeAt(oldI));
                    _files.insert(newI, _files.removeAt(oldI));
                  });
                },
                children: [
                  for (var i = 0; i < _lessons.length; i++)
                    Card(
                      key: ValueKey('${_lessons[i]}_$i'),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                        title: Text(_lessons[i]),
                        subtitle: Text(_files[i],
                            style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => setState(() {
                            _lessons.removeAt(i);
                            _files.removeAt(i);
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'SUBMIT FOR REVIEW',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: () => _submit(draft: false),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _submit(draft: true),
              child: const Text('Save as draft'),
            ),
          ],
        ),
      ),
    );
  }
}
