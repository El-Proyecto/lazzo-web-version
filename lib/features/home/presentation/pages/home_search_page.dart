import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/recent_memory_card.dart';
import '../../../../shared/components/cards/payment_summary_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/layouts/main_layout_providers.dart';
import '../../../../routes/app_router.dart';
import '../../../memory/data/fakes/fake_memory_repository.dart';
import '../../../inbox/presentation/providers/payments_provider.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/entities/payment_summary_entity.dart';
import '../providers/home_event_providers.dart';
import 'package:intl/intl.dart';

/// Home search page - search across all home content
class HomeSearchPage extends ConsumerStatefulWidget {
  const HomeSearchPage({super.key});

  @override
  ConsumerState<HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends ConsumerState<HomeSearchPage> {
  String _searchQuery = '';

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Date and Location to be decided';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
  }

  bool _matchesSearch(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  bool _matchesDateSearch(DateTime? date, String query) {
    if (date == null) return false;

    // Format: "Fri, 20 Dec"
    final formatted = _formatEventDate(date);
    if (_matchesSearch(formatted, query)) return true;

    // Format: "20 December"
    final fullMonth = DateFormat('d MMMM').format(date);
    if (_matchesSearch(fullMonth, query)) return true;

    // Format: "20/12/2025"
    final numeric = DateFormat('dd/MM/yyyy').format(date);
    if (_matchesSearch(numeric, query)) return true;

    // Day only
    if (_matchesSearch(date.day.toString(), query)) return true;

    return false;
  }

  List<HomeEventEntity> _filterEvents(
    List<HomeEventEntity> events,
    String query,
  ) {
    if (query.isEmpty) return events;

    return events.where((event) {
      // Search by name
      if (_matchesSearch(event.name, query)) return true;

      // Search by location
      if (event.location != null && _matchesSearch(event.location!, query)) {
        return true;
      }

      // Search by group name
      if (event.groupName != null && _matchesSearch(event.groupName!, query)) {
        return true;
      }

      // Search by date
      if (_matchesDateSearch(event.date, query)) return true;

      return false;
    }).toList();
  }

  List<RecentMemoryEntity> _filterMemories(
    List<RecentMemoryEntity> memories,
    String query,
  ) {
    if (query.isEmpty) return memories;

    return memories.where((memory) {
      // Search by title
      if (_matchesSearch(memory.eventName, query)) return true;

      // Search by location
      if (memory.location != null && _matchesSearch(memory.location!, query)) {
        return true;
      }

      // Search by date
      if (_matchesDateSearch(memory.date, query)) return true;

      return false;
    }).toList();
  }

  List<PaymentSummaryEntity> _filterPayments(
    List<PaymentSummaryEntity> payments,
    String query,
  ) {
    if (query.isEmpty) return payments;

    return payments.where((payment) {
      // Search by user name
      if (_matchesSearch(payment.userName, query)) return true;

      // Search by amount
      final amount = payment.amount.abs().toStringAsFixed(2);
      if (_matchesSearch(amount, query)) return true;

      return false;
    }).toList();
  }

  EventSmallCardState _mapStatusToSmallCardState(HomeEventStatus status) {
    switch (status) {
      case HomeEventStatus.pending:
        return EventSmallCardState.pending;
      case HomeEventStatus.confirmed:
        return EventSmallCardState.confirmed;
      default:
        return EventSmallCardState.confirmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmedEventsAsync = ref.watch(confirmedEventsControllerProvider);
    final pendingEventsAsync = ref.watch(homeEventsControllerProvider);
    final livingAndRecapEventsAsync =
        ref.watch(livingAndRecapEventsControllerProvider);
    final memoriesAsync = ref.watch(recentMemoriesControllerProvider);
    final paymentsAsync = ref.watch(paymentSummariesControllerProvider);

    // Filter results based on search query
    final filteredConfirmed = confirmedEventsAsync.maybeWhen(
      data: (events) => _filterEvents(events, _searchQuery),
      orElse: () => <HomeEventEntity>[],
    );

    final filteredPending = pendingEventsAsync.maybeWhen(
      data: (events) => _filterEvents(events, _searchQuery),
      orElse: () => <HomeEventEntity>[],
    );

    final allLivingAndRecap = livingAndRecapEventsAsync.maybeWhen(
      data: (events) => _filterEvents(events, _searchQuery),
      orElse: () => <HomeEventEntity>[],
    );

    final filteredLiving = allLivingAndRecap
        .where((e) => e.status == HomeEventStatus.living)
        .toList();

    final filteredRecap = allLivingAndRecap
        .where((e) => e.status == HomeEventStatus.recap)
        .toList();

    final filteredMemories = memoriesAsync.maybeWhen(
      data: (memories) => _filterMemories(memories, _searchQuery),
      orElse: () => <RecentMemoryEntity>[],
    );

    final filteredPayments = paymentsAsync.maybeWhen(
      data: (payments) => _filterPayments(payments, _searchQuery),
      orElse: () => <PaymentSummaryEntity>[],
    );

    final hasResults = filteredConfirmed.isNotEmpty ||
        filteredPending.isNotEmpty ||
        filteredLiving.isNotEmpty ||
        filteredRecap.isNotEmpty ||
        filteredMemories.isNotEmpty ||
        filteredPayments.isNotEmpty;

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Search',
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios,
              color: BrandColors.text1,
              size: 20,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.screenH,
                vertical: Gaps.sm,
              ),
              child: custom.SearchBar(
                placeholder: 'Search events, memories, payments...',
                enabled: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Results
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: BrandColors.text2.withOpacity(0.5),
                          ),
                          const SizedBox(height: Gaps.md),
                          Text(
                            'Search for events, memories, or payments',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : !hasResults
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: BrandColors.text2.withOpacity(0.5),
                              ),
                              const SizedBox(height: Gaps.md),
                              Text(
                                'No results found',
                                style: AppText.bodyMedium.copyWith(
                                  color: BrandColors.text2,
                                ),
                              ),
                              const SizedBox(height: Gaps.xs),
                              Text(
                                'Try a different search term',
                                style: AppText.bodyMedium.copyWith(
                                  color: BrandColors.text2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH,
                          ),
                          children: [
                            // Live Events
                            if (filteredLiving.isNotEmpty) ...[
                              _buildSectionHeader('Live Events'),
                              const SizedBox(height: Gaps.sm),
                              ...filteredLiving.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Gaps.sm,
                                  ),
                                  child: EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.location,
                                    state: EventSmallCardState.living,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRouter.eventLiving,
                                        arguments: {'eventId': event.id},
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: Gaps.md),
                            ],

                            // Recaps
                            if (filteredRecap.isNotEmpty) ...[
                              _buildSectionHeader('Recaps'),
                              const SizedBox(height: Gaps.sm),
                              ...filteredRecap.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Gaps.sm,
                                  ),
                                  child: EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.location,
                                    state: EventSmallCardState.recap,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRouter.memory,
                                        arguments: {'memoryId': event.id},
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: Gaps.md),
                            ],

                            // Confirmed Events
                            if (filteredConfirmed.isNotEmpty) ...[
                              _buildSectionHeader('Confirmed Events'),
                              const SizedBox(height: Gaps.sm),
                              ...filteredConfirmed.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Gaps.sm,
                                  ),
                                  child: EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.date == null
                                        ? null
                                        : (event.location ??
                                            'Location to be decided'),
                                    state: _mapStatusToSmallCardState(
                                        event.status),
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRouter.event,
                                        arguments: {'eventId': event.id},
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: Gaps.md),
                            ],

                            // Pending Events
                            if (filteredPending.isNotEmpty) ...[
                              _buildSectionHeader('Pending Events'),
                              const SizedBox(height: Gaps.sm),
                              ...filteredPending.map((event) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Gaps.sm,
                                  ),
                                  child: EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.date == null
                                        ? null
                                        : (event.location ??
                                            'Location to be decided'),
                                    state: _mapStatusToSmallCardState(
                                        event.status),
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRouter.event,
                                        arguments: {'eventId': event.id},
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: Gaps.md),
                            ],

                            // Memories
                            if (filteredMemories.isNotEmpty) ...[
                              _buildSectionHeader('Recent Memories'),
                              const SizedBox(height: Gaps.sm),
                              ...filteredMemories.map((memory) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Gaps.sm,
                                  ),
                                  child: SizedBox(
                                    height: 120,
                                    child: RecentMemoryCard(
                                      memory: memory,
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRouter.memory,
                                          arguments: {
                                            'memoryId': memory.id,
                                            'eventStatus':
                                                FakeEventStatus.ended,
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: Gaps.md),
                            ],

                            // Payments
                            if (filteredPayments.isNotEmpty) ...[
                              _buildSectionHeader('Payments'),
                              const SizedBox(height: Gaps.sm),
                              Wrap(
                                spacing: Gaps.sm,
                                runSpacing: Gaps.sm,
                                children: filteredPayments.map((payment) {
                                  return SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            (Insets.screenH * 2) -
                                            Gaps.sm) /
                                        2,
                                    child: PaymentSummaryCard(
                                      payment: payment,
                                      onTap: () {
                                        // Store selected payment user ID
                                        ref
                                            .read(selectedPaymentUserIdProvider
                                                .notifier)
                                            .state = payment.userId;

                                        // Navigate to Inbox Payments tab
                                        ref
                                            .read(
                                                inboxTabIndexProvider.notifier)
                                            .state = 2;

                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: Gaps.md),
                            ],

                            const SizedBox(height: Gaps.lg),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppText.titleMediumEmph.copyWith(
        color: BrandColors.text1,
      ),
    );
  }
}
