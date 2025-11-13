# Event Living Mode Feature - P1 to P2 Handoff Documentation

---------------------------------- DONE ----------------------------------

**Date:** 13 de novembro de 2025  
**Feature:** Event Living Mode page - event in progress with photo upload, chat, and host controls  
**P1 Status:** ✅ COMPLETE - Ready for P2  
**P2 Focus:** Data layer implementation for expenses, time management, and real-time photo sync  

## 📋 Executive Summary

The Event Living Mode feature UI layer (P1) is complete with all interactive components, mode-based styling (purple accent), host controls, and expenses integration. All components follow Clean Architecture principles and use design tokens. P2 needs to implement the data layer with Supabase real-time features and storage integration.

---

## ✅ P1 DELIVERABLES COMPLETED

### 🎨 **UI COMPONENTS (ALL TOKENIZED & STATELESS)**

#### **Shared Components Used**
All components properly tokenized and reusable:
- ✅ `CommonAppBar` - Standard app bar with back navigation
- ✅ `EventHeader` - Event title, emoji, location, and date display
- ✅ `LocationWidget` - Location display with address support
- ✅ `AddExpenseBottomSheet` - Modal for adding new expenses (purple accent in living mode)

#### **Feature-Specific Widgets** (`lib/features/event/presentation/widgets/`)
- ✅ `LivingTimeLeftPill` - Non-interactive time left display for participants
- ✅ `HostTimeControls` - Interactive time management controls for event host
- ✅ `LivingActionRow` - Action buttons (Add Expense, Take Photo, View Memory)
- ✅ `ChatPreviewWidget` - Chat preview with mode-based styling (purple/green)
- ✅ `EventExpensesWidget` - Expenses display with mode parameter (replaces LivingExpensesWidget)

**Key Features Implemented:**
- ✅ **Mode-Based Styling**: Purple accent (#8B5CF6) for all living mode components
- ✅ **Host Controls**: Time management (add time, end now) with visual elevation
- ✅ **Participant View**: Simple time left pill without controls
- ✅ **Expenses Integration**: Total display with add button (green for planning, purple for living)
- ✅ **Action Row**: Three buttons with center purple button for photos
- ✅ **Chat Preview**: Mode parameter (ChatMode.living) for purple accent

---

## 🏗️ **ARCHITECTURE LAYER STATUS**

### ✅ **Domain Layer** (`lib/features/event/domain/`)

#### **Entities** - Business models used
- ✅ `EventDetail` - Extended event information with hostId
- ✅ `ChatMessage` - Event chat messages
- ✅ `GroupExpenseEntity` (`group_hub` feature) - Expense information with participantIds

**New Fields Added:**
- ✅ `GroupExpenseEntity.participantIds` - List of participant IDs for expense detail view

#### **Enums Used**
- ✅ `ChatMode` (planning/living) - Mode-based UI switching throughout the app
- ✅ `EventStatus` (pending/confirmed) - Event confirmation state

### ✅ **Presentation Layer** (`lib/features/event/presentation/`)

#### **Complete EventLivingPage** - Main orchestrating page
- ✅ **AsyncValue state management** for event data and messages
- ✅ **Loading/Error/Success states** for all components
- ✅ **Conditional rendering** based on hostId (host controls vs participant view)
- ✅ **Mode-based styling** with ChatMode.living parameter
- ✅ **Navigation** back to previous screen
- ✅ **TODO markers** for P2 implementation (auth, real actions)

#### **Widgets Implementation Details**

**LivingTimeLeftPill** (`living_time_left_pill.dart`)
```dart
// Simple pill displaying time left
// - Purple accent color (#8B5CF6)
// - Shadow with purple glow (alpha: 0.4, blur: 12, offset: (0, 4))
// - Time calculation with relative display ("X min left", "Ending soon")
// - Updates based on eventEndTime
```

**HostTimeControls** (`host_time_controls.dart`)
```dart
// Interactive controls for event host
// - Time left pill with tap to manage time
// - Bottom sheet with time picker (CupertinoPicker)
// - Hours (0-23) and Minutes (0-55 in 5min increments)
// - Default: 30 minutes extension
// - Purple "Add Time" button
// - Red "End Now" button (bg3 background)
// - Confirmation dialog for ending event
// - Shadow elevation on main pill
```

**LivingActionRow** (`living_action_row.dart`)
```dart
// Three action buttons
// - Add Expense (left): gray bg2, wallet icon
// - Take Photo (center): purple bg, camera icon, elevated shadow
// - View Memory (right): gray bg2, folder icon
// - All buttons: 80x80 with 12px radius
// - Purple button shadow: alpha 0.3, blur 8, offset (0, 4)
// - Callbacks for each action
```

**ChatPreviewWidget** (`chat_preview_widget.dart`)
```dart
// Chat preview with mode parameter
// - ChatMode mode parameter (planning/living)
// - Accent color: purple for living, green for planning
// - Shows latest message or empty state
// - Unread count badge
// - Tap to navigate to chat (TODO: implement route)
```

**EventExpensesWidget** (`living_expenses_widget.dart`)
```dart
// Renamed from LivingExpensesWidget to support both modes
// - ChatMode mode parameter
// - Total calculation (excludes settled expenses)
// - Color coding: red (owe), green (receive)
// - Add button color: purple (living), green (planning)
// - Group expense cards with participant avatars
// - Sorted: active by date desc, settled last
// - Empty state when no expenses
// - Tap card to show ExpenseDetailBottomSheet
```

### ✅ **State Management** (`event_providers.dart`)

#### **Providers Used**
```dart
// Event data
final eventDetailProvider = FutureProvider.family<EventDetail, String>(...);

// Chat messages
final recentMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(...);
final unreadMessageCountProvider = FutureProvider.family<int, String>(...);

// Expenses (from group_hub feature)
final groupExpensesProvider = FutureProvider.family<List<GroupExpenseEntity>, String>(...);
```

### ✅ **Data Layer Preparation**

#### **Fake Implementations** - Development data
- ✅ `FakeEventRepository` - Mock event operations
- ✅ `FakeChatRepository` - Mock chat with realistic messages
- ✅ `FakeGroupExpenseRepository` (`group_hub`) - 5 mock expenses with participants

**Mock Expenses Data:**
```dart
// 5 expenses total:
// - 4 active expenses (sorted by date desc)
// - 1 settled expense (always last)
// - Each has 2-3 participants from participantIds
// - Amounts: €12.50, €8.00, €25.00, €15.50, €30.00 (settled)
// - Realistic descriptions and dates
```

---

## 🎯 **KEY BUSINESS LOGIC IMPLEMENTED**

### **Host vs Participant Views** ✅
- Checks `event.hostId == 'current-user'` (TODO: replace with auth)
- Host: Shows `HostTimeControls` with interactive time management
- Participant: Shows `LivingTimeLeftPill` with read-only time display
- Visual differentiation: host controls have elevation/shadow

### **Time Management Flow** ✅
1. Host taps time pill → opens bottom sheet
2. CupertinoPicker for hours (0-23) and minutes (5min increments)
3. Default: 30 minutes extension
4. "Add Time" button → TODO: extend event by selected time
5. "End Now" button → shows confirmation dialog → TODO: end event immediately
6. Time display updates based on event end time

### **Expenses Integration** ✅
1. Fetches expenses for event's groupId
2. Calculates total (excludes settled expenses)
3. Shows red if owing, green if receiving
4. Sorted: active by date desc, settled always last
5. Tap card → opens ExpenseDetailBottomSheet with participants
6. "Mark as paid" button color: purple (living), green (planning)
7. Add button → opens AddExpenseBottomSheet with mode parameter

### **Photo Upload Flow** ✅ (UI only)
1. Center purple button in action row
2. TODO: Open camera/photo picker
3. TODO: Upload to Supabase storage
4. TODO: Create memory entry
5. TODO: Real-time sync to other participants

### **Mode-Based Styling** ✅
- ChatMode.living parameter throughout
- Purple accent: `BrandColors.living` (#8B5CF6)
- Shadow patterns: `BoxShadow(color: color.withValues(alpha: 0.3-0.4), blurRadius: 8-12, offset: Offset(0, 3-4))`
- Buttons, pills, chat preview all respect mode

---

## 🔄 **WORKING UI FLOWS**

### **Complete User Journeys Working**
1. ✅ **View event in living mode** (loading → data → display)
2. ✅ **See time left** (host and participant views)
3. ✅ **Manage time** (host only, bottom sheet with picker)
4. ✅ **View expenses** (total, sorted list, detail modal)
5. ✅ **Add expense** (bottom sheet with purple accent)
6. ✅ **View chat preview** (latest message, unread count)
7. ✅ **Action buttons** (all 3 buttons with visual feedback)

### **Error Handling** ✅
- Loading states with spinners for all async operations
- Error states with user-friendly messages
- Empty states when no data (expenses, messages)
- Proper navigation and feedback

---

## 📁 **FILE STRUCTURE REFERENCE**

```
lib/features/event/
├── domain/
│   └── entities/
│       ├── event_detail.dart ✅ (used)
│       └── chat_message.dart ✅ (used)
├── presentation/
│   ├── pages/
│   │   └── event_living_page.dart ✅ COMPLETE
│   ├── widgets/
│   │   ├── living_time_left_pill.dart ✅ COMPLETE
│   │   ├── host_time_controls.dart ✅ COMPLETE
│   │   ├── living_action_row.dart ✅ COMPLETE
│   │   ├── chat_preview_widget.dart ✅ COMPLETE (mode parameter)
│   │   └── living_expenses_widget.dart ✅ COMPLETE (renamed to EventExpensesWidget)
│   └── providers/
│       └── event_providers.dart ✅ (providers used)

lib/features/group_hub/
└── domain/
    └── entities/
        └── group_expense_entity.dart ✅ (participantIds added)

lib/shared/
└── models/
    └── group_enums.dart ✅ (ChatMode enum)
```

---

## 🔗 **DEPENDENCIES & INTEGRATIONS**

### **Cross-Feature Dependencies**
- ✅ `group_hub` feature - GroupExpenseEntity, expenses repository
- ✅ `shared/components` - CommonAppBar, EventHeader, LocationWidget, AddExpenseBottomSheet
- ✅ `shared/models` - ChatMode enum for mode switching
- ✅ `shared/themes` - BrandColors.living (#8B5CF6)

### **Navigation**
- ✅ Back navigation to previous screen
- ❌ Chat navigation (TODO: implement route to event chat page)
- ❌ Memory navigation (TODO: implement route to memory viewer)

---

## 🚀 **P2 IMPLEMENTATION CHECKLIST**

### **High Priority**

#### **Time Management Backend**
- [ ] Implement `extendEventTime(eventId, minutes)` method in EventRepository
- [ ] Implement `endEventNow(eventId)` method in EventRepository
- [ ] Add real-time sync for time updates (Supabase Realtime)
- [ ] Update event end_time in database
- [ ] Notify all participants of time changes

#### **Expenses Backend**
- [ ] Wire EventExpensesWidget to real event's groupId
- [ ] Implement `addExpense(groupId, expense)` in GroupExpenseRepository
- [ ] Implement `markAsPaid(expenseId)` in GroupExpenseRepository
- [ ] Real-time sync for expense updates
- [ ] Calculate total owed/receiving correctly
- [ ] Filter expenses by event participants

#### **Photo Upload & Storage**
- [ ] Implement camera/photo picker integration
- [ ] Upload photos to Supabase Storage (`/groupId/eventId/userId/uuid.jpg`)
- [ ] Create memory entry linked to event
- [ ] Real-time photo sync to all participants
- [ ] Thumbnail generation and compression

### **Medium Priority**

#### **Chat Integration**
- [ ] Implement real chat messages query (not just recent)
- [ ] Real-time message sync (Supabase Realtime)
- [ ] Unread count tracking per user
- [ ] Navigation to full chat page
- [ ] Message pagination

#### **Authentication Integration**
- [ ] Replace `'current-user'` with real auth userId
- [ ] Verify host permissions before showing controls
- [ ] User profile data for expense participants
- [ ] Participant avatars and names

### **Low Priority**

#### **Real-time Features**
- [ ] Live time countdown updates (every minute)
- [ ] Real-time participant join/leave
- [ ] Live expense updates across devices
- [ ] Push notifications for time extensions/event end

#### **Error Recovery**
- [ ] Offline support for viewing cached data
- [ ] Retry logic for failed uploads
- [ ] Conflict resolution for simultaneous edits

---

## 📊 **TESTING CONSIDERATIONS FOR P2**

### **Time Management Tests**
- Host can extend time by custom amount
- Host can end event early
- Participants cannot access host controls
- Time updates sync to all participants
- Event transitions to ended state correctly

### **Expenses Tests**
- Expenses filtered to event participants only
- Total calculation excludes settled expenses
- Mode parameter changes button colors correctly
- Mark as paid updates expense state
- Real-time sync across devices

### **Photo Upload Tests**
- Photos upload to correct storage path
- Memory entry created successfully
- Photos appear in real-time for participants
- Image compression works correctly
- Failed uploads handled gracefully

### **Integration Tests**
- Event living mode loads all data correctly
- Host and participant views render correctly
- Mode switching (planning ↔ living) works
- Navigation between pages works
- Error states display correctly

---

## 🎨 **DESIGN TOKENS USED**

### **Colors**
```dart
BrandColors.living          // #8B5CF6 (purple accent)
BrandColors.bg1             // Background
BrandColors.bg2             // Cards, buttons
BrandColors.bg3             // End Now button
BrandColors.text1           // Primary text
BrandColors.text2           // Secondary text
BrandColors.cantVote        // Red (destructive, "End Now" text)
BrandColors.planning        // Green (for planning mode comparisons)
```

### **Spacing**
```dart
Insets.screenH              // Horizontal screen padding
Gaps.lg                     // Large gap between sections
Gaps.md                     // Medium gap
Gaps.sm                     // Small gap
Radii.md                    // Medium border radius
```

### **Shadows**
```dart
// Main pill shadow (purple glow)
BoxShadow(
  color: BrandColors.living.withValues(alpha: 0.4),
  blurRadius: 12,
  offset: Offset(0, 4),
)

// Button shadow (purple)
BoxShadow(
  color: BrandColors.living.withValues(alpha: 0.3),
  blurRadius: 8,
  offset: Offset(0, 4),
)
```

---

## 📝 **NOTES FOR P2**

### **Critical Implementation Details**
1. **Auth Integration**: All `'current-user'` references must be replaced with actual user ID from auth provider
2. **Group Association**: Event must have groupId to fetch expenses correctly
3. **Storage Paths**: Follow convention `/groupId/eventId/userId/uuid.jpg` for photos
4. **Real-time**: Use Supabase Realtime for live updates (time, expenses, photos, chat)
5. **RLS Policies**: Verify all queries respect row-level security

### **Performance Considerations**
- Time countdown updates: throttle to once per minute, not every second
- Photo uploads: compress images before upload (use ImageCompressionService)
- Expenses list: limit query with pagination if many expenses
- Chat preview: only fetch last 3-5 messages, not all history

### **Business Rules to Verify**
- Only host can extend time or end event
- Only event participants can view/add expenses
- Photos uploaded during event are associated with event memory
- Settled expenses excluded from total calculation
- Expenses sorted with settled always last

### **Migration Notes**
- `LivingExpensesWidget` renamed to `EventExpensesWidget` with mode parameter
- Widget now supports both planning (green) and living (purple) modes
- All references updated to use new name and mode parameter
- Old file removed, export updated

---

## ✅ **P1 SIGN-OFF CHECKLIST**

- [x] All UI components implemented and tokenized
- [x] All widgets follow stateless pattern
- [x] Mode-based styling implemented (ChatMode.living)
- [x] Host vs participant views working
- [x] Expenses integration complete
- [x] Time management UI complete
- [x] Action row buttons implemented
- [x] Chat preview with mode parameter
- [x] AsyncValue states for all data
- [x] Loading/Error/Empty states
- [x] Navigation working
- [x] TODO markers for P2 work
- [x] No hardcoded colors/dimensions
- [x] No domain/data imports in presentation
- [x] Clean Architecture boundaries respected
- [x] All linter warnings fixed
- [x] Documentation complete

**Ready for P2 Implementation** ✅
