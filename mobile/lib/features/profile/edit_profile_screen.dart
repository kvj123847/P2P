import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../state/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _institution;
  late final TextEditingController _bio;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    final state = AppScope.read(context);
    _name = TextEditingController(text: state.name);
    _institution = TextEditingController(text: state.institution);
    _bio = TextEditingController(text: state.bio);
    _init = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.read(context).updateProfile(
      newName: _name.text,
      newInstitution: _institution.text.trim(),
      newBio: _bio.text.trim(),
    );
    showSnack(context, 'Profile updated');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                InitialsAvatar(name: state.name, color: AppColors.primary, radius: 46),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(controller: _name, label: 'Name', hint: 'Your name'),
          const SizedBox(height: 16),
          CustomTextField(
              controller: _institution, label: 'School / College', hint: 'Institution'),
          const SizedBox(height: 16),
          CustomTextField(controller: _bio, label: 'About', hint: 'About you', maxLines: 4),
          const SizedBox(height: 24),
          PrimaryButton(label: 'SAVE CHANGES', onPressed: _save),
        ],
      ),
    );
  }
}
