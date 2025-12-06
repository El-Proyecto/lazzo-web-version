import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/group_entity.dart';
import '../widgets/group_permissions_section.dart';
import '../widgets/group_photo_selector_with_camera.dart';
import '../providers/create_group_provider.dart';
import '../providers/groups_provider.dart';

/// Page for creating a new group
class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _canEditSettings = false;
  bool _canAddMembers = false;
  bool _canSendMessages = false;
  String? _selectedPhotoPath;
  String? _nameError;
  bool _fromCreateEvent = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {}); // Rebuild to update button state
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we came from create event page
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['fromCreateEvent'] == true) {
      _fromCreateEvent = true;
          }
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
        });
      } else {
              }
    } catch (e) {
            // Show error to user
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
    });
  }

  void _handleCreateGroup() {
    _validateFields();

    final name = _nameController.text.trim();

    // Only proceed if form is valid
    if (_isFormValid) {
      ref.read(createGroupProvider.notifier).createGroup(
            name: name,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            photoPath: _selectedPhotoPath,
            canEditSettings: _canEditSettings,
            canAddMembers: _canAddMembers,
            canSendMessages: _canSendMessages,
          );
    }
    // If form is invalid, errors are now visible due to _validateFields call
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

  Widget _buildCreateButton(AsyncValue<GroupEntity?> createGroupState) {
    final isLoading = createGroupState.isLoading;

    return Container(
      width: double.infinity,
      height: TouchTargets.input,
      decoration: ShapeDecoration(
        color:
            _isFormValid && !isLoading ? BrandColors.planning : BrandColors.bg3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.md)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
          onTap: isLoading
              ? null
              : _handleCreateGroup, // Always allow tap when not loading
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
                    'Create',
                    style: AppText.labelLarge.copyWith(
                      color:
                          _isFormValid ? BrandColors.text1 : BrandColors.text2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createGroupState = ref.watch(createGroupProvider);

    // Listen to state changes for navigation
    ref.listen<AsyncValue<GroupEntity?>>(createGroupProvider, (previous, next) {
      next.whenOrNull(
        data: (createdGroup) async {
          if (createdGroup != null) {
            // If coming from create event, return group data
            if (_fromCreateEvent) {
              
              // Get the group cover URL if available
              String? imageUrl;
              if (createdGroup.photoUrl != null &&
                  createdGroup.photoUrl!.isNotEmpty) {
                try {
                  imageUrl = await ref.read(
                      groupCoverUrlProvider((createdGroup.photoUrl, null))
                          .future);
                } catch (e) {
                  // Failed to load cover image - continue without it
                }
              }
              // Store navigator before async gap
              // ignore: use_build_context_synchronously
              final navigator = Navigator.of(context);
              // Only check mounted after all awaits
              if (!mounted) return;
              navigator.pop({
                'groupId': createdGroup.id,
                'groupName': createdGroup.name,
                'memberCount': 1,
                'imageUrl': imageUrl,
              });
            } else {
              // Navigate to Group Created page
              // Store navigator before any potential async work
              final navigator = Navigator.of(context);
              if (!mounted) return;
              navigator.pushNamed(
                AppRouter.groupCreated,
                arguments: {'group': createdGroup},
              );
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

    return Scaffold(
      appBar: CommonAppBar.createEvent(
        title: 'Create Group',
        onBackPressed: () {
          if (!mounted) return;
          Navigator.of(context).pop();
        },
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
              addPhotoText: 'Add Photo',
              size: 120,
              showRemoveOption: true,
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
              },
              onAddMembersChanged: (value) {
                setState(() => _canAddMembers = value);
              },
              onSendMessagesChanged: (value) {
                setState(() => _canSendMessages = value);
              },
            ),

            const SizedBox(height: Gaps.xl),

            // Create button
            SizedBox(
              width: double.infinity,
              child: _buildCreateButton(createGroupState),
            ),

            const SizedBox(height: Gaps.md),
          ],
        ),
      ),
    );
  }
}
