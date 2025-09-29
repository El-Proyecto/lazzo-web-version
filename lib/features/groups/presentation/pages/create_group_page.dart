import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/inputs/inputBox.dart';
import '../../../../shared/components/buttons/green_button.dart';
import '../widgets/group_photo_selector.dart';
import '../widgets/group_permissions_section.dart';
import '../providers/create_group_provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handlePhotoSelection() {
    // TODO: Implement photo selection logic
    // This would typically open a file picker or camera
    setState(() {
      _selectedPhotoPath = 'mock_photo_path';
    });
  }

  void _handleCreateGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    ref
        .read(createGroupProvider.notifier)
        .createGroup(
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

  @override
  Widget build(BuildContext context) {
    final createGroupState = ref.watch(createGroupProvider);

    // Listen to state changes for navigation
    ref.listen<AsyncValue<void>>(createGroupProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Navigate back on success
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        },
      );
    });

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Create Group',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: Gaps.lg),

            // Photo selector
            GroupPhotoSelector(
              photoUrl: _selectedPhotoPath,
              onTap: _handlePhotoSelection,
            ),

            const SizedBox(height: Gaps.lg),

            // Group name input
            InputBox(
              label: 'Name',
              hintText: 'e.g. Rancho Folclórico da Afurada',
              controller: _nameController,
            ),

            const SizedBox(height: Gaps.lg),

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
              child: GreenButton(
                text: 'Create',
                onPressed: createGroupState.isLoading
                    ? null
                    : _handleCreateGroup,
                isLoading: createGroupState.isLoading,
              ),
            ),

            const SizedBox(height: Gaps.lg),
          ],
        ),
      ),
    );
  }
}
