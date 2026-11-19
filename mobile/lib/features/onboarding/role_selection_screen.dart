import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'age_verification_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 of 3')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepBar(step: 1),
              const SizedBox(height: 24),
              const Text('How do you want to use the app?',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('You can change your role later in Settings.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              SelectableCard(
                title: 'Learner',
                subtitle: 'Learn from other students',
                icon: Icons.menu_book_rounded,
                selected: _selected == UserRole.learner,
                onTap: () => setState(() => _selected = UserRole.learner),
              ),
              const SizedBox(height: 14),
              SelectableCard(
                title: 'Tutor',
                subtitle: 'Teach and share your knowledge',
                icon: Icons.school_rounded,
                accent: AppColors.success,
                selected: _selected == UserRole.tutor,
                onTap: () => setState(() => _selected = UserRole.tutor),
              ),
              const SizedBox(height: 14),
              SelectableCard(
                title: 'Both',
                subtitle: 'Learn and teach - switch anytime',
                icon: Icons.people_alt_rounded,
                accent: const Color(0xFF7C3AED),
                selected: _selected == UserRole.both,
                onTap: () => setState(() => _selected = UserRole.both),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'CONTINUE',
                onPressed: _selected == null
                    ? null
                    : () {
                        AppScope.read(context).setRole(_selected!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AgeVerificationScreen()),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small 3-step progress indicator used during onboarding.
class OnboardingStepBar extends StatelessWidget {
  final int step;
  const OnboardingStepBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
            decoration: BoxDecoration(
              color: i < step ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}
