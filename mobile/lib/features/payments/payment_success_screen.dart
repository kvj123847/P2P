import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String title;
  final String message;
  final WidgetBuilder? nextBuilder;
  final String? nextLabel;

  const PaymentSuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.nextBuilder,
    this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 70, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 28),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const Spacer(),
              if (nextBuilder != null) ...[
                PrimaryButton(
                  label: nextLabel ?? 'CONTINUE',
                  onPressed: () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: nextBuilder!)),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
