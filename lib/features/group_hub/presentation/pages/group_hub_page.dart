import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/cards/group_event_card.dart';
import '../../../../shared/components/cards/memory_card.dart';
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

  // Scroll snap state and controllers
  bool _isSnapped = false;
  late ScrollController _eventsScrollController;
  late ScrollController _expensesScrollController;
  late ScrollController _memoriesScrollController;

  // Track primary scroll axis to detect vertical vs horizontal movement
  Axis? _primaryScrollAxis;

  // Prevent multiple rapid unsnap calls
  bool _isUnsnapping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeExpenseParticipants();
    _initializeScrollControllers();
  }

  void _initializeScrollControllers() {
    _eventsScrollController = ScrollController();
    _expensesScrollController = ScrollController();
    _memoriesScrollController = ScrollController();

    // Listen for scroll down at the top of section scrolls to unsnap
    _eventsScrollController.addListener(_onSectionScrollChanged);
    _expensesScrollController.addListener(_onSectionScrollChanged);
    _memoriesScrollController.addListener(_onSectionScrollChanged);
  }

  void _onSectionScrollChanged() {
    final currentController = _getCurrentSectionScrollController();
    if (currentController == null || !currentController.hasClients) return;

    final pixels = currentController.position.pixels;
    final direction = currentController.position.userScrollDirection;

    // If scrolling down and at/near the top of section, unsnap
    // Check for pixels <= 1 to account for floating point precision and overscroll
    if (_isSnapped &&
        !_isUnsnapping &&
        pixels <= 1.0 &&
        direction == ScrollDirection.forward) {
      _isUnsnapping = true;
      _setSnapState(false);
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _isUnsnapping = false;
      });
    }
  }

  ScrollController? _getCurrentSectionScrollController() {
    switch (_tabController.index) {
      case 0:
        return _eventsScrollController;
      case 1:
        return _expensesScrollController;
      case 2:
        return _memoriesScrollController;
      default:
        return null;
    }
  }

  void _setSnapState(bool snapped) {
    if (_isSnapped != snapped) {
      setState(() {
        _isSnapped = snapped;
      });
    }
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
    _eventsScrollController.dispose();
    _expensesScrollController.dispose();
    _memoriesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: GestureDetector(
          // Detect vertical drag up to snap when not snapped
          onVerticalDragUpdate: (details) {
            if (!_isSnapped && details.delta.dy < 0) {
              // Only snap if drag is primarily vertical (not diagonal)
              final horizontalMovement = details.delta.dx.abs();
              final verticalMovement = details.delta.dy.abs();

              if (verticalMovement > horizontalMovement * 1.5) {
                // Trigger snap immediately
                _setSnapState(true);
              }
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: _isSnapped ? _buildSnappedView() : _buildNormalView(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CommonAppBar(
      title: _isSnapped ? widget.groupName : '',
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
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Track scroll start to determine primary axis
    if (notification is ScrollStartNotification) {
      _primaryScrollAxis = null; // Reset
      return false;
    }

    if (notification is ScrollUpdateNotification && !_isSnapped) {
      final scrollDelta = notification.scrollDelta;
      final axis = notification.metrics.axis;

      // On first update, determine the primary scroll axis
      if (_primaryScrollAxis == null &&
          scrollDelta != null &&
          scrollDelta.abs() > 0) {
        _primaryScrollAxis = axis;
      }

      // Only respond if primary axis is vertical
      if (_primaryScrollAxis == Axis.vertical && axis == Axis.vertical) {
        if (scrollDelta != null && scrollDelta < 0) {
          // Scrolling up vertically - snap the view immediately
          _setSnapState(true);
          return true;
        }
      }
    }

    // Reset on scroll end
    if (notification is ScrollEndNotification) {
      _primaryScrollAxis = null;
    }

    return false;
  }

  Widget _buildNormalView() {
    return Column(
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
    );
  }

  Widget _buildSnappedView() {
    return Column(
      children: [
        // Segmented control fixed at top
        NotificationListener<ScrollNotification>(
          onNotification: _handleSegmentedControlScroll,
          child: _buildSegmentedControl(),
        ),

        // Content sections with individual scroll controllers
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
    );
  }

  bool _handleSegmentedControlScroll(ScrollNotification notification) {
    // When in snapped mode, detect vertical scroll down to unsnap
    if (_isSnapped && notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta;
      final axis = notification.metrics.axis;

      // Only detect vertical scrolls, not horizontal (TabBarView swipes)
      if (axis == Axis.vertical) {
        if (scrollDelta != null && scrollDelta > 0) {
          // Scrolling down vertically - unsnap immediately
          _setSnapState(false);
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildMemoriesGrid(List<GroupMemoryEntity> memories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - Gaps.xs) / 2;

        return Column(
          children: [
            for (int i = 0; i < memories.length; i += 2)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + 2 < memories.length ? Gaps.xs : 0,
                ),
                child: Row(
                  children: [
                    // First memory in row
                    Expanded(
                      child: SizedBox(
                        width: cardWidth,
                        child: MemoryCard(
                          title: memories[i].title,
                          coverImageUrl: memories[i].coverImageUrl,
                          date: memories[i].date,
                          location: memories[i].location,
                        ),
                      ),
                    ),

                    // Spacing between cards
                    const SizedBox(width: Gaps.xs),

                    // Second memory in row (if exists)
                    if (i + 1 < memories.length)
                      Expanded(
                        child: SizedBox(
                          width: cardWidth,
                          child: MemoryCard(
                            title: memories[i + 1].title,
                            coverImageUrl: memories[i + 1].coverImageUrl,
                            date: memories[i + 1].date,
                            location: memories[i + 1].location,
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: SizedBox(),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
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
          controller: _eventsScrollController,
          physics: _isSnapped
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Insets.screenH,
            right: Insets.screenH,
            top: _isSnapped ? Gaps.md : 0,
            bottom: Gaps.md,
          ),
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
          controller: _expensesScrollController,
          physics: _isSnapped
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Insets.screenH,
            right: Insets.screenH,
            top: _isSnapped ? Gaps.md : 0,
            bottom: Gaps.md,
          ),
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

        return SingleChildScrollView(
          controller: _memoriesScrollController,
          physics: _isSnapped
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Insets.screenH,
            right: Insets.screenH,
            top: _isSnapped ? Gaps.md : 0,
            bottom: Gaps.lg,
          ),
          child: _buildMemoriesGrid(memories),
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
