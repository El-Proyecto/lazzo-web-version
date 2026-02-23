# Actions — Beta Recommendations

## Overview

Actions is a host-facing feature in the Inbox tab that surfaces the most important tasks an event host should address. The goal is to **reduce friction** and help hosts keep their events on track without having to manually check each event.

---

## Architecture Decision: Computed vs Stored Actions

### Recommended for Beta: **Computed Actions (no DB table)**

For the beta, actions are **computed on-the-fly** from existing event/participant data. This avoids the need for a new `actions` table and keeps the system simple.

**How it works:**
1. Query all events where `created_by = current_user_id`
2. For each event, check conditions (e.g., pending voters, missing details)
3. Generate `ActionEntity` objects client-side
4. Sort by priority/urgency and display

**Pros:**
- Zero schema changes needed
- Actions are always fresh (no stale data)
- Simple to add/remove action types
- No sync issues between event state and action state

**Cons:**
- Slightly more queries per inbox open
- Can't track dismissed actions across sessions (unless we add a small table)

### Future (Post-Beta): **Stored Actions Table**

When action complexity grows (e.g., scheduled reminders, team actions), migrate to a dedicated `actions` table. See `ACTIONS_SCHEMA.sql` for ready-to-use DDL.

---

## Recommended Actions for Beta

### 1. **Remind Maybe Voters** (`remindMaybeVoters`)
- **Trigger:** Event has active polls AND some participants have `rsvp = 'maybe'` or `rsvp = 'pending'`
- **Priority:** High
- **Title:** "Remind maybe voters"
- **Subtitle:** "{count} guests haven't voted yet"
- **Due date:** Poll closing date (if set), otherwise event `start_datetime - 2 days`
- **CTA:** Tap → navigate to event page (guest list section)
- **Condition:** Only show for events in `pending` or `confirmed` status

### 2. **Confirm Event** (`confirmEvent`)
- **Trigger:** Event is in `pending` status AND has a date/place poll that has ended (all votes in or deadline passed)
- **Priority:** Urgent
- **Title:** "Confirm event"
- **Subtitle:** "Voting ended — pick final date & place"
- **Due date:** `start_datetime` of the event (if set)
- **CTA:** Tap → navigate to event page (edit mode or confirmation flow)
- **Condition:** Only when voting is complete but event not yet confirmed

### 3. **Add Event Details** (`addEventDetails`)
- **Trigger:** Event is missing critical info: `start_datetime IS NULL` OR `location_id IS NULL`
- **Priority:** Medium
- **Title:** "Add event details"
- **Subtitle:** "Missing {date/location/both}"
- **Due date:** None (persistent until resolved)
- **CTA:** Tap → navigate to edit event page
- **Condition:** Only for events in `pending` status

### 4. **Review Guest List** (`reviewGuests`)
- **Trigger:** Event is `confirmed` AND some participants have `rsvp = 'maybe'` or `rsvp = 'pending'`, AND event starts within 3 days
- **Priority:** Medium
- **Title:** "Review guest list"
- **Subtitle:** "{count} guests are still maybe"
- **Due date:** `start_datetime` of the event
- **CTA:** Tap → navigate to event page (guest list)
- **Condition:** Only close to event date, not for far-future events

### 5. **Add Photos** (`addPhotos`)
- **Trigger:** Event is in `living` status AND host has uploaded 0 photos
- **Priority:** High
- **Title:** "Add photos"
- **Subtitle:** "Upload window closes in {time}"
- **Due date:** `end_datetime` of the event (when living phase ends)
- **CTA:** Tap → navigate to event page (photos section)
- **Condition:** Only during living phase

---

## Actions NOT Recommended for Beta

| Action | Reason |
|--------|--------|
| Payment reminders | Payments/expenses feature removed in LAZZO 2.0 |
| Task assignments | No task system exists yet |
| Chat-based actions | Chat is secondary; notifications cover this |
| Group-level actions | Groups feature is simplified in 2.0 |
| Scheduled send reminders | Requires push notification integration (Phase 2) |

---

## Priority & Sorting Logic

Actions are sorted by:
1. **Overdue first** (past due date)
2. **Priority** (urgent > high > medium > low)
3. **Due date** (soonest first)

Priority mapping:
| Action Type | Default Priority |
|-------------|-----------------|
| `confirmEvent` | Urgent |
| `remindMaybeVoters` | High |
| `addPhotos` | High |
| `reviewGuests` | Medium |
| `addEventDetails` | Medium |

---

## Time-Left Color Coding

| Time Left | Color | Token |
|-----------|-------|-------|
| Overdue | Red | `BrandColors.cantVote` |
| ≤ 2 hours | Red | `BrandColors.cantVote` |
| ≤ 24 hours | Orange | `BrandColors.recap` |
| > 24 hours | Green | `BrandColors.planning` |

---

## UI Specifications

### Inbox Segmented Control
- Two segments: **Notifications** | **Actions**
- Background: `BrandColors.bg2`
- Selected segment: `BrandColors.bg3` with `text1` color
- Unselected: transparent with `text2` color

### Action Card Layout
```
┌─────────────────────────────────────────┐
│ 🍽️  Remind maybe voters    ⏱ 2d left  │
│      Friday Dinner              ▶       │
└─────────────────────────────────────────┘
```
- Left: event emoji (28px)
- Center: title (bold) + event name (text2)
- Right: time-left badge (color-coded) + chevron

### Empty State
- Icon: `task_alt_outlined` in `bg3` circle
- Title: "No pending actions"
- Subtitle: "When you have tasks to complete, they'll be organized here by time left."

---

## Implementation Phases

### Phase 1: Beta (Current) ✅
- [x] ActionEntity with 5 host-focused types
- [x] Segmented control in Inbox (Notifications | Actions)
- [x] FakeActionRepository with sample data
- [x] InboxActionCard with time-left color coding
- [x] ActionsSection with empty state
- [ ] Real ActionRepository (computed from events data)

### Phase 2: Post-Beta
- [ ] Real Supabase data source (query events + participants)
- [ ] Dismissed actions persistence (small DB table or local storage)
- [ ] Badge count on Actions tab
- [ ] Push notifications for urgent actions
- [ ] Action-specific CTAs (e.g., "Send reminder" button)

### Phase 3: Future
- [ ] Stored actions table for complex workflows
- [ ] Team/group actions (not just host)
- [ ] Automated action generation via Supabase triggers
- [ ] Action analytics (completion rates, response times)
