import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/components.dart';
import 'widgets/ios_birthday_picker_card.dart';
import 'widgets/editable_profile_photo.dart';
import 'widgets/editable_info_card.dart';
import 'widgets/photo_change_bottom_sheet.dart';
import '../../auth/presentation/widgets/email_info_card.dart';
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

  // Error state management
  String? _nameError;
  String? _locationError;
  String? _birthdayError;

  bool _allowBirthdayNotifications = false;

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
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
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
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.cantVote,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Failed to load profile',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.sm),
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
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Column(
          children: [
            const SizedBox(height: Gaps.lg),

            // Profile photo
            EditableProfilePhoto(
              profileImageUrl: profile.profileImageUrl,
              onTap: () => _showPhotoChangeSheet(profile),
            ),

            const SizedBox(height: Gaps.xl),

            // Email field (non-editable)
            EmailInfoCard(email: profile.email),

            const SizedBox(height: Gaps.md),

            // Name field (required)
            EditableInfoCard(
              label: 'Name',
              value: profile.name,
              placeholder: 'Enter your name',
              isRequired: true,
              isEditing: _editingStates['name'] ?? false,
              errorMessage: _nameError,
              onEdit: () => _toggleEditing('name'),
              onSave: (value) => _saveField('name', value, profile),
              onCancel: () => _cancelEditing('name'),
            ),

            const SizedBox(height: Gaps.md),

            // Location field (optional)
            EditableInfoCard(
              label: 'Location',
              value: profile.location,
              placeholder: 'Enter your location',
              isEditing: _editingStates['location'] ?? false,
              errorMessage: _locationError,
              onEdit: () => _toggleEditing('location'),
              onSave: (value) => _saveField('location', value, profile),
              onCancel: () => _cancelEditing('location'),
              onRemove: () => _removeField('location', profile),
            ),

            const SizedBox(height: Gaps.md),

            // Birthday field (optional) with notification checkbox
            IosBirthdayPickerCard(
              birthday: profile.birthday,
              isEditing: _editingStates['birthday'] ?? false,
              allowNotifications: _allowBirthdayNotifications,
              errorMessage: _birthdayError,
              onEdit: () => _toggleEditing('birthday'),
              onSave: (date) => _saveBirthday(date, profile),
              onCancel: () => _cancelEditing('birthday'),
              onNotificationChanged: (allow) =>
                  setState(() => _allowBirthdayNotifications = allow),
              onRemove: profile.birthday != null
                  ? () => _removeField('birthday', profile)
                  : null,
            ),

            const SizedBox(height: Gaps.xl),
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
      // Clear any validation errors when canceling
      if (field == 'name') _nameError = null;
      if (field == 'location') _locationError = null;
      if (field == 'birthday') _birthdayError = null;
    });
  }

  Future<void> _removeField(String field, ProfileEntity profile) async {
    try {
      ProfileEntity updatedProfile;
      switch (field) {
        case 'location':
          updatedProfile = profile.copyWith(clearLocation: true);
          break;
        case 'birthday':
          updatedProfile = profile.copyWith(clearBirthday: true);
          break;
        default:
          return;
      }

      await ref
          .read(editProfileProvider.notifier)
          .updateProfile(updatedProfile);

      setState(() {
        if (field == 'location') _locationError = null;
        if (field == 'birthday') _birthdayError = null;
        // Exit edit mode after successful removal
        _editingStates[field] = false;
      });
    } catch (e) {
      setState(() {
        if (field == 'location') _locationError = 'Failed to remove location';
        if (field == 'birthday') _birthdayError = 'Failed to remove birthday';
      });
    }
  }

  Future<void> _saveField(
    String field,
    String value,
    ProfileEntity profile,
  ) async {
    if (field == 'name' && value.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
      });
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
        // Clear any existing errors on successful save
        if (field == 'name') _nameError = null;
        if (field == 'location') _locationError = null;
      });
    } catch (e) {
      setState(() {
        if (field == 'name') _nameError = 'Failed to update name';
        if (field == 'location') _locationError = 'Failed to update location';
      });
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
        _birthdayError = null;
      });
    } catch (e) {
      setState(() {
        _birthdayError = 'Failed to update birthday';
      });
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
          // Photo removed successfully
        } catch (e) {
          _showSnackBar('Failed to remove photo');
        }
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: BrandColors.text1),
        ),
        backgroundColor: BrandColors.bg1,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
