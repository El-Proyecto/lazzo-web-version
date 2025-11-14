import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../domain/entities/group_entity.dart';
import '../widgets/group_permissions_section.dart';
import '../widgets/group_photo_selector_with_camera.dart';
import '../providers/update_group_provider.dart';

/// Page for editing an existing group (Admin only)
class EditGroupPage extends ConsumerStatefulWidget {
  final GroupEntity group;

  const EditGroupPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends ConsumerState<EditGroupPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late bool _canEditSettings;
  late bool _canAddMembers;
  late bool _canSendMessages;
  String? _selectedPhotoPath;
  bool _hasPhotoChanged = false;
  String? _nameError;

  // Store initial values for comparison
  late final String _initialName;
  late final String _initialDescription;
  late final bool _initialCanEditSettings;
  late final bool _initialCanAddMembers;
  late final bool _initialCanSendMessages;
  late final String? _initialPhotoPath;

  @override
  void initState() {
    super.initState();

    // Store initial values
    _initialName = widget.group.name;
    _initialDescription = widget.group.description ?? '';
    _initialCanEditSettings = widget.group.permissions.membersCanInvite;
    _initialCanAddMembers = widget.group.permissions.membersCanAddMembers;
    _initialCanSendMessages = widget.group.permissions.membersCanCreateEvents;
    _initialPhotoPath = widget.group.photoUrl;

    // Initialize controllers with existing group data
    _nameController = TextEditingController(text: _initialName);
    _descriptionController = TextEditingController(text: _initialDescription);

    _canEditSettings = _initialCanEditSettings;
    _canAddMembers = _initialCanAddMembers;
    _canSendMessages = _initialCanSendMessages;

    _selectedPhotoPath = _initialPhotoPath;

    // Listen for changes - but actual change detection is in _hasUnsavedChanges getter
    _nameController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  /// Check if any field has actually changed from initial values
  bool get _hasUnsavedChanges {
    final currentName = _nameController.text.trim();
    final currentDescription = _descriptionController.text.trim();

    return currentName != _initialName ||
        currentDescription != _initialDescription ||
        _canEditSettings != _initialCanEditSettings ||
        _canAddMembers != _initialCanAddMembers ||
        _canSendMessages != _initialCanSendMessages ||
        _hasPhotoChanged;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handlePhotoSelection() async {
    await _selectPhoto(ImageSource.gallery);
  }

  void _handleCameraPhoto() async {
    await _selectPhoto(ImageSource.camera);
  }

  Future<void> _selectPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotoPath = image.path;
          _hasPhotoChanged = true;
        });
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to select photo: $e',
        );
      }
    }
  }

  void _handlePhotoRemoval() {
    setState(() {
      _selectedPhotoPath = null;
      _hasPhotoChanged = true;
    });
  }

  void _handlePermissionChange() {
    setState(() {
      // Trigger rebuild to re-evaluate _hasUnsavedChanges
    });
  }

  Future<void> _showUnsavedChangesDialog() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        contentPadding: const EdgeInsets.all(Gaps.lg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Unsaved Changes',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.md),
            // Message
            Text(
              'You have unsaved changes. What would you like to do?',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.lg),
            // Buttons row
            Row(
              children: [
                // Discard button (left, gray with red text)
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop('discard'),
                    style: TextButton.styleFrom(
                      backgroundColor: BrandColors.bg3,
                      padding:
                          const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.cantVote,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                // Save button (right, green)
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop('save'),
                    style: TextButton.styleFrom(
                      backgroundColor: BrandColors.planning,
                      padding:
                          const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppText.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'discard') {
      // Discard changes and go back
      Navigator.of(context).pop();
    } else if (result == 'save') {
      // Save and go back
      _handleSaveChanges();
    }
    // If null (tapped outside), do nothing - stay on page
  }

  Future<void> _handleBackPress() async {
    await _showUnsavedChangesDialog();
  }

  void _handleSaveChanges() {
    _validateFields();

    final name = _nameController.text.trim();

    // Only proceed if form is valid
    if (_isFormValid) {
      ref.read(updateGroupProvider.notifier).updateGroup(
            groupId: widget.group.id!,
            name: name,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            photoPath: _hasPhotoChanged ? _selectedPhotoPath : null,
            canEditSettings: _canEditSettings,
            canAddMembers: _canAddMembers,
            canSendMessages: _canSendMessages,
          );
    }
  }

  void _validateFields() {
    final name = _nameController.text.trim();

    setState(() {
      if (name.isEmpty) {
        _nameError = 'Please enter a group name';
      } else if (name.length < 3) {
        _nameError = 'Group name must be at least 3 characters';
      } else {
        _nameError = null;
      }
    });
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    return _nameError == null && name.isNotEmpty && name.length >= 3;
  }

  Widget _buildSaveButton(AsyncValue<GroupEntity?> updateGroupState) {
    final isLoading = updateGroupState.isLoading;

    return Container(
      width: double.infinity,
      height: TouchTargets.input,
      decoration: ShapeDecoration(
        color: _isFormValid && !isLoading && _hasUnsavedChanges
            ? BrandColors.planning
            : BrandColors.bg3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.md)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
          onTap: isLoading || !_hasUnsavedChanges ? null : _handleSaveChanges,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrandColors.text1,
                      ),
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: AppText.labelLarge.copyWith(
                      color: _isFormValid && _hasUnsavedChanges
                          ? BrandColors.text1
                          : BrandColors.text2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updateGroupState = ref.watch(updateGroupProvider);

    // Listen to state changes for navigation
    ref.listen<AsyncValue<GroupEntity?>>(updateGroupProvider, (previous, next) {
      next.whenOrNull(
        data: (updatedGroup) {
          if (updatedGroup != null) {
            if (mounted) {
              TopBanner.showSuccess(
                context,
                message: 'Group updated successfully',
              );

              // Navigate back after brief delay
              final navigator = Navigator.of(context);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  navigator.pop(updatedGroup);
                }
              });
            }
          }
        },
        error: (error, stack) {
          if (mounted) {
            TopBanner.showError(
              context,
              message: 'Error: $error',
            );
          }
        },
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        appBar: CommonAppBar.createEvent(
          title: 'Edit Group',
          onBackPressed: _handleBackPress,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: Gaps.xs),

              // Photo selector with camera support
              GroupPhotoSelectorWithCamera(
                photoUrl: _selectedPhotoPath,
                onGallerySelected: _handlePhotoSelection,
                onCameraSelected: _handleCameraPhoto,
                onPhotoRemoved: _handlePhotoRemoval,
                addPhotoText:
                    _selectedPhotoPath != null && _selectedPhotoPath!.isNotEmpty
                        ? 'Change Photo'
                        : 'Add Photo',
                size: 120,
                showRemoveOption: _selectedPhotoPath != null,
              ),

              const SizedBox(height: Gaps.md),

              // Group name input with error support
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name', style: AppText.labelLarge),
                  const SizedBox(height: Gaps.xs),
                  Container(
                    width: double.infinity,
                    height: TouchTargets.input,
                    decoration: ShapeDecoration(
                      color: BrandColors.bg2,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Radii.md),
                        ),
                        side: _nameError != null
                            ? const BorderSide(
                                color: BrandColors.cantVote,
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text1,
                      ),
                      onChanged: (value) {
                        // Clear error when user starts typing
                        if (_nameError != null) {
                          setState(() {
                            _nameError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. Rancho Folclórico da Afurada',
                        hintStyle: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        contentPadding: const EdgeInsets.all(Insets.screenH),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_nameError != null) ...[
                    const SizedBox(height: Gaps.xxs),
                    Padding(
                      padding: const EdgeInsets.only(left: Insets.screenH),
                      child: Text(
                        _nameError!,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.cantVote,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: Gaps.md),

              // Permissions section
              GroupPermissionsSection(
                canEditSettings: _canEditSettings,
                canAddMembers: _canAddMembers,
                canSendMessages: _canSendMessages,
                onEditSettingsChanged: (value) {
                  setState(() => _canEditSettings = value);
                  _handlePermissionChange();
                },
                onAddMembersChanged: (value) {
                  setState(() => _canAddMembers = value);
                  _handlePermissionChange();
                },
                onSendMessagesChanged: (value) {
                  setState(() => _canSendMessages = value);
                  _handlePermissionChange();
                },
              ),

              const SizedBox(height: Gaps.xl),

              // Save button
              SizedBox(
                width: double.infinity,
                child: _buildSaveButton(updateGroupState),
              ),

              const SizedBox(height: Gaps.md),
            ],
          ),
        ),
      ),
    );
  }
}
