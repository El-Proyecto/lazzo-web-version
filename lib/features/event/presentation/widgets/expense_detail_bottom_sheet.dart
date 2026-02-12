import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ✅ MUDAR: import de expense/ em vez de event/
import '../../../expense/domain/entities/event_expense_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'event_expenses_widget.dart';

class ExpenseDetailBottomSheet extends StatefulWidget {
  // ✅ MUDAR: GroupExpenseEntity → EventExpenseEntity
  final EventExpenseEntity expense;
  final String payerName; // ✅ Name of person who paid
  // ✅ USAR: modelo local de living_expenses_widget.dart
  final List<ExpenseParticipantDisplay> participants;
  final bool isCurrentUserPayer;
  final EventMode? mode;
  final Future<void> Function()? onMarkAsPaid;
  final Function(String participantId)? onNotifyParticipant;

  const ExpenseDetailBottomSheet({
    super.key,
    required this.expense,
    required this.payerName,
    required this.participants,
    required this.isCurrentUserPayer,
    this.mode,
    this.onMarkAsPaid,
    this.onNotifyParticipant,
  });

  @override
  State<ExpenseDetailBottomSheet> createState() =>
      _ExpenseDetailBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required EventExpenseEntity expense, // ✅ Mudou
    required String payerName,
    required List<ExpenseParticipantDisplay> participants,
    required bool isCurrentUserPayer,
    EventMode? mode,
    Future<void> Function()? onMarkAsPaid,
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
        payerName: payerName,
        participants: participants,
        isCurrentUserPayer: isCurrentUserPayer,
        mode: mode,
        onMarkAsPaid: onMarkAsPaid,
        onNotifyParticipant: onNotifyParticipant,
      ),
    );
  }
}

class _ExpenseDetailBottomSheetState extends State<ExpenseDetailBottomSheet> {
  late List<ExpenseParticipantDisplay> _participants;
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

    paidParticipants.sort((a, b) {
      if (a.paidAt == null && b.paidAt == null) return 0;
      if (a.paidAt == null) return 1;
      if (b.paidAt == null) return -1;
      return b.paidAt!.compareTo(a.paidAt!);
    });

    final singleAmount =
        _participants.isNotEmpty ? _participants.first.amount : 0.0;

    // Get current user ID from Supabase auth
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Find current user in participants list (uses real UUID)
    final currentUserParticipant = _participants.firstWhere(
      (p) => p.id == currentUserId,
      orElse: () => ExpenseParticipantDisplay(
        id: '',
        name: 'You',
        amount: singleAmount,
        hasPaid:
            true, // Default to true so button doesn't show if user not found
      ),
    );

    // Show button if user is in the expense (whether paid or not)
    final showButton =
        currentUserId != null && currentUserParticipant.id.isNotEmpty;
    final hasUserPaid = currentUserParticipant.hasPaid;

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
                      'Paid',
                      paidParticipants.length,
                      BrandColors.planning,
                    ),
                    const SizedBox(height: Gaps.sm),
                    ...paidParticipants
                        .map((p) => _buildParticipantRow(p, true)),
                    const SizedBox(height: Gaps.sm),
                  ],

                  // Owes section
                  if (oweParticipants.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Owes',
                      oweParticipants.length,
                      BrandColors.cantVote,
                    ),
                    const SizedBox(height: Gaps.sm),
                    ...oweParticipants
                        .map((p) => _buildParticipantRow(p, false)),
                  ],

                  // Bottom spacing
                  const SizedBox(height: Gaps.xs),
                ],
              ),
            ),
          ),

          // Cooldown banner
          if (_showCooldownBanner.values.any((show) => show))
            _buildCooldownBanner(_showCooldownBanner.keys.firstWhere(
              (key) => _showCooldownBanner[key] == true,
            )),

          // Fixed bottom button
          if (showButton)
            _buildFixedBottomButton(
              context,
              currentUserParticipant.amount,
              hasUserPaid,
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.expense.description, // ✅ Mudou de title
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.expense.amount.toStringAsFixed(2)}€',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid by ${widget.payerName}', // ✅ Show name instead of UUID
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
              Text(
                '${singleAmount.toStringAsFixed(2)}€ each',
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
          style: AppText.bodyMediumEmph.copyWith(color: color),
        ),
        Text(
          count == 1 ? '1 person' : '$count people',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
      ],
    );
  }

  Widget _buildParticipantRow(
      ExpenseParticipantDisplay participant, bool hasPaid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.md),
      child: Row(
        children: [
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
                    ),
                  )
                : _buildDefaultAvatar(participant.name),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                ),
              ],
            ),
          ),
          if (hasPaid)
            Text(
              _formatTime(participant.paidAt),
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
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
      style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text2),
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
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
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
      decoration: const BoxDecoration(color: BrandColors.bg3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 16, color: BrandColors.text2),
          const SizedBox(width: Gaps.xs),
          Text(
            'Can notify again in $timeLeft',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(String participantId) {
    final isNotificationSent = _notificationSent[participantId] ?? false;

    if (isNotificationSent) {
      setState(() {
        _showCooldownBanner[participantId] = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCooldownBanner[participantId] = false;
          });
        }
      });
    } else {
      setState(() {
        _notificationSent[participantId] = true;
        _lastNotificationTime[participantId] = DateTime.now();
      });

      widget.onNotifyParticipant?.call(participantId);

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

  Future<void> _handleMarkAsPaid() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      final currentUserIndex =
          _participants.indexWhere((p) => p.id == currentUserId);
      if (currentUserIndex != -1) {
        _participants[currentUserIndex] = ExpenseParticipantDisplay(
          id: _participants[currentUserIndex].id,
          name: _participants[currentUserIndex].name,
          avatarUrl: _participants[currentUserIndex].avatarUrl,
          amount: _participants[currentUserIndex].amount,
          hasPaid: true,
          paidAt: DateTime.now(),
        );
      }
    });

    // Aguardar a operação async completar
    await widget.onMarkAsPaid?.call();

    // Não fechar aqui - o callback já fecha o bottom sheet
    // Navigator.pop(context);
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

  Widget _buildFixedBottomButton(
      BuildContext context, double amount, bool hasPaid) {
    return Container(
      padding: EdgeInsets.only(
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: MediaQuery.of(context).padding.bottom + Pads.sectionH,
        top: Pads.sectionH,
      ),
      decoration: const BoxDecoration(color: BrandColors.bg2),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              hasPaid ? null : _handleMarkAsPaid, // Disable if already paid
          style: ElevatedButton.styleFrom(
            backgroundColor: hasPaid
                ? BrandColors.bg3
                : (widget.mode == EventMode.living
                    ? BrandColors.living
                    : BrandColors.planning),
            foregroundColor: hasPaid ? BrandColors.text2 : BrandColors.text1,
            disabledBackgroundColor: BrandColors.bg3,
            disabledForegroundColor: BrandColors.text2,
            padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
          ),
          child: Text(
            hasPaid
                ? 'Already Paid'
                : 'Mark ${amount.toStringAsFixed(2)}€ as paid',
            style: AppText.bodyMediumEmph.copyWith(
              color: hasPaid ? BrandColors.text2 : BrandColors.text1,
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
