import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Learner wallet (in-app credits) + payment history.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Payments')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet credits', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('â‚¹${state.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final amt in [100, 250, 500])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('+ â‚¹$amt'),
                          onPressed: () {
                            AppScope.read(context).topUpWallet(amt.toDouble());
                            showSnack(context, 'â‚¹$amt added to wallet');
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Transaction history'),
          if (state.transactions.isEmpty)
            const EmptyState(
                icon: Icons.receipt_long, title: 'No payments yet', message: '')
          else
            for (final t in state.transactions) ...[
              TransactionTile(tx: t),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final PaymentTransaction tx;

  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = tx.isCredit ? AppColors.success : AppColors.error;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(25),
            child: Icon(tx.isCredit ? Icons.south_west : Icons.north_east, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${Fmt.date(tx.date)} â€¢ ${tx.method}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'} â‚¹${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
