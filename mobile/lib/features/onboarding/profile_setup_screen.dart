import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../mock_data/mock_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../dashboard/main_shell.dart';
import 'role_selection_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _institution = TextEditingController();
  final _bio = TextEditingController();
  final Set<String> _subjects = {};

  @override
  void dispose() {
    _institution.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _finish() {
    AppScope.read(context).completeProfile(
      institutionName: _institution.text.trim(),
      about: _bio.text.trim(),
      selectedSubjects: _subjects.toList(),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final teaching = state.role.canTeach;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3 of 3'),
        actions: [TextButton(onPressed: _finish, child: const Text('Skip'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingStepBar(step: 3),
            const SizedBox(height: 24),
            const Text('Set up your profile',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              teaching
                  ? 'Learners will see this on your tutor profile.'
                  : 'This helps us recommend the right tutors and courses.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  InitialsAvatar(name: state.name, color: AppColors.primary, radius: 46),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => showSnack(context, 'Photo picker opens here (image_picker)'),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _institution,
              label: 'School / College',
              hint: 'e.g. ABC College of Engineering',
              icon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _bio,
              label: 'About you',
              hint: teaching
                  ? 'What do you teach and how?'
                  : 'What are your learning goals?',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(teaching ? 'Subjects you can teach' : 'Subjects you are interested in',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MockData.subjects.map((s) {
                final sel = _subjects.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (v) => setState(() => v ? _subjects.add(s) : _subjects.remove(s)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'FINISH SETUP', onPressed: _finish),
          ],
        ),
      ),
    );
  }
}
