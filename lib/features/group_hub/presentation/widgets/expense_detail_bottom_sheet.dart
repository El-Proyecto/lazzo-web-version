import 'package:flutter/material.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/expense_participant_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class ExpenseDetailBottomSheet extends StatefulWidget {
  final GroupExpenseEntity expense;
  final List<ExpenseParticipant> participants;
  final bool isCurrentUserPayer;
  final VoidCallback? onMarkAsPaid;
  final Function(String participantId)? onNotifyParticipant;

  const ExpenseDetailBottomSheet({
    super.key,
    required this.expense,
    required this.participants,
    required this.isCurrentUserPayer,
    this.onMarkAsPaid,
    this.onNotifyParticipant,
  });

  @override
  State<ExpenseDetailBottomSheet> createState() =>
      _ExpenseDetailBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required GroupExpenseEntity expense,
    required List<ExpenseParticipant> participants,
    required bool isCurrentUserPayer,
    VoidCallback? onMarkAsPaid,
    Function(String participantId)? onNotifyParticipant,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExpenseDetailBottomSheet(
        expense: expense,
        participants: participants,
        isCurrentUserPayer: isCurrentUserPayer,
        onMarkAsPaid: onMarkAsPaid,
        onNotifyParticipant: onNotifyParticipant,
      ),
    );
  }
}

class _ExpenseDetailBottomSheetState extends State<ExpenseDetailBottomSheet> {
  late List<ExpenseParticipant> _participants;
  final Map<String, bool> _notificationSent = {};
  final Map<String, DateTime> _lastNotificationTime = {};
  final Map<String, bool> _showCooldownBanner = {};

  @override
  void initState() {
    super.initState();
    _participants = List.from(widget.participants);
  }

  @override
  Widget build(BuildContext context) {
    final paidParticipants = _participants.where((p) => p.hasPaid).toList();
    final oweParticipants = _participants.where((p) => !p.hasPaid).toList();

    // Sort paid participants by payment date (most recent first)
    paidParticipants.sort((a, b) {
      if (a.paidAt == null && b.paidAt == null) return 0;
      if (a.paidAt == null) return 1;
      if (b.paidAt == null) return -1;
      return b.paidAt!.compareTo(a.paidAt!); // Most recent first
    });

    final singleAmount =
        _participants.isNotEmpty ? _participants.first.amount : 0.0;

    // Check if current user has paid (to determine if we show the button)
    final currentUserParticipant = _participants.firstWhere(
      (p) => p.id == 'current_user',
      orElse: () => ExpenseParticipant(
        id: 'current_user',
        name: 'You',
        amount: singleAmount,
        hasPaid: false,
      ),
    );
    final showMarkAsPaidButton = !currentUserParticipant.hasPaid;

    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: Gaps.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: BrandColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Fixed Header
          _buildFixedHeader(singleAmount),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Pads.sectionH),

                  // Paid section
                  if (paidParticipants.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Paid', paidParticipants.length, BrandColors.planning),
                    const SizedBox(height: Gaps.md),
                    ...paidParticipants.map((participant) =>
                        _buildParticipantRow(participant, true)),
                    const SizedBox(height: Gaps.xs),
                  ],

                  // Owes section
                  if (oweParticipants.isNotEmpty) ...[
                    _buildSectionHeader(
                        'Owes', oweParticipants.length, BrandColors.cantVote),
                    const SizedBox(height: Gaps.md),
                    ...oweParticipants.map((participant) =>
                        _buildParticipantRow(participant, false)),
                  ],

                  // Exact 32px spacing before button
                  if (showMarkAsPaidButton) const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Check if any cooldown banner should be shown
          if (_showCooldownBanner.values.any((show) => show))
            _buildCooldownBanner(_showCooldownBanner.keys.firstWhere(
              (key) => _showCooldownBanner[key] == true,
            )),

          // Fixed bottom button
          if (showMarkAsPaidButton)
            _buildFixedBottomButton(context, currentUserParticipant.amount),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(double singleAmount) {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BrandColors.bg3, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Expense name and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.expense.description,
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ),
              Text(
                '€${widget.expense.amount.toStringAsFixed(2)}',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ],
          ),

          const SizedBox(height: Gaps.xs),

          // Paid by and amount per person
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid by ${widget.expense.paidBy}',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
              Text(
                '€${singleAmount.toStringAsFixed(2)} each',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppText.bodyMediumEmph.copyWith(
            color: color,
          ),
        ),
        Text(
          count == 1 ? '1 person' : '$count people',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantRow(ExpenseParticipant participant, bool hasPaid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.md),
      child: Row(
        children: [
          // Profile picture (circular like votes)
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.bg3,
            child: participant.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      participant.avatarUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(participant.name),
                    ),
                  )
                : _buildDefaultAvatar(participant.name),
          ),

          const SizedBox(width: Gaps.md),

          // Name
          Expanded(
            child: Text(
              participant.name,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
              ),
            ),
          ),

          // Time paid or notify button
          if (hasPaid)
            Text(
              _formatTime(participant.paidAt),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            )
          else if (widget.isCurrentUserPayer)
            _buildNotifyButton(participant.id),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: AppText.bodyMediumEmph.copyWith(
        color: BrandColors.text2,
      ),
    );
  }

  Widget _buildNotifyButton(String participantId) {
    final isNotificationSent = _notificationSent[participantId] ?? false;

    return GestureDetector(
      onTap: () => _handleNotificationTap(participantId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isNotificationSent ? BrandColors.bg2 : BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: isNotificationSent
              ? Border.all(color: BrandColors.bg3, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotificationSent ? Icons.schedule : Icons.notifications,
              size: 14,
              color: BrandColors.text1,
            ),
            const SizedBox(width: 4),
            Text(
              'Notify',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownBanner(String participantId) {
    final timeLeft = _getTimeUntilNextNotification(participantId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: const BoxDecoration(
        color: BrandColors.bg3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 16, color: BrandColors.text2),
          const SizedBox(width: Gaps.xs),
          Text(
            'Can notify again in $timeLeft',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(String participantId) {
    final isNotificationSent = _notificationSent[participantId] ?? false;

    if (isNotificationSent) {
      // Show cooldown banner
      setState(() {
        _showCooldownBanner[participantId] = true;
      });

      // Hide banner after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCooldownBanner[participantId] = false;
          });
        }
      });
    } else {
      // First notification: change to pending state
      setState(() {
        _notificationSent[participantId] = true;
        _lastNotificationTime[participantId] = DateTime.now();
      });

      // Call callback for actual notification
      widget.onNotifyParticipant?.call(participantId);

      // Reset notification status after 30 minutes
      Future.delayed(const Duration(minutes: 30), () {
        if (mounted) {
          setState(() {
            _notificationSent[participantId] = false;
            _lastNotificationTime.remove(participantId);
          });
        }
      });
    }
  }

  void _handleMarkAsPaid() {
    // Update the current user's payment status
    setState(() {
      final currentUserIndex =
          _participants.indexWhere((p) => p.id == 'current_user');
      if (currentUserIndex != -1) {
        _participants[currentUserIndex] =
            _participants[currentUserIndex].copyWith(
          hasPaid: true,
          paidAt: DateTime.now(),
        );
      }
    });

    // Call the original callback
    widget.onMarkAsPaid?.call();

    // Close the bottom sheet
    Navigator.pop(context);
  }

  String _getTimeUntilNextNotification(String participantId) {
    final lastTime = _lastNotificationTime[participantId];
    if (lastTime == null) return '0m';

    final timeElapsed = DateTime.now().difference(lastTime);
    final timeLeft = const Duration(minutes: 30) - timeElapsed;

    if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m';
    } else {
      return '${timeLeft.inSeconds}s';
    }
  }

  Widget _buildFixedBottomButton(BuildContext context, double amount) {
    return Container(
      padding: EdgeInsets.only(
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: MediaQuery.of(context).padding.bottom + Pads.sectionH,
        top: Pads.sectionH,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleMarkAsPaid(),
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.planning,
            foregroundColor: BrandColors.text1,
            padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
          ),
          child: Text(
            'Mark €${amount.toStringAsFixed(2)} as paid',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
