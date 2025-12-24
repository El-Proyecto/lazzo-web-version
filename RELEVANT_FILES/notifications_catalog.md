
# Lazzo — Notifications Catalog

A compact spec of all user-facing notifications. Split by where they **appear**: **Push**, **Notifications** (feed) and **Actions** (to‑dos).

---

## Conventions

**Placeholders**: `{user}`, `{group}`, `{event}`, `{amount}`, `{hours}`, `{mins}`, `{date}`, `{time}`
**Avatar**: event emoji > group photo
**Tap on card**: primary action (navigates to *Deeplink*)

**Deeplinks (examples):**

- `lazzo://group/{groupId}`
- `lazzo://event/{eventId}`
- `lazzo://event/{eventId}/uploads`
- `lazzo://group/{groupId}/actions`

---

## 1) PUSH (with in‑app feed entry)

Essential, low‑noise changes of state. Also listed inside **Notifications**.

| Key                   | Message (EN)                                                | Deeplink                  |
| --------------------- | ----------------------------------------------------------- | ------------------------- |
| group.invite.received | `{user} invited you to join **{group}**.`                   | `group/{groupId}`         |
| event.starts.soon     | `**{event}** starts in {mins} min.`                         | `event/{eventId}`         |
| event.live            | `**{event}** is live now.`                                  | `event/{eventId}`         |
| event.ends.soon       | `**{event}** ends in {mins} min.`                           | `event/{eventId}`         |
| event.extended        | `**{event}** was extended by {mins} min.`                   | `event/{eventId}`         |
| uploads.open          | `Add your photos to **{event}** · {hours}h left.`           | `event/{eventId}/uploads` |
| uploads.closing       | `Last call to add photos to **{event}** · {hours}h left.`   | `event/{eventId}/uploads` |
| memory.ready          | `Your memory for **{event}** is ready to share.`            | `event/{eventId}`         |
| payments.request      | `{user} requested **{amount}** for {note}.`                 | `payments`                |
| payments.added.youowe | `{user} added an expense in **{event}**. You owe {amount}.` | `payments`                |
| payments.paid.you     | `{user} paid you **{amount}**.`                             | `payments`                |
| chat.mention          | `{user} mentioned you in **{event}**.`                      | `event/{eventId}`         |
| security.newlogin     | `New sign-in on {device}. Was this you?`                    | `profile/security`        |

> Push defaults: enabled. Respect device/OS settings and in‑app mute per group.

---

## 2) NOTIFICATIONS (feed)

Informational updates (tap opens context).

| Key                   | Message (EN)                                         | Deeplink          |
| --------------------- | ---------------------------------------------------- | ----------------- |
| group.invite.accepted | `{user} joined **{group}**.`                         | `group/{groupId}` |
| group.renamed         | `**{group}** has a new name.`                        | `group/{groupId}` |
| event.created         | `New event **{event}** in **{group}**.`              | `event/{eventId}` |
| event.date.set        | `Date confirmed for **{event}**: {date}, {time}.`    | `event/{eventId}` |
| event.location.set    | `Location confirmed for **{event}**: {place}.`       | `event/{eventId}` |
| event.details.updated | `**{event}** was updated. Check the new details.`    | `event/{eventId}` |
| event.canceled        | `**{event}** was canceled.`                          | `group/{groupId}` |
| event.confirmed       | `**{event} is confirmed to happen.`                  | `event/{eventId}` |
| suggestion.added      | `{user} suggested **{suggestion}** for **{event}**.` | `event/{eventId}` |

Empty state: *“No new notifications.”*

---

## Behavior & rules

- **Dedup**: collapse duplicates within 5 min (e.g., multiple RSVP updates).
- **TTL**: uploads window entries expire when time runs out; event reminders auto‑remove after end.
- **Mute**: per‑group mute silences push but still lists in feed.

---
