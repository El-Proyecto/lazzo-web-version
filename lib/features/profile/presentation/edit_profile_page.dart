import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/components.dart';
import '../../../shared/constants/spacing.dart';
import '../../../shared/themes/colors.dart';
import '../domain/entities/profile_entity.dart';
import '../providers/edit_profile_provider.dart';

/// Edit Profile page for updating user profile information
/// Shows editable fields for name, location, birthday with photo change
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final Map<String, bool> _editingStates = {
    'name': false,
    'location': false,
    'birthday': false,
  };

  @override
  Widget build(BuildContext context) {
    final editProfileState = ref.watch(editProfileProvider);

    return editProfileState.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (profile) => _buildContent(profile),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: BrandColors.text1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: BrandColors.text1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: BrandColors.cantVote),
            SizedBox(height: Gaps.md),
            Text(
              'Failed to load profile',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: BrandColors.text1),
            ),
            SizedBox(height: Gaps.sm),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BrandColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProfileEntity profile) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: BrandColors.text1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Insets.screenH),
        child: Column(
          children: [
            SizedBox(height: Gaps.lg),

            // Profile photo
            EditableProfilePhoto(
              profileImageUrl: profile.profileImageUrl,
              onTap: () => _showPhotoChangeSheet(profile),
            ),

            SizedBox(height: Gaps.xl),

            // Name field (required)
            EditableInfoCard(
              label: 'Name',
              value: profile.name,
              placeholder: 'Enter your name',
              isRequired: true,
              isEditing: _editingStates['name'] ?? false,
              onEdit: () => _toggleEditing('name'),
              onSave: (value) => _saveField('name', value, profile),
              onCancel: () => _cancelEditing('name'),
            ),

            SizedBox(height: Gaps.md),

            // Location field (optional)
            EditableInfoCard(
              label: 'Location',
              value: profile.location,
              placeholder: 'Enter your location',
              isEditing: _editingStates['location'] ?? false,
              onEdit: () => _toggleEditing('location'),
              onSave: (value) => _saveField('location', value, profile),
              onCancel: () => _cancelEditing('location'),
            ),

            SizedBox(height: Gaps.md),

            // Birthday field (optional)
            BirthdayPickerCard(
              birthday: profile.birthday,
              isEditing: _editingStates['birthday'] ?? false,
              onEdit: () => _toggleEditing('birthday'),
              onSave: (date) => _saveBirthday(date, profile),
              onCancel: () => _cancelEditing('birthday'),
            ),

            SizedBox(height: Gaps.xl),
          ],
        ),
      ),
    );
  }

  void _toggleEditing(String field) {
    setState(() {
      // Close other editing states
      _editingStates.forEach((key, value) {
        if (key != field) _editingStates[key] = false;
      });

      // Toggle current field
      _editingStates[field] = !(_editingStates[field] ?? false);
    });
  }

  void _cancelEditing(String field) {
    setState(() {
      _editingStates[field] = false;
    });
  }

  Future<void> _saveField(
    String field,
    String value,
    ProfileEntity profile,
  ) async {
    if (field == 'name' && value.trim().isEmpty) {
      _showSnackBar('Name is required');
      return;
    }

    ProfileEntity updatedProfile;
    switch (field) {
      case 'name':
        updatedProfile = profile.copyWith(name: value.trim());
        break;
      case 'location':
        updatedProfile = profile.copyWith(
          location: value.trim().isEmpty ? null : value.trim(),
        );
        break;
      default:
        return;
    }

    try {
      await ref
          .read(editProfileProvider.notifier)
          .updateProfile(updatedProfile);
      setState(() {
        _editingStates[field] = false;
      });
      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Failed to update profile');
    }
  }

  Future<void> _saveBirthday(DateTime? date, ProfileEntity profile) async {
    final updatedProfile = profile.copyWith(birthday: date);

    try {
      await ref
          .read(editProfileProvider.notifier)
          .updateProfile(updatedProfile);
      setState(() {
        _editingStates['birthday'] = false;
      });
      _showSnackBar('Birthday updated successfully');
    } catch (e) {
      _showSnackBar('Failed to update birthday');
    }
  }

  void _showPhotoChangeSheet(ProfileEntity profile) {
    PhotoChangeBottomSheet.show(
      context: context,
      hasCurrentPhoto:
          profile.profileImageUrl != null &&
          profile.profileImageUrl!.isNotEmpty,
      onAction: (action) => _handlePhotoAction(action, profile),
    );
  }

  Future<void> _handlePhotoAction(
    PhotoSourceAction action,
    ProfileEntity profile,
  ) async {
    switch (action) {
      case PhotoSourceAction.gallery:
        // TODO: Implement gallery picker
        _showSnackBar('Gallery picker not implemented yet');
        break;
      case PhotoSourceAction.camera:
        // TODO: Implement camera picker
        _showSnackBar('Camera picker not implemented yet');
        break;
      case PhotoSourceAction.remove:
        final updatedProfile = profile.copyWith(profileImageUrl: null);
        try {
          await ref
              .read(editProfileProvider.notifier)
              .updateProfile(updatedProfile);
          _showSnackBar('Photo removed successfully');
        } catch (e) {
          _showSnackBar('Failed to remove photo');
        }
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: BrandColors.text1)),
        backgroundColor: BrandColors.bg1,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
