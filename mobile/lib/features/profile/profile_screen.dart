import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../authentication/login_screen.dart';
import '../content/my_content_screen.dart';
import '../content/my_learning_screen.dart';
import '../mentor/mentor_dashboard.dart';
import '../notifications/notifications_screen.dart';
import '../payments/payment_history_screen.dart';
import '../payments/tutor_earnings_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                InitialsAvatar(name: state.name, color: AppColors.primary, radius: 42),
                const SizedBox(height: 12),
                Text(state.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                if (state.email.isNotEmpty)
                  Text(state.email, style: const TextStyle(color: AppColors.textSecondary)),
                if (state.institution.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(state.institution,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    StatusChip(label: state.role.label, color: AppColors.primary),
                    StatusChip(
                      label: state.tier.label,
                      color: state.tier == AgeTier.school
                          ? const Color(0xFFF97316)
                          : AppColors.success,
                      icon: Icons.verified_user,
                    ),
                  ],
                ),
                if (state.interests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: state.interests
                        .map((s) => StatusChip(label: s, color: AppColors.textSecondary))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _push(context, const EditProfileScreen()),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('${state.enrolledCourses.length}', 'Courses'),
              const SizedBox(width: 10),
              _stat('${state.pastSessions.length}', 'Sessions'),
              const SizedBox(width: 10),
              _stat('â‚¹${state.walletBalance.toStringAsFixed(0)}', 'Wallet'),
            ],
          ),
          const SizedBox(height: 20),
          _section('Learning'),
          _tile(context, Icons.auto_stories_outlined, 'My Learning',
              () => _push(context, const MyLearningScreen())),
          _tile(context, Icons.account_balance_wallet_outlined, 'Wallet & Payments',
              () => _push(context, const PaymentHistoryScreen())),
          if (state.role.canTeach) ...[
            const SizedBox(height: 12),
            _section('Teaching'),
            _tile(context, Icons.folder_copy_outlined, 'My Content & Reviews',
                () => _push(context, const MyContentScreen())),
            _tile(context, Icons.payments_outlined, 'Earnings & Payouts',
                () => _push(context, const TutorEarningsScreen())),
          ],
          const SizedBox(height: 12),
          _section('More'),
          _tile(context, Icons.notifications_none, 'Notifications',
              () => _push(context, const NotificationsScreen())),
          _tile(context, Icons.admin_panel_settings_outlined, 'Mentor Panel (demo)',
              () => _push(context, const MentorDashboard())),
          _tile(context, Icons.help_outline, 'Help & Support',
              () => showSnack(context, 'support@learnsharegrow.app')),
          _tile(context, Icons.logout, 'Logout', () {
            AppScope.read(context).logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700)),
      );

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.primary),
          title: Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
