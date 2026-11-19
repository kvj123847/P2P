import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Mentor opens a submission, checks it against a checklist and
/// approves it or rejects it with feedback.
class ContentReviewScreen extends StatefulWidget {
  final Submission submission;

  const ContentReviewScreen({super.key, required this.submission});

  @override
  State<ContentReviewScreen> createState() => _ContentReviewScreenState();
}

class _ContentReviewScreenState extends State<ContentReviewScreen> {
  final _feedback = TextEditingController();
  final Map<String, bool> _checks = {
    'Content is accurate': false,
    'Age-appropriate for the selected tier': false,
    'Clear audio / readable text': false,
    'No plagiarism or copyrighted material': false,
    'Price is reasonable': false,
  };

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  void _decide(bool approve) {
    if (!approve && _feedback.text.trim().isEmpty) {
      showSnack(context, 'Please write feedback explaining what to change');
      return;
    }
    if (approve && _checks.values.any((v) => !v)) {
      showSnack(context, 'Complete the review checklist before approving');
      return;
    }
    AppScope.read(context).reviewSubmission(
      widget.submission,
      approve: approve,
      feedback: _feedback.text,
    );
    showSnack(context, approve ? 'Approved - content is now live' : 'Sent back to tutor');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final reviewed = s.status != ReviewStatus.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Content')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(label: s.status.label, color: s.status.color),
              StatusChip(
                  label: s.type == CourseType.video ? 'Video' : 'Text',
                  color: const Color(0xFF7C3AED)),
              StatusChip(label: s.tier.label, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('by ${s.tutorName} â€¢ ${s.subject} â€¢ ${Fmt.money(s.price)}',
              style: const TextStyle(color: AppColors.textSecondary)),
          Text('Submitted ${Fmt.dateTime(s.submittedAt)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Description'),
          Text(s.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          SectionHeader(title: 'Lessons (${s.lessonTitles.length})'),
          for (var i = 0; i < s.lessonTitles.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => showSnack(context, 'Preview "${s.lessonTitles[i]}" (demo)'),
                child: Row(
                  children: [
                    Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.lessonTitles[i])),
                    Icon(
                      s.type == CourseType.video ? Icons.play_arrow : Icons.visibility,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (reviewed)
            AppCard(
              color: s.status.color.withAlpha(20),
              child: Text('Feedback: ${s.feedback ?? '-'}'),
            )
          else ...[
            const SectionHeader(title: 'Review checklist'),
            for (final key in _checks.keys)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _checks[key],
                title: Text(key),
                onChanged: (v) => setState(() => _checks[key] = v ?? false),
              ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _feedback,
              label: 'Feedback for tutor',
              hint: 'Required when rejecting. Be specific and kind.',
              maxLines: 3,
            ),
          ],
        ],
      ),
      bottomSheet: reviewed
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () => _decide(false),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () => _decide(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
