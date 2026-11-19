import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../payments/checkout_screen.dart';
import '../payments/payment_success_screen.dart';

class BookingScreen extends StatefulWidget {
  final Tutor tutor;

  const BookingScreen({super.key, required this.tutor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  SessionType _type = SessionType.oneToOne;
  int _dayOffset = 0;
  String? _slot;
  int _minutes = 60;
  final _topic = TextEditingController();

  static const _slots = ['9:00 AM', '11:00 AM', '2:00 PM', '4:00 PM', '6:00 PM', '8:00 PM'];

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  double get _price {
    final perHour = widget.tutor.pricePerHour;
    final base = perHour * _minutes / 60;
    // Group sessions are cheaper per learner.
    return _type == SessionType.group ? (base * 0.4).roundToDouble() : base.roundToDouble();
  }

  DateTime get _selectedDateTime {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: _dayOffset));
    final parts = _slot!.split(RegExp(r'[: ]'));
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (parts[2] == 'PM' && hour != 12) hour += 12;
    return day.add(Duration(hours: hour, minutes: minute));
  }

  void _confirm() {
    final state = AppScope.read(context);
    final when = _selectedDateTime;
    final tutor = widget.tutor;

    void book(String method) => state.bookSession(
          tutor: tutor,
          when: when,
          minutes: _minutes,
          type: _type,
          topic: _topic.text.trim(),
          price: _price,
          method: method,
        );

    final summary = '${_type == SessionType.group ? 'Group' : '1:1'} session â€¢ '
        '$_minutes min\n${Fmt.dateTime(when)}';

    if (_price == 0) {
      book('Free');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            title: 'Session Booked!',
            message: 'Your free session with ${tutor.name} is confirmed.\n$summary',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          itemTitle: 'Session with ${tutor.name}',
          itemSubtitle: summary,
          amount: _price,
          icon: Icons.videocam_rounded,
          onPaid: (method) async {
            book(method);
            return null;
          },
          successTitle: 'Session Booked!',
          successMessage: 'Your session with ${tutor.name} is confirmed.\n$summary',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AppCard(
            child: Row(
              children: [
                InitialsAvatar(name: widget.tutor.name, color: widget.tutor.avatarColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tutor.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(widget.tutor.subjects.join(', '),
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Session type'),
          SegmentedButton<SessionType>(
            segments: const [
              ButtonSegment(
                  value: SessionType.oneToOne,
                  label: Text('One-to-one'),
                  icon: Icon(Icons.person)),
              ButtonSegment(
                  value: SessionType.group, label: Text('Group'), icon: Icon(Icons.groups)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Select date'),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final d = now.add(Duration(days: i));
                final sel = i == _dayOffset;
                return GestureDetector(
                  onTap: () => setState(() => _dayOffset = i),
                  child: Container(
                    width: 62,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(i == 0 ? 'Today' : Fmt.weekday(d),
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white70 : AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: sel ? Colors.white : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Select time'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots.map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _slot == s,
                onSelected: (_) => setState(() => _slot = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Duration'),
          Wrap(
            spacing: 8,
            children: [30, 45, 60, 90].map((m) {
              return ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          CustomTextField(
            controller: _topic,
            label: 'What do you need help with? (optional)',
            hint: 'e.g. Integration by parts, Module 3 problems',
            maxLines: 2,
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                Text(Fmt.money(_price),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: PrimaryButton(
                label: _price == 0 ? 'CONFIRM BOOKING' : 'CONTINUE TO PAY',
                onPressed: _slot == null ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
