import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/common/simple_selection_sheet.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/report_providers.dart';

/// Page for reporting problems during beta
class ReportProblemPage extends ConsumerStatefulWidget {
  const ReportProblemPage({super.key});

  @override
  ConsumerState<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends ConsumerState<ReportProblemPage> {
  static const List<String> _categories = [
    'Sign up / Login',
    'Create or join event',
    'Upload photos & memories',
    'Share memories',
    'Notifications',
    'Other',
  ];

  static const int _maxCharacters = 200;

  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  int _characterCount = 0;
  bool _showValidationErrors = false;

  String? get _categoryError {
    if (_selectedCategory == null) {
      return 'Please select a category';
    }
    return null;
  }

  String? get _descriptionError {
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please describe what happened';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateCharacterCount);
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _descriptionController.text.length;
    });
  }

  bool get _canSubmit =>
      _selectedCategory != null &&
      _descriptionController.text.trim().isNotEmpty;

  Future<void> _showCategorySelector() async {
    final selected = await SimpleSelectionSheet.show(
      context: context,
      title: 'Select a category',
      options: _categories,
      selectedOption: _selectedCategory,
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
        // Clear validation errors when field becomes valid
        if (_showValidationErrors && _categoryError == null) {
          _showValidationErrors = false;
        }
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_canSubmit) {
      setState(() {
        _showValidationErrors = true;
      });
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'You must be logged in to submit a report',
        );
      }
      return;
    }

    try {
      await ref.read(reportControllerProvider.notifier).submitReport(
            category: _selectedCategory!,
            description: _descriptionController.text.trim(),
            userId: userId,
          );

      if (mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Report submitted successfully',
        );

        // Wait a bit for user to see the success message
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to submit report. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportControllerProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar.createEvent(
        title: 'Report a Problem',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intro text
                Text(
                  'Help us improve Lazzo by reporting any issues you encounter. Your feedback is essential during our beta phase and will be reviewed by our team.',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),

                const SizedBox(height: Gaps.xl),

                // Category section
                _buildSection(
                  title: 'What went wrong?',
                  child: _buildCategorySelector(),
                  error: _categoryError,
                ),

                const SizedBox(height: Gaps.xl),

                // Description section
                _buildSection(
                  title: 'Describe what happened',
                  child: _buildDescriptionField(),
                  error: _descriptionError,
                ),

                const SizedBox(height: Gaps.xl),

                // Submit button
                _buildSubmitButton(reportState),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Loading overlay
          if (reportState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.bodyLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Gaps.md),
        child,
        if (error != null && _showValidationErrors) ...[
          const SizedBox(height: Gaps.xs),
          Text(
            error,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.cantVote,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: _showCategorySelector,
      borderRadius: BorderRadius.circular(Radii.smAlt),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(
            color: BrandColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCategory ?? 'Select a category',
                style: AppText.bodyLarge.copyWith(
                  color: _selectedCategory == null
                      ? BrandColors.text2
                      : BrandColors.text1,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: BrandColors.text2,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Pads.ctlH),
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.smAlt),
            border: Border.all(
              color: BrandColors.border,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLength: _maxCharacters,
            maxLines: 6,
            style: AppText.bodyLarge.copyWith(
              color: BrandColors.text1,
            ),
            decoration: InputDecoration(
              hintText:
                  'Tell us what you were trying to do, and what went wrong.',
              hintStyle: AppText.bodyLarge.copyWith(
                color: BrandColors.text2,
              ),
              border: InputBorder.none,
              counterText: '', // Hide default counter
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: Gaps.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_characterCount/$_maxCharacters',
            style: AppText.bodyMedium.copyWith(
              color: _characterCount > _maxCharacters
                  ? Colors.red
                  : BrandColors.text2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AsyncValue<void> reportState) {
    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: !reportState.isLoading ? _submitReport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSubmit
                ? Theme.of(context).colorScheme.primary
                : BrandColors.bg3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
          ),
          child: Text(
            'Submit Report',
            style: AppText.titleMediumEmph.copyWith(
              color: _canSubmit ? BrandColors.text1 : BrandColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
