import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../state/app_state.dart';
import 'payment_history_screen.dart';

class TutorEarningsScreen extends StatelessWidget {
  const TutorEarningsScreen({super.key});

  // Mock weekly earnings for the bar chart (Mon..Sun).
  static const _week = [120.0, 0.0, 260.0, 90.0, 180.0, 340.0, 210.0];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final maxV = _week.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available for payout', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('â‚¹${state.tutorBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(170, 44),
                  ),
                  onPressed: state.tutorBalance < 100 ? null : () => _payout(context),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Request payout'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Mini(label: 'This month', value: 'â‚¹3,460')),
              SizedBox(width: 10),
              Expanded(child: _Mini(label: 'Total earned', value: 'â‚¹12,980')),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'This week'),
          AppCard(
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_week.length, (i) {
                  final h = maxV == 0 ? 0.0 : _week[i] / maxV * 110;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(_week[i] == 0 ? '' : 'â‚¹${_week[i].toInt()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          height: h < 4 ? 4 : h,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: i == 5 ? AppColors.primary : AppColors.secondary.withAlpha(120),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_days[i],
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Transactions'),
          for (final t in state.earnings) ...[
            TransactionTile(tx: t),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          const Text(
            'Platform commission (10%) is already deducted from the amounts shown.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _payout(BuildContext context) {
    final state = AppScope.read(context);
    final amount = state.tutorBalance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request payout'),
        content: Text(
            'Transfer â‚¹${amount.toStringAsFixed(0)} to your linked bank account (XXXX 4321)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              state.requestPayout(amount);
              Navigator.pop(ctx);
              showSnack(context, 'Payout requested. Arrives in 2-3 working days.');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;

  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
