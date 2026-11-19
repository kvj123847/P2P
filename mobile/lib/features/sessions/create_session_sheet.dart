import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Bottom sheet for tutors to schedule a 1:1 slot or a group class.
Future<void> showCreateSessionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CreateSessionSheet(),
  );
}

class _CreateSessionSheet extends StatefulWidget {
  const _CreateSessionSheet();

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _title = TextEditingController();
  final _price = TextEditingController(text: '0');
  SessionType _type = SessionType.group;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _minutes = 60;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null && mounted) setState(() => _time = t);
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      showSnack(context, 'Please enter a session title');
      return;
    }
    final when = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    AppScope.read(context).createTeachingSession(
      title: _title.text.trim(),
      type: _type,
      when: when,
      minutes: _minutes,
      price: double.tryParse(_price.text) ?? 0,
    );
    Navigator.pop(context);
    showSnack(context, 'Session scheduled');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule a session',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            CustomTextField(
                controller: _title, hint: 'Session title', icon: Icons.title),
            const SizedBox(height: 14),
            SegmentedButton<SessionType>(
              segments: const [
                ButtonSegment(value: SessionType.oneToOne, label: Text('1:1')),
                ButtonSegment(value: SessionType.group, label: Text('Group class')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [30, 45, 60, 90]
                  .map((m) => ChoiceChip(
                        label: Text('$m min'),
                        selected: _minutes == m,
                        onSelected: (_) => setState(() => _minutes = m),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _price,
              hint: 'Price per learner (0 = free)',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'SCHEDULE', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
