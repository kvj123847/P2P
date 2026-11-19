import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'profile_setup_screen.dart';
import 'role_selection_screen.dart';

/// Age-tier verification: School (<18) and College (18+) users are kept in
/// separate pools for search, chat, sessions and courses.
class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  AgeTier? _tier;
  DateTime? _dob;
  bool _idUploaded = false;

  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now();
    var age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  /// Date of birth must agree with the selected tier.
  String? get _mismatch {
    final a = _age;
    if (a == null || _tier == null) return null;
    if (_tier == AgeTier.school && a >= 18) {
      return 'Your date of birth shows you are 18+. Please choose College / Adult.';
    }
    if (_tier == AgeTier.college && a < 18) {
      return 'Your date of birth shows you are under 18. Please choose School Student.';
    }
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 60),
      lastDate: DateTime(now.year - 10),
      helpText: 'Select your date of birth',
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _tier != null && _dob != null && _mismatch == null && _idUploaded;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 2 of 3')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingStepBar(step: 2),
            const SizedBox(height: 24),
            const Text('Tell us your age group',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'This keeps learning safe: school and college students are matched only '
              'within their own group.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SelectableCard(
              title: 'School Student',
              subtitle: 'Under 18',
              icon: Icons.backpack_rounded,
              accent: const Color(0xFFF97316),
              selected: _tier == AgeTier.school,
              onTap: () => setState(() => _tier = AgeTier.school),
            ),
            const SizedBox(height: 14),
            SelectableCard(
              title: 'College / Adult',
              subtitle: '18 or older',
              icon: Icons.account_balance_rounded,
              selected: _tier == AgeTier.college,
              onTap: () => setState(() => _tier = AgeTier.college),
            ),
            const SizedBox(height: 24),
            const Text('Date of birth', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickDob,
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dob == null
                          ? 'Select date of birth'
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}  (age $_age)',
                      style: TextStyle(
                        color: _dob == null ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month, color: AppColors.primary),
                ],
              ),
            ),
            if (_mismatch != null) ...[
              const SizedBox(height: 8),
              Text(_mismatch!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            const Text('Student ID verification',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppCard(
              color: _idUploaded ? AppColors.tutor : null,
              onTap: () {
                // Replace with image_picker / file_picker when integrating.
                setState(() => _idUploaded = true);
                showSnack(context, 'student_id.jpg uploaded (demo)');
              },
              child: Row(
                children: [
                  Icon(
                    _idUploaded ? Icons.verified_rounded : Icons.upload_file_rounded,
                    color: _idUploaded ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _idUploaded
                          ? 'ID uploaded - verification pending'
                          : 'Upload school / college ID card',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'CONTINUE',
              onPressed: canContinue
                  ? () {
                      AppScope.read(context).setTier(_tier!);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
