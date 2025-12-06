import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/editable_profile_photo.dart';
import '../widgets/photo_change_bottom_sheet.dart';
import '../../../auth/presentation/widgets/email_info_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/common/edit_field_bottom_sheet.dart';
import '../../../../shared/components/common/birthday_picker_bottom_sheet.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_providers.dart';

/// Edit Profile page for updating user profile information
/// Shows editable fields for name, location, birthday with photo change
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  @override
  Widget build(BuildContext context) {
    final editProfileState = ref.watch(currentUserProfileProvider);

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BrandColors.text1,
              ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BrandColors.text1,
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: BrandColors.text1,
                  ),
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.text2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(currentUserProfileProvider),
              child: const Text('Retry'),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BrandColors.text1,
              ),
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
            _buildInfoRow(
              label: 'Name',
              value: profile.name,
              isRequired: true,
              onTap: () => _showEditNameSheet(profile),
            ),

            const SizedBox(height: Gaps.md),

            // Location field (optional)
            _buildInfoRow(
              label: 'Location',
              value: profile.location,
              placeholder: 'Tap to add',
              onTap: () => _showEditLocationSheet(profile),
            ),

            const SizedBox(height: Gaps.md),

            // Birthday field (optional)
            _buildInfoRow(
              label: 'Birthday',
              value: profile.birthday != null
                  ? _formatDate(profile.birthday!)
                  : null,
              placeholder: 'Tap to add',
              onTap: () => _showEditBirthdaySheet(profile),
            ),

            const SizedBox(height: Gaps.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    String? value,
    String? placeholder,
    bool isRequired = false,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final showEmptyState = !hasValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: ShapeDecoration(
          color: showEmptyState ? BrandColors.bg3 : BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Label with required indicator
            Row(
              children: [
                Text(
                  label,
                  style: AppText.bodyMediumEmph.copyWith(
                    color: BrandColors.text1,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: Gaps.xs),
                  Text(
                    '*',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.cantVote,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            // Right side: Value and edit icon
            Row(
              children: [
                Text(
                  hasValue ? value : (placeholder ?? 'Tap to add'),
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: Gaps.xs),
                Icon(
                  hasValue ? Icons.edit_outlined : Icons.add,
                  size: 16,
                  color: BrandColors.text2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameSheet(ProfileEntity profile) async {
    final result = await EditFieldBottomSheet.show(
      context: context,
      title: 'Name',
      initialValue: profile.name,
      placeholder: 'Enter your name',
      isRequired: true,
    );

    if (result != null && mounted) {
      await _updateProfile(profile.copyWith(name: result), 'name');
    }
  }

  Future<void> _showEditLocationSheet(ProfileEntity profile) async {
    final result = await EditFieldBottomSheet.show(
      context: context,
      title: 'Location',
      initialValue: profile.location,
      placeholder: 'Enter your location',
    );

    if (result != null && mounted) {
      // Empty string means user wants to clear the field
      final newLocation = result.trim().isEmpty ? null : result.trim();
      await _updateProfile(
        profile.copyWith(
            location: newLocation, clearLocation: newLocation == null),
        'location',
      );
    }
  }

  Future<void> _showEditBirthdaySheet(ProfileEntity profile) async {
    final result = await BirthdayPickerBottomSheet.show(
      context: context,
      initialDate: profile.birthday,
      allowNotifications: false, // TODO: get from profile if stored
    );

    if (result != null && mounted) {
      // Check if user wants to remove the birthday
      if (result['remove'] == true) {
        await _updateProfile(
          profile.copyWith(birthday: null, clearBirthday: true),
          'birthday',
        );
        return;
      }

      // Save the new birthday
      final date = result['date'] as DateTime?;

      if (date != null) {
        await _updateProfile(profile.copyWith(birthday: date), 'birthday');
      }
    }
  }

  Future<void> _updateProfile(
      ProfileEntity updatedProfile, String fieldName) async {
    try {
      final controller = ref.read(editProfileControllerProvider);
      await controller.updateProfile(updatedProfile);

      if (mounted) {
        TopBanner.showSuccess(context, message: 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context, message: 'Failed to update $fieldName');
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')}/${months[date.month - 1]}/${date.year}';
  }

  void _showPhotoChangeSheet(ProfileEntity profile) {
    PhotoChangeBottomSheet.show(
      context: context,
      hasCurrentPhoto: profile.profileImageUrl != null &&
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
        await _pickImageFromGallery(profile);
        break;
      case PhotoSourceAction.camera:
        await _pickImageFromCamera(profile);
        break;
      case PhotoSourceAction.remove:
        await _removePhoto(profile);
        break;
    }
  }

  Future<void> _pickImageFromGallery(ProfileEntity profile) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePicture(image, profile);
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context,
            message: 'Failed to pick image from gallery');
      }
    }
  }

  Future<void> _pickImageFromCamera(ProfileEntity profile) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePicture(image, profile);
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context, message: 'Failed to take photo');
      }
    }
  }

  Future<void> _uploadProfilePicture(XFile image, ProfileEntity profile) async {
    try {
      // Show info banner
      if (mounted) {
        TopBanner.showInfo(context, message: 'Uploading photo...');
      }

      final controller = ref.read(editProfileControllerProvider);

      // Upload the image and get the storage path
      final imagePath =
          await ref.read(profileRepositoryProvider).uploadProfilePicture(image);

      // Update profile with new image path
      final updatedProfile = profile.copyWith(profileImageUrl: imagePath);
      await controller.updateProfile(updatedProfile);

      if (mounted) {
        TopBanner.showSuccess(context, message: 'Photo updated successfully');
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context, message: 'Failed to upload photo');
      }
    }
  }

  Future<void> _removePhoto(ProfileEntity profile) async {
    try {
      final controller = ref.read(editProfileControllerProvider);

      // Delete the image from storage if it exists
      if (profile.profileImageUrl != null &&
          profile.profileImageUrl!.isNotEmpty) {
        await ref.read(profileRepositoryProvider).deleteProfilePicture();
      }

      // Update profile to remove image reference
      final updatedProfile = profile.copyWith(profileImageUrl: null);
      await controller.updateProfile(updatedProfile);

      if (mounted) {
        TopBanner.showSuccess(context, message: 'Photo removed successfully');
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context, message: 'Failed to remove photo');
      }
    }
  }
}
