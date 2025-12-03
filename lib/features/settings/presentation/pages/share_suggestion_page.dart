import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/suggestion_providers.dart';

/// Page for sharing suggestions during beta
class ShareSuggestionPage extends ConsumerStatefulWidget {
  const ShareSuggestionPage({super.key});

  @override
  ConsumerState<ShareSuggestionPage> createState() =>
      _ShareSuggestionPageState();
}

class _ShareSuggestionPageState extends ConsumerState<ShareSuggestionPage> {
  static const int _maxCharacters = 200;

  final TextEditingController _descriptionController = TextEditingController();
  int _characterCount = 0;
  bool _showValidationErrors = false;

  String? get _descriptionError {
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please describe your suggestion';
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

  bool get _canSubmit => _descriptionController.text.trim().isNotEmpty;

  Future<void> _submitSuggestion() async {
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
          message: 'You must be logged in to submit a suggestion',
        );
      }
      return;
    }

    try {
      await ref.read(suggestionControllerProvider.notifier).submitSuggestion(
            description: _descriptionController.text.trim(),
            userId: userId,
          );

      if (mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Suggestion submitted successfully',
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
          message: 'Failed to submit suggestion. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestionState = ref.watch(suggestionControllerProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar.createEvent(
        title: 'Share a Suggestion',
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
                  'Have an idea to make Lazzo better? We\'d love to hear it! Share your suggestions and help us shape the future of the app.',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),

                const SizedBox(height: Gaps.xl),

                // Description section
                _buildSection(
                  title: 'What\'s your idea?',
                  child: _buildDescriptionField(),
                  error: _descriptionError,
                ),

                const SizedBox(height: Gaps.xl),

                // Submit button
                _buildSubmitButton(suggestionState),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Loading overlay
          if (suggestionState.isLoading)
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
                  'Describe your idea or feature request. What would make Lazzo more useful for you?',
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

  Widget _buildSubmitButton(AsyncValue<void> suggestionState) {
    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: !suggestionState.isLoading ? _submitSuggestion : null,
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
            'Submit Suggestion',
            style: AppText.titleMediumEmph.copyWith(
              color: _canSubmit ? BrandColors.text1 : BrandColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
