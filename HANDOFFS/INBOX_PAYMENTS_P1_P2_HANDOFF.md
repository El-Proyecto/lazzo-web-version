# Inbox Payments Feature — P1 to P2 Handoff

**Feature:** Payment system with grouping, net calculations, and bottom sheet details  
**Status:** P1 Complete ✅ | Ready for P2 Implementation  
**Date:** October 3, 2025

---

## Summary

The payment system has been fully implemented for Role P1, including:
- ✅ Domain entities and repository contracts
- ✅ Complete UI components with tokenized design
- ✅ State management with Riverpod providers  
- ✅ Fake repository with comprehensive test data
- ✅ Payment grouping logic with net calculations
- ✅ Bottom sheet details with bidirectional expense display

The system is **ready for Role P2** to implement Supabase data sources and real repository implementations.

---

## Domain Contracts (Stable - Do Not Change)

### PaymentEntity
Located: `lib/features/inbox/domain/entities/payment_entity.dart`

**Required fields for UI:**
```dart
class PaymentEntity {
  final String id;                    // Unique payment identifier
  final String title;                 // Display title ("Restaurant dinner")
  final String description;           // Detailed description
  final PaymentType type;             // expense, split, debt, request
  final PaymentStatus status;         // pending, paid, overdue, cancelled
  final double amount;                // Payment amount (positive number)
  final String currency;              // Currency code (default: 'EUR')
  final DateTime createdAt;           // Payment creation timestamp
  final DateTime? dueDate;            // Optional due date
  final String? fromUserId;           // Who pays (null = current user pays)
  final String? toUserId;             // Who receives (null = current user receives)
  final String? groupId;              // Associated group ID
  final String? eventId;              // Associated event ID
  final List<String>? participantIds; // Split payment participants
}
```

**Enums:**
```dart
enum PaymentType { expense, split, debt, request }
enum PaymentStatus { pending, paid, overdue, cancelled }
```

### PaymentGroup
Located: `lib/features/inbox/domain/entities/payment_group.dart`

Handles grouping and net calculation logic for payments. **Do not modify** - contains complex bidirectional payment logic.

### Repository Interface (Implement in Data Layer)
Located: `lib/features/inbox/domain/repositories/payment_repository.dart`

```dart
abstract class PaymentRepository {
  // Get paginated payments with optional filters
  Future<List<PaymentEntity>> getPayments({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  });

  // Get payments where others owe current user
  Future<List<PaymentEntity>> getPaymentsOwedToUser(String userId);

  // Get payments where current user owes others
  Future<List<PaymentEntity>> getPaymentsUserOwes(String userId);

  // Get single payment by ID
  Future<PaymentEntity?> getPaymentById(String id);

  // Mark payment as paid (update status)
  Future<void> markAsPaid(String id);

  // Calculate total amounts (for validation)
  Future<double> getTotalOwedToUser(String userId);
  Future<double> getTotalUserOwes(String userId);

  // Real-time payment updates
  Stream<List<PaymentEntity>> watchPayments();
}
```

---

## Data Requirements for P2

### Supabase Schema Requirements

**Core payments table:**
```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type payment_type NOT NULL,  -- enum: expense, split, debt, request
  status payment_status NOT NULL DEFAULT 'pending',  -- enum: pending, paid, overdue, cancelled
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'EUR',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  due_date TIMESTAMPTZ,
  from_user_id UUID REFERENCES auth.users(id),  -- null = current user pays
  to_user_id UUID REFERENCES auth.users(id),    -- null = current user receives
  group_id UUID REFERENCES groups(id),
  event_id UUID REFERENCES events(id),
  participant_ids UUID[] -- for split payments
);
```

**Required indexes:**
```sql
CREATE INDEX idx_payments_from_user ON payments(from_user_id, status);
CREATE INDEX idx_payments_to_user ON payments(to_user_id, status);
CREATE INDEX idx_payments_group ON payments(group_id, created_at DESC);
CREATE INDEX idx_payments_event ON payments(event_id, created_at DESC);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);
```

**Row Level Security (RLS):**
- Users can only see payments where they are `from_user_id`, `to_user_id`, or in `participant_ids`
- Users can only see payments from groups they belong to
- Users can only see payments from events they have access to

### Data Source Implementation Path

1. **Create data source:** `lib/features/inbox/data/data_sources/payment_remote_data_source.dart`
2. **Create models:** `lib/features/inbox/data/models/payment_model.dart`
3. **Implement repository:** `lib/features/inbox/data/repositories/payment_repository_impl.dart`
4. **Add DI override** in `main.dart`

---

## UI Components (Complete - No Changes Needed)

### Shared Components
- ✅ `InboxPaymentCard` - Main payment card with notification/paid actions
- ✅ `PaymentDetailsBottomSheet` - Detailed expense breakdown
- ✅ `PaymentsSection` - Section with grouped payments and totals

### Key UI Features
- ✅ **Net calculation display** - Shows net amounts between users
- ✅ **Bidirectional expenses** - Handles positive/negative payments  
- ✅ **Real-time totals** - Calculated from grouped net amounts
- ✅ **Custom bottom sheet** - Person name + amount in header
- ✅ **Proper spacing** - Grab bar with top margin

### State Management (Complete)
- ✅ `PaymentsOwedToUserController` - Manages "Owed to you" section
- ✅ `PaymentsUserOwesController` - Manages "You owe" section
- ✅ All providers properly wired with fake repositories
- ✅ AsyncValue error/loading state handling

---

## Current DI Setup

**Provider location:** `lib/features/inbox/presentation/providers/payments_provider.dart`

```dart
// Repository provider - currently points to fake
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return FakePaymentRepository();
});
```

**Required P2 override in `main.dart`:**
```dart
// Payment repo -> real (Supabase)
paymentRepositoryProvider.overrideWith(
  (ref) => PaymentRepositoryImpl(
    PaymentRemoteDataSource(Supabase.instance.client),
  ),
),
```

---

## Fake Data Reference

The `FakePaymentRepository` provides comprehensive test scenarios:
- ✅ Multiple users with bidirectional payments
- ✅ Various payment types and statuses
- ✅ Mixed positive/negative amounts for net calculation testing
- ✅ Group and event associations
- ✅ Realistic payment amounts and dates

**Test users:** 'ana', 'maria', 'joao', 'sofia' with varied payment relationships.

---

## Critical Notes for P2

### ⚠️ **DO NOT MODIFY:**
1. **PaymentEntity fields** - UI depends on exact field structure
2. **PaymentGroup logic** - Contains complex net calculation algorithms
3. **Repository method signatures** - Providers are already wired
4. **Enum values** - Used throughout UI for status/type display

### ✅ **IMPLEMENT:**
1. **Supabase data source** with proper error handling
2. **DTO model** with JSON serialization  
3. **Repository implementation** calling data source
4. **RLS policies** for secure data access
5. **Real-time subscriptions** for payment updates

### 🔧 **VALIDATION:**
1. Verify net calculation totals match fake data behavior
2. Test bidirectional payment scenarios
3. Ensure proper currency handling (all EUR for MVP)
4. Validate RLS with different user contexts

---

## Testing Scenarios

1. **Basic payments** - Simple one-way payments between users
2. **Bidirectional expenses** - Users who both owe each other money
3. **Group events** - Multiple payments within same group/event
4. **Mixed statuses** - Pending, paid, overdue payment combinations
5. **Real-time updates** - Payment status changes reflecting immediately

---

## Definition of Done for P2

- [ ] Supabase schema created with proper RLS
- [ ] Data source implements all repository methods
- [ ] DTO model handles all PaymentEntity fields
- [ ] Repository implementation passes integration tests
- [ ] DI override added to main.dart
- [ ] Real-time payment updates working
- [ ] Net calculation totals match expected behavior
- [ ] All fake scenarios work with real data
- [ ] RLS policies tested with multiple users

---

**Contact:** P1 implementation complete. Ready for P2 Supabase integration.