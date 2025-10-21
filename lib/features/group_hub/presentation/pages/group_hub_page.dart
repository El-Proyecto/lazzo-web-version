import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/cards/group_event_card.dart';
import '../../../../shared/components/sections/memories_section.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/group_hub_providers.dart';
import '../widgets/group_expense_card.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/group_memory_entity.dart';
import '../widgets/expense_detail_bottom_sheet.dart';
import '../../domain/entities/expense_participant_entity.dart';

class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;

  const GroupHubPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
    required this.memberCount,
  });

  @override
  ConsumerState<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends ConsumerState<GroupHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<ExpenseParticipant>> _expenseParticipants = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeExpenseParticipants();
  }

  void _initializeExpenseParticipants() {
    // Initialize participants for each expense
    final expenses = ['1', '2', '3', '4'];
    for (final expenseId in expenses) {
      _expenseParticipants[expenseId] = _createMockParticipants(expenseId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings, color: BrandColors.text1),
          onPressed: () {
            // TODO: Navigate to group settings
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Group information section
            _buildGroupInfo(),
            const SizedBox(height: Gaps.lg),

            // Segmented control
            _buildSegmentedControl(),
            const SizedBox(height: Gaps.md),

            // Content sections
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsSection(),
                  _buildExpensesSection(),
                  _buildMemoriesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Column(
        children: [
          // Group photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: BrandColors.bg3,
              image: widget.groupPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.groupPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.groupPhotoUrl == null
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : null,
          ),
          const SizedBox(height: Gaps.md),

          // Group name
          Text(
            widget.groupName,
            style: AppText.headlineMedium.copyWith(
              color: BrandColors.text1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.xs),

          // Member count
          Text(
            '${widget.memberCount} Members',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return PageSegmentedControl(
      controller: _tabController,
      labels: const ['Events', 'Expenses', 'Memories'],
    );
  }

  Widget _buildEventsSection() {
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));

    return eventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading events',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: () {
                ref
                    .read(groupEventsProvider(widget.groupId).notifier)
                    .refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
              ),
            ),
          ],
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_outlined,
            title: 'No events yet',
            subtitle: 'Events will appear here when created',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
          itemCount: events.length + 1,
          separatorBuilder: (context, index) {
            if (index == events.length - 1) {
              // After last event, no separator (bottom padding handled below)
              return const SizedBox.shrink();
            }
            return const SizedBox(height: Gaps.md);
          },
          itemBuilder: (context, index) {
            if (index < events.length) {
              final event = events[index];
              return GroupEventCard(
                event: event,
                onTap: () {
                  // TODO: Navigate to event detail
                  print('Navigate to event: ${event.id}');
                },
                onVoteChanged: (eventId, vote) {
                  // TODO: Implement vote persistence
                  print('Vote changed for event $eventId: $vote');
                },
              );
            } else {
              return const SizedBox(height: Gaps.md);
            }
          },
        );
      },
    );
  }

  Widget _buildExpensesSection() {
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));

    return expensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading expenses',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: () {
                ref
                    .read(groupExpensesProvider(widget.groupId).notifier)
                    .refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
              ),
            ),
          ],
        ),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            subtitle: 'Group expenses will appear here',
          );
        }

        // Sort expenses by payment status and date
        // Order: Active -> Paid -> Settled (within each group: most recent first)
        final sortedExpenses = List<GroupExpenseEntity>.from(expenses)
          ..sort((a, b) {
            final statusA = _getPaymentStatus(a);
            final statusB = _getPaymentStatus(b);

            // Define priority order: Active (empty) = 0, Paid = 1, Settled = 2
            int getPriority(String status) {
              switch (status) {
                case 'Settled':
                  return 2;
                case 'Paid':
                  return 1;
                default:
                  return 0; // Active expenses (empty status)
              }
            }

            final priorityA = getPriority(statusA);
            final priorityB = getPriority(statusB);

            // First sort by priority
            if (priorityA != priorityB) {
              return priorityA.compareTo(priorityB);
            }

            // If same priority, sort by date (most recent first)
            return b.date.compareTo(a.date);
          });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
          itemCount: sortedExpenses.length + 1,
          separatorBuilder: (context, index) {
            if (index == sortedExpenses.length - 1) {
              // After last expense, no separator (bottom padding handled below)
              return const SizedBox.shrink();
            }
            return const SizedBox(height: Gaps.md);
          },
          itemBuilder: (context, index) {
            if (index < sortedExpenses.length) {
              final expense = sortedExpenses[index];
              return GroupExpenseCard(
                expense: expense,
                eventName: _getEventName(expense.id),
                userAmount: _calculateUserAmount(expense),
                totalAmount: expense.amount,
                isOwedToUser: _isOwedToUser(expense),
                paymentStatus: _getPaymentStatus(expense),
                onTap: () {
                  _showExpenseDetail(expense);
                },
              );
            } else {
              return const SizedBox(height: Gaps.md);
            }
          },
        );
      },
    );
  }

  Widget _buildMemoriesSection() {
    final memoriesAsync = ref.watch(groupMemoriesProvider(widget.groupId));

    return memoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading memories',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
      data: (memories) {
        if (memories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No memories yet',
            subtitle: 'Group memories will appear here',
          );
        }

        return MemoriesSection<GroupMemoryEntity>(
          memories: memories,
          enableScroll: true,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              title,
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              subtitle,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for expense cards
  String _getEventName(String expenseId) {
    switch (expenseId) {
      case '1':
        return 'Churrasco Casa Marco';
      case '2':
        return 'Concert Night';
      case '3':
        return 'Weekend Trip';
      case '4':
        return 'BBQ Weekend';
      default:
        return 'Group Event';
    }
  }

  double _calculateUserAmount(GroupExpenseEntity expense) {
    // Mock calculation - in real app this would be calculated based on split logic
    return expense.amount / 4; // Assuming 4 people split
  }

  bool _isOwedToUser(GroupExpenseEntity expense) {
    // Fixed logic: if current user paid, others owe them (positive amount)
    // If someone else paid, current user owes them (negative amount)
    return expense.paidBy == 'current_user';
  }

  String _getPaymentStatus(GroupExpenseEntity expense) {
    final participants = _expenseParticipants[expense.id] ?? [];
    final currentUserParticipant = participants.firstWhere(
      (p) => p.id == 'current_user',
      orElse: () => const ExpenseParticipant(
        id: 'current_user',
        name: 'You',
        amount: 0,
        hasPaid: false,
      ),
    );

    if (expense.isSettled) {
      return 'Settled';
    }

    // If current user has paid their part
    if (currentUserParticipant.hasPaid) {
      return 'Paid';
    }

    return ''; // Show total amount instead
  }

  void _showExpenseDetail(GroupExpenseEntity expense) {
    final participants = _expenseParticipants[expense.id] ?? [];
    final isCurrentUserPayer = expense.paidBy == 'current_user';

    ExpenseDetailBottomSheet.show(
      context: context,
      expense: expense,
      participants: participants,
      isCurrentUserPayer: isCurrentUserPayer,
      onMarkAsPaid: () {
        _handleMarkAsPaid(expense.id);
      },
      onNotifyParticipant: (participantId) {
        _handleNotifyParticipant(expense.id, participantId);
      },
    );
  }

  void _handleMarkAsPaid(String expenseId) {
    setState(() {
      final participants = _expenseParticipants[expenseId];
      if (participants != null) {
        final currentUserIndex =
            participants.indexWhere((p) => p.id == 'current_user');
        if (currentUserIndex != -1) {
          _expenseParticipants[expenseId]![currentUserIndex] =
              participants[currentUserIndex].copyWith(
            hasPaid: true,
            paidAt: DateTime.now(),
          );
        }
      }
    });

    print('Mark expense $expenseId as paid');
  }

  void _handleNotifyParticipant(String expenseId, String participantId) {
    print('Notify participant: $participantId for expense: $expenseId');
  }

  List<ExpenseParticipant> _createMockParticipants(String expenseId) {
    const amountPerPerson = 25.0; // Mock amount per person
    final baseDate =
        DateTime.now().subtract(const Duration(days: 2)); // Mock base date

    switch (expenseId) {
      case '1': // Dinner at Restaurant - Marco paid
        return [
          ExpenseParticipant(
            id: 'marco',
            name: 'Marco',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate,
          ),
          const ExpenseParticipant(
            id: 'current_user',
            name: 'You',
            amount: amountPerPerson,
            hasPaid: false,
          ),
          const ExpenseParticipant(
            id: 'ana',
            name: 'Ana',
            amount: amountPerPerson,
            hasPaid: false,
          ),
          const ExpenseParticipant(
            id: 'joao',
            name: 'João',
            amount: amountPerPerson,
            hasPaid: false,
          ),
        ];
      case '2': // Concert Tickets - Ana paid
        return [
          ExpenseParticipant(
            id: 'ana',
            name: 'Ana',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate,
          ),
          ExpenseParticipant(
            id: 'current_user',
            name: 'You',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate.add(const Duration(hours: 2)),
          ),
          ExpenseParticipant(
            id: 'marco',
            name: 'Marco',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate.add(const Duration(hours: 1)),
          ),
          ExpenseParticipant(
            id: 'joao',
            name: 'João',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate.add(const Duration(hours: 3)),
          ),
        ];
      case '3': // Gas for Trip - João paid
        return [
          ExpenseParticipant(
            id: 'joao',
            name: 'João',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate,
          ),
          const ExpenseParticipant(
            id: 'current_user',
            name: 'You',
            amount: amountPerPerson,
            hasPaid: false,
          ),
          ExpenseParticipant(
            id: 'marco',
            name: 'Marco',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate.add(const Duration(hours: 4)),
          ),
          const ExpenseParticipant(
            id: 'ana',
            name: 'Ana',
            amount: amountPerPerson,
            hasPaid: false,
          ),
        ];
      case '4': // Groceries for BBQ - Current user paid
        return [
          ExpenseParticipant(
            id: 'current_user',
            name: 'You',
            amount: amountPerPerson,
            hasPaid: true,
            paidAt: baseDate,
          ),
          const ExpenseParticipant(
            id: 'marco',
            name: 'Marco',
            amount: amountPerPerson,
            hasPaid: false,
          ),
          const ExpenseParticipant(
            id: 'ana',
            name: 'Ana',
            amount: amountPerPerson,
            hasPaid: false,
          ),
          const ExpenseParticipant(
            id: 'joao',
            name: 'João',
            amount: amountPerPerson,
            hasPaid: false,
          ),
        ];
      default:
        return [];
    }
  }
}
