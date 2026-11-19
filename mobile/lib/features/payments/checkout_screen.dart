import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../state/app_state.dart';
import 'payment_success_screen.dart';

/// Generic checkout used for both course purchases and session bookings.
///
/// NOTE: Real payments must go through a backend + payment provider
/// (Razorpay / Stripe). Never keep payment secrets inside the Flutter app.
class CheckoutScreen extends StatefulWidget {
  final String itemTitle;
  final String itemSubtitle;
  final double amount;
  final IconData icon;
  final Future<String?> Function(String method) onPaid;
  final String successTitle;
  final String successMessage;
  final WidgetBuilder? afterSuccess;
  final String? afterSuccessLabel;

  const CheckoutScreen({
    super.key,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.amount,
    required this.icon,
    required this.onPaid,
    required this.successTitle,
    required this.successMessage,
    this.afterSuccess,
    this.afterSuccessLabel,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'UPI';
  bool _processing = false;
  final _coupon = TextEditingController();
  double _discount = 0;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  double get _total => (widget.amount - _discount).clamp(0, double.infinity).toDouble();

  void _applyCoupon() {
    if (_coupon.text.trim().toUpperCase() == 'PEER10') {
      setState(() => _discount = (widget.amount * 0.1).roundToDouble());
      showSnack(context, 'Coupon applied: 10% off');
    } else {
      setState(() => _discount = 0);
      showSnack(context, 'Invalid coupon. Try PEER10');
    }
  }

  Future<void> _pay() async {
    final state = AppScope.read(context);
    if (_method == 'Wallet' && state.walletBalance < _total) {
      showSnack(context, 'Not enough wallet balance');
      return;
    }
    setState(() => _processing = true);
    // Simulate the payment gateway.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final error = await widget.onPaid(_method);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error);
      setState(() => _processing = false);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          title: widget.successTitle,
          message: '${widget.successMessage}\n\nPaid ${Fmt.money(_total)} via $_method',
          nextBuilder: widget.afterSuccess,
          nextLabel: widget.afterSuccessLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final methods = [
      ('UPI', 'Google Pay, PhonePe, Paytm', Icons.qr_code_2),
      ('Card', 'Debit / Credit card', Icons.credit_card),
      ('Net Banking', 'All major banks', Icons.account_balance),
      ('Wallet', 'Balance: â‚¹${state.walletBalance.toStringAsFixed(0)}',
          Icons.account_balance_wallet),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.itemTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(widget.itemSubtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Coupon'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coupon,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter code (try PEER10)',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: OutlinedButton(onPressed: _applyCoupon, child: const Text('Apply')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Payment method'),
          for (final m in methods) ...[
            _MethodTile(
              title: m.$1,
              subtitle: m.$2,
              icon: m.$3,
              selected: _method == m.$1,
              onTap: () => setState(() => _method = m.$1),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          const SectionHeader(title: 'Price details'),
          AppCard(
            child: Column(
              children: [
                InfoRow(label: 'Price', value: Fmt.money(widget.amount)),
                if (_discount > 0)
                  InfoRow(label: 'Coupon discount', value: '- â‚¹${_discount.toStringAsFixed(0)}'),
                const InfoRow(label: 'Platform fee', value: 'â‚¹0 (student offer)'),
                const Divider(height: 20),
                InfoRow(label: 'Total', value: 'â‚¹${_total.toStringAsFixed(0)}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text('Payments are processed securely by the payment gateway.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: PrimaryButton(
          label: 'PAY â‚¹${_total.toStringAsFixed(0)}',
          loading: _processing,
          onPressed: _pay,
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
