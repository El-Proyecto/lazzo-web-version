import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/grabber_bar.dart';

/// Model for a participant that can be selected for an expense
class ExpenseParticipantOption {
  final String id;
  final String name;
  final String? avatarUrl;

  const ExpenseParticipantOption({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

/// Bottom sheet for adding a new expense
/// Allows user to input expense details including title, payer(s), participants, and amount
class AddExpenseBottomSheet extends StatefulWidget {
  final List<ExpenseParticipantOption> participants;
  final Future<void> Function(
    String title,
    String paidBy,
    List<String> participantsOwe,
    double totalAmount,
  ) onAddExpense;

  const AddExpenseBottomSheet({
    super.key,
    required this.participants,
    required this.onAddExpense,
  });

  /// Show the add expense bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required List<ExpenseParticipantOption> participants,
    required Future<void> Function(
      String title,
      String paidBy,
      List<String> participantsOwe,
      double totalAmount,
    ) onAddExpense,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddExpenseBottomSheet(
        participants: participants,
        onAddExpense: onAddExpense,
      ),
    );
  }

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  String? _selectedPaidBy;
  late List<String> _selectedParticipants;

  bool _showPaidByDropdown = false;
  bool _showSplitWithDropdown = false;

  bool _showErrors = false;
  String? _titleError;
  String? _amountError;
  String? _paidByError;
  String? _splitWithError;

  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Default: primeiro participante como host
    _selectedPaidBy =
        widget.participants.isNotEmpty ? widget.participants.first.id : null;
    // ✅ Default: todos os participantes selecionados para dividir a despesa
    _selectedParticipants = widget.participants.map((p) => p.id).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _titleFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final text = _amountController.text.trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _amountPerPerson {
    if (_selectedParticipants.isEmpty || _totalAmount == 0) return 0.0;
    return _totalAmount / _selectedParticipants.length;
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
        _selectedPaidBy != null &&
        _selectedParticipants.isNotEmpty &&
        _totalAmount > 0;
  }

  void _validateFields() {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'Please enter an expense title'
          : null;
      _amountError = _totalAmount <= 0 ? 'Please enter a valid amount' : null;
      _paidByError = _selectedPaidBy == null ? 'Please select who paid' : null;
      _splitWithError =
          _selectedParticipants.isEmpty ? 'Please select participants' : null;
    });
  }

  Future<void> _handleAddExpense() async {
    // Prevent double-tap
    if (_isAdding) return;

    if (!_isValid) {
      _validateFields();
      setState(() {
        _showErrors = true;
      });
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await widget.onAddExpense(
        _titleController.text.trim(),
        _selectedPaidBy!,
        _selectedParticipants,
        _totalAmount,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Reset adding state on error
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
      rethrow; // Allow parent to handle error
    }
  }

  void _selectPaidBy(String participantId) {
    setState(() {
      _selectedPaidBy = participantId;
      if (_showErrors) _validateFields();
    });
  }

  void _closePaidByDropdown() {
    if (_showPaidByDropdown) {
      setState(() {
        _showPaidByDropdown = false;
      });
    }
  }

  void _closeSplitWithDropdown() {
    if (_showSplitWithDropdown) {
      setState(() {
        _showSplitWithDropdown = false;
      });
    }
  }

  void _closeAllDropdowns() {
    _closePaidByDropdown();
    _closeSplitWithDropdown();
    _titleFocusNode.unfocus();
    _amountFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeAllDropdowns,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Grabber
            const GrabberBar(),

            // Header - title aligned left, no close button
            Padding(
              padding: const EdgeInsets.only(
                  right: Pads.sectionH,
                  left: Pads.sectionH,
                  top: Gaps.sm,
                  bottom: Pads.sectionH),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'New Expense',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ),
            ),

            // Content - Expanded to fill available space
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: Pads.sectionH,
                  right: Pads.sectionH,
                  bottom: Pads.sectionH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense Title
                    _buildInputField(
                      label: 'Expense Title',
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      hintText: 'e.g., Dinner at Restaurant',
                      errorText: _showErrors ? _titleError : null,
                      onChanged: (_) {
                        setState(() {});
                        if (_showErrors) _validateFields();
                      },
                    ),

                    const SizedBox(height: Gaps.lg),

                    // Total Amount
                    _buildAmountField(
                      label: 'Total Amount',
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      hintText: '0.00',
                      errorText: _showErrors ? _amountError : null,
                      onChanged: (_) {
                        setState(() {});
                        if (_showErrors) _validateFields();
                      },
                    ), // Amount per person (inline display)
                    if (_totalAmount > 0 &&
                        _selectedParticipants.isNotEmpty) ...[
                      const SizedBox(height: Gaps.xs),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Gaps.xxs),
                        child: Text(
                          '${_amountPerPerson.toStringAsFixed(2)}€ per person • ${_selectedParticipants.length} ${_selectedParticipants.length == 1 ? 'person' : 'people'}',
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: Gaps.lg),

                    // Paid by (dropdown trigger)
                    _buildSingleSelectDropdownTrigger(
                      label: 'Paid by',
                      selectedId: _selectedPaidBy,
                      showDropdown: _showPaidByDropdown,
                      errorText: _showErrors ? _paidByError : null,
                      onToggle: () {
                        setState(() {
                          _showPaidByDropdown = !_showPaidByDropdown;
                          _showSplitWithDropdown = false;
                        });
                      },
                      dropdownBuilder: _buildPaidByDropdown,
                    ),

                    const SizedBox(height: Gaps.lg),

                    // Split with (dropdown trigger)
                    _buildMultiSelectDropdownTrigger(
                      label: 'Split with',
                      selectedIds: _selectedParticipants,
                      showDropdown: _showSplitWithDropdown,
                      errorText: _showErrors ? _splitWithError : null,
                      onToggle: () {
                        setState(() {
                          _showSplitWithDropdown = !_showSplitWithDropdown;
                          _showPaidByDropdown = false;
                        });
                      },
                      dropdownBuilder: _buildSplitWithDropdown,
                    ),
                  ],
                ),
              ),
            ),

            // Add Expense Button - pinned at bottom with optimistic UI
            Padding(
              padding: const EdgeInsets.all(Pads.sectionH),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isAdding || !_isValid) ? null : _handleAddExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdding
                        ? BrandColors.planning.withOpacity(0.5)
                        : (_isValid ? BrandColors.planning : BrandColors.bg3),
                    foregroundColor: BrandColors.text1,
                    padding: const EdgeInsets.symmetric(
                      vertical: Gaps.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    disabledBackgroundColor: _isAdding
                        ? BrandColors.planning.withOpacity(0.5)
                        : BrandColors.bg3,
                  ),
                  child: _isAdding
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  BrandColors.text1,
                                ),
                              ),
                            ),
                            const SizedBox(width: Gaps.sm),
                            Text(
                              'Adding...',
                              style: AppText.labelLarge.copyWith(
                                color: BrandColors.text1,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Add Expense',
                          style: AppText.labelLarge.copyWith(
                            color: _isValid
                                ? BrandColors.text1
                                : BrandColors.text2,
                          ),
                        ),
                ),
              ),
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.xs),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: TouchTargets.input),
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: errorText != null ? Colors.red : BrandColors.border,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlV,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: Gaps.xxs),
          Padding(
            padding: const EdgeInsets.only(left: Gaps.xxs),
            child: Text(
              errorText,
              style: AppText.bodyMedium.copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.xs),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: TouchTargets.input),
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: errorText != null ? Colors.red : BrandColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                  inputFormatters: [
                    // Allow digits, dot, and comma (comma will be converted to dot)
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}')),
                    // Convert comma to dot for iOS keyboards
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(
                        text: newValue.text.replaceAll(',', '.'),
                      );
                    }),
                  ],
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle:
                        AppText.bodyMedium.copyWith(color: BrandColors.text2),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Pads.ctlV,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: Pads.ctlH),
                child: Text(
                  '€',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: Gaps.xxs),
          Padding(
            padding: const EdgeInsets.only(left: Gaps.xxs),
            child: Text(
              errorText,
              style: AppText.bodyMedium.copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleSelectDropdownTrigger({
    required String label,
    required String? selectedId,
    required bool showDropdown,
    required VoidCallback onToggle,
    required Widget Function() dropdownBuilder,
    String? errorText,
  }) {
    final selectedName = selectedId != null
        ? widget.participants.firstWhere((p) => p.id == selectedId).name
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.xs),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: TouchTargets.input),
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Pads.ctlV,
            ),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: errorText != null
                    ? Colors.red
                    : (showDropdown
                        ? BrandColors.planning
                        : BrandColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedName ?? 'Select ${label.toLowerCase()}',
                    style: AppText.bodyMedium.copyWith(
                      color: selectedName == null
                          ? BrandColors.text2
                          : BrandColors.text1,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: BrandColors.text2,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: Gaps.xxs),
          Padding(
            padding: const EdgeInsets.only(left: Gaps.xxs),
            child: Text(
              errorText,
              style: AppText.bodyMedium.copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (showDropdown) dropdownBuilder(),
      ],
    );
  }

  Widget _buildMultiSelectDropdownTrigger({
    required String label,
    required List<String> selectedIds,
    required bool showDropdown,
    required VoidCallback onToggle,
    required Widget Function() dropdownBuilder,
    String? errorText,
  }) {
    final selectedNames = selectedIds.isNotEmpty
        ? selectedIds
            .map((id) => widget.participants.firstWhere((p) => p.id == id).name)
            .join(', ')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.xs),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: TouchTargets.input),
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Pads.ctlV,
            ),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: errorText != null
                    ? Colors.red
                    : (showDropdown
                        ? BrandColors.planning
                        : BrandColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedNames ?? 'Select ${label.toLowerCase()}',
                    style: AppText.bodyMedium.copyWith(
                      color: selectedNames == null
                          ? BrandColors.text2
                          : BrandColors.text1,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: BrandColors.text2,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: Gaps.xxs),
          Padding(
            padding: const EdgeInsets.only(left: Gaps.xxs),
            child: Text(
              errorText,
              style: AppText.bodyMedium.copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (showDropdown) dropdownBuilder(),
      ],
    );
  }

  Widget _buildPaidByDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: Gaps.xs),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.participants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          final isSelected = _selectedPaidBy == participant.id;
          final isFirst = index == 0;
          final isLast = index == widget.participants.length - 1;

          return _buildParticipantOption(
            name: participant.name,
            avatarUrl: participant.avatarUrl,
            isSelected: isSelected,
            onTap: () {
              _selectPaidBy(participant.id);
              // Auto-close dropdown após seleção
              setState(() {
                _showPaidByDropdown = false;
              });
            },
            isFirst: isFirst,
            isLast: isLast,
            isRadio: true, // ✅ Usar radio button
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSplitWithDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: Gaps.xs),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Select All option
          _buildParticipantOption(
            name: 'Select All',
            isSelected:
                _selectedParticipants.length == widget.participants.length,
            onTap: _toggleAllParticipants,
            isSelectAll: true,
            isFirst: true,
            isLast: false,
          ),
          // Participants
          ...widget.participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            final isSelected = _selectedParticipants.contains(participant.id);
            final isLast = index == widget.participants.length - 1;

            return _buildParticipantOption(
              name: participant.name,
              avatarUrl: participant.avatarUrl,
              isSelected: isSelected,
              onTap: () => _toggleParticipant(participant.id),
              isFirst: false,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  void _toggleParticipant(String participantId) {
    setState(() {
      if (_selectedParticipants.contains(participantId)) {
        _selectedParticipants.remove(participantId);
      } else {
        _selectedParticipants.add(participantId);
      }
      if (_showErrors) _validateFields();
    });
  }

  void _toggleAllParticipants() {
    setState(() {
      if (_selectedParticipants.length == widget.participants.length) {
        _selectedParticipants.clear();
      } else {
        _selectedParticipants = widget.participants.map((p) => p.id).toList();
      }
      if (_showErrors) _validateFields();
    });
  }

  Widget _buildParticipantOption({
    required String name,
    String? avatarUrl,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSelectAll = false,
    bool isFirst = false,
    bool isLast = false,
    bool isRadio = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(Radii.md) : Radius.zero,
          bottom: isLast ? const Radius.circular(Radii.md) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.ctlH,
            vertical: Pads.ctlV,
          ),
          decoration: BoxDecoration(
            border: !isLast
                ? const Border(
                    bottom: BorderSide(
                      color: BrandColors.border,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (!isSelectAll) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: BrandColors.bg1,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: Gaps.sm),
              ],
              Expanded(
                child: Text(
                  name,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text1,
                    fontSize: 14,
                    fontWeight:
                        isSelectAll ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isRadio)
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? BrandColors.planning
                      : BrandColors.text2.withValues(alpha: 0.3),
                  size: IconSizes.smAlt,
                )
              else
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? BrandColors.planning
                      : BrandColors.text2.withValues(alpha: 0.3),
                  size: IconSizes.smAlt,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
