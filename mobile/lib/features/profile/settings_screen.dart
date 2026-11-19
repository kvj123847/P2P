import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sessionReminders = true;
  bool _chatAlerts = true;
  bool _courseUpdates = false;
  bool _profileVisible = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header('Account'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Role'),
                  trailing: DropdownButton<UserRole>(
                    value: state.role == UserRole.mentor ? UserRole.learner : state.role,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: UserRole.learner, child: Text('Learner')),
                      DropdownMenuItem(value: UserRole.tutor, child: Text('Tutor')),
                      DropdownMenuItem(value: UserRole.both, child: Text('Both')),
                    ],
                    onChanged: (r) {
                      if (r == null) return;
                      AppScope.read(context).setRole(r);
                      showSnack(context, 'Role changed to ${r.label}');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Age tier'),
                  subtitle: const Text('Changing tier requires re-verification'),
                  trailing: Text(state.tier.short,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _header('Notifications'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Session reminders'),
                  value: _sessionReminders,
                  onChanged: (v) => setState(() => _sessionReminders = v),
                ),
                SwitchListTile(
                  title: const Text('Chat messages'),
                  value: _chatAlerts,
                  onChanged: (v) => setState(() => _chatAlerts = v),
                ),
                SwitchListTile(
                  title: const Text('Course updates'),
                  value: _courseUpdates,
                  onChanged: (v) => setState(() => _courseUpdates = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _header('Privacy & Safety'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show my profile in search'),
                  value: _profileVisible,
                  onChanged: (v) => setState(() => _profileVisible = v),
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Blocked users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showSnack(context, 'No blocked users'),
                ),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: const Text('Community guidelines'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showSnack(context, 'Opens guidelines page'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _header('About'),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learn Share Grow', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Version 1.0.0 (frontend prototype)',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700)),
      );
}
