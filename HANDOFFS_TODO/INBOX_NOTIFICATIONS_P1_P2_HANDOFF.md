# Inbox Notifications Feature — P1 to P2 Handoff

**Feature:** Notifications system with push, feed, and action categories  
**Status:** P1 Complete ✅ | Ready for P2 Implementation  
**Date:** October 3, 2025

---

## Summary

The notifications system has been fully implemented for Role P1, including:
- ✅ Domain entities and repository contracts aligned with `notifications_catalog.md`
- ✅ Complete UI components with tokenized design
- ✅ State management with Riverpod providers  
- ✅ Fake repository with comprehensive test scenarios
- ✅ Push, feed, and action notification categories
- ✅ Dynamic message formatting with placeholders
- ✅ Deeplink generation for navigation

The system is **ready for Role P2** to implement Supabase data sources and real repository implementations.

---

## Domain Contracts (Stable - Do Not Change)

### NotificationEntity
Located: `lib/features/inbox/domain/entities/notification_entity.dart`

**Required fields for UI:**
```dart
class NotificationEntity {
  final String id;                       // Unique notification identifier
  final String title;                    // Display title
  final String description;              // Message template with placeholders
  final NotificationType type;           // Specific notification type
  final NotificationCategory category;   // push, notifications, actions
  final NotificationPriority priority;   // low, medium, high
  final DateTime createdAt;              // Notification timestamp
  final bool isRead;                     // Read status (default: false)
  final String? actionText;              // Optional action button text
  final String? actionUrl;               // Optional action URL
  final String? deeplink;                // Navigation deeplink
  final String? groupId;                 // Associated group
  final String? eventId;                 // Associated event
  final String? eventEmoji;              // Event emoji for display
  
  // Placeholder fields for message formatting
  final String? userName;                // {user} placeholder
  final String? groupName;               // {group} placeholder  
  final String? eventName;               // {event} placeholder
  final String? amount;                  // {amount} placeholder
  final String? hours;                   // {hours} placeholder
  final String? mins;                    // {mins} placeholder
  final String? date;                    // {date} placeholder
  final String? time;                    // {time} placeholder
  final String? place;                   // {place} placeholder
  final String? device;                  // {device} placeholder
  final String? note;                    // For payment notes
}
```

**Enums (Based on notifications_catalog.md):**
```dart
enum NotificationCategory { push, notifications, actions }

enum NotificationPushType {
  groupInviteReceived, eventStartsSoon, eventLive, eventEndsSoon,
  eventExtended, uploadsOpen, uploadsClosing, memoryReady,
  paymentsRequest, paymentsAddedYouOwe, paymentsPaidYou,
  chatMention, securityNewLogin
}

enum NotificationFeedType {
  groupInviteAccepted, groupRenamed, groupPhotoChanged,
  eventCreated, eventDateSet, eventLocationSet, eventDetailsUpdated,
  eventCanceled, eventRestored, eventConfirmed, suggestionAdded
}

enum NotificationPriority { low, medium, high }
```

**Key Methods:**
- `formattedMessage` - Replaces placeholders with actual values
- `resolvedDeeplink` - Generates navigation deeplinks based on type and IDs

### Repository Interface (Implement in Data Layer)
Located: `lib/features/inbox/domain/repositories/notification_repository.dart`

```dart
abstract class NotificationRepository {
  // Get paginated notifications with filters
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    NotificationCategory? category,
  });

  // Get single notification by ID
  Future<NotificationEntity?> getNotificationById(String id);

  // Mark single notification as read
  Future<void> markAsRead(String id);

  // Mark all notifications as read
  Future<void> markAllAsRead();

  // Get unread count for badge display
  Future<int> getUnreadCount();

  // Delete notification
  Future<void> deleteNotification(String id);

  // Real-time notification updates
  Stream<List<NotificationEntity>> watchNotifications();
}
```

---

## Data Requirements for P2

### Supabase Schema Requirements

**Core notifications table:**
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type notification_type NOT NULL,
  category notification_category NOT NULL,
  priority notification_priority NOT NULL DEFAULT 'medium',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  action_text TEXT,
  action_url TEXT,
  deeplink TEXT,
  group_id UUID REFERENCES groups(id),
  event_id UUID REFERENCES events(id),
  event_emoji TEXT,
  user_name TEXT,
  group_name TEXT,
  event_name TEXT,
  amount TEXT,
  hours TEXT,
  mins TEXT,
  date TEXT,
  time TEXT,
  place TEXT,
  device TEXT,
  note TEXT,
  recipient_user_id UUID NOT NULL REFERENCES auth.users(id)
);
```

**Required indexes:**
```sql
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(recipient_user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_category ON notifications(category, created_at DESC);
CREATE INDEX idx_notifications_group ON notifications(group_id, created_at DESC);
CREATE INDEX idx_notifications_event ON notifications(event_id, created_at DESC);
```

**Row Level Security (RLS):**
- Users can only see notifications where they are `recipient_user_id`
- Users can only update `is_read` status on their own notifications
- Users can only delete their own notifications

### Message Templates (Based on notifications_catalog.md)

**Push notifications:**
- `groupInviteReceived`: "{user} invited you to join **{group}**."
- `eventStartsSoon`: "**{event}** starts in {mins} min."
- `eventLive`: "**{event}** is live now."
- `paymentsRequest`: "{user} requested **{amount}** for {note}."

**Feed notifications:**
- `groupInviteAccepted`: "{user} joined **{group}**."
- `eventCreated`: "New event **{event}** in **{group}**."
- `eventDateSet`: "Date confirmed for **{event}**: {date}, {time}."

### Data Source Implementation Path

1. **Create data source:** `lib/features/inbox/data/data_sources/notification_remote_data_source.dart`
2. **Create models:** `lib/features/inbox/data/models/notification_model.dart`
3. **Implement repository:** `lib/features/inbox/data/repositories/notification_repository_impl.dart`
4. **Add DI override** in `main.dart`

---

## UI Components (Complete - No Changes Needed)

### Shared Components
- ✅ `NotificationCard` - Main notification display with avatar and message
- ✅ `NotificationsSection` - Section with grouped notifications

### Key UI Features
- ✅ **Dynamic avatars** - Event emoji or group photo based on type
- ✅ **Message formatting** - Placeholder replacement with bold formatting
- ✅ **Read/unread states** - Visual indicators for notification status
- ✅ **Deeplink navigation** - Tap actions for contextual navigation
- ✅ **Time display** - Relative time formatting (X min ago, Yesterday, etc.)

### State Management (Complete)
- ✅ `NotificationsController` - Manages notification list
- ✅ `UnreadCountController` - Manages unread badge count
- ✅ All providers properly wired with fake repositories
- ✅ AsyncValue error/loading state handling

---

## Current DI Setup

**Provider location:** `lib/features/inbox/presentation/providers/notifications_provider.dart`

```dart
// Repository provider - currently points to fake
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FakeNotificationRepository();
});
```

**Required P2 override in `main.dart`:**
```dart
// Notification repo -> real (Supabase)
notificationRepositoryProvider.overrideWith(
  (ref) => NotificationRepositoryImpl(
    NotificationRemoteDataSource(Supabase.instance.client),
  ),
),
```

---

## Fake Data Reference

The `FakeNotificationRepository` provides comprehensive test scenarios:
- ✅ All notification types from catalog (push, feed, actions)
- ✅ Various priority levels and read states
- ✅ Complete placeholder data for message formatting
- ✅ Realistic timestamps and deadlines
- ✅ Group and event associations
- ✅ Deeplink examples for all supported navigation patterns

**Test scenarios:** Group invites, event updates, payment notifications, memory ready, uploads deadlines, security alerts.

---

## Critical Notes for P2

### ⚠️ **DO NOT MODIFY:**
1. **NotificationEntity fields** - UI depends on exact field structure
2. **Message templates** - Must match `notifications_catalog.md` exactly
3. **Repository method signatures** - Providers are already wired
4. **Enum values** - Used throughout UI for type-specific formatting
5. **Deeplink patterns** - Follow existing format: `lazzo://type/id`

### ✅ **IMPLEMENT:**
1. **Supabase data source** with proper error handling
2. **DTO model** with JSON serialization  
3. **Repository implementation** calling data source
4. **RLS policies** for secure notification access
5. **Real-time subscriptions** for live notification updates
6. **Deduplication logic** (5-min window as per catalog)
7. **TTL handling** for time-sensitive notifications

### 🔧 **VALIDATION:**
1. Verify placeholder replacement works correctly
2. Test deeplink generation for all notification types
3. Ensure proper RLS with different user contexts
4. Validate unread count accuracy
5. Test real-time notification delivery

---

## Testing Scenarios

1. **Push notifications** - High-priority alerts (invites, event start, payments)
2. **Feed notifications** - Informational updates (group changes, event updates)
3. **Placeholder formatting** - All template variables replaced correctly
4. **Deeplink navigation** - Proper routing to groups, events, payments
5. **Real-time updates** - Live notification delivery and read status sync
6. **Badge counts** - Accurate unread notification counting
7. **Category filtering** - Separate push/feed/action notification streams

---

## Notification Delivery Rules (From Catalog)

- **Dedup**: Collapse duplicates within 5 min (e.g., multiple RSVP updates)
- **TTL**: Upload window entries expire when time runs out; event reminders auto-remove after end
- **Mute**: Per-group mute silences push but still lists in feed
- **Push defaults**: Enabled. Respect device/OS settings and in-app mute per group

---

## Definition of Done for P2

- [ ] Supabase schema created with proper RLS and indexes
- [ ] Data source implements all repository methods
- [ ] DTO model handles all NotificationEntity fields including placeholders
- [ ] Repository implementation passes integration tests
- [ ] DI override added to main.dart
- [ ] Real-time notification updates working
- [ ] Message formatting with placeholders working correctly
- [ ] Deeplink generation working for all notification types
- [ ] Unread count badge accurate and real-time
- [ ] Deduplication and TTL logic implemented
- [ ] RLS policies tested with multiple users

---

**Contact:** P1 implementation complete. Ready for P2 Supabase integration.