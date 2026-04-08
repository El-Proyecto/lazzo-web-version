# Lazzo

**Plan fast, remember forever.**

**Status:** Active beta — iOS (TestFlight) + Web — April 2026
**Team:** Two engineers
**Stack:** Flutter · Dart 3 · Riverpod · Supabase · Next.js · PostHog

---

## The Problem

Group event coordination defaults to WhatsApp. RSVPs get buried, decisions don't get made, and photos from the event live in one person's camera roll. We saw this pattern consistently not as a complaint, but as something people had simply accepted.

This isn't a niche problem. Everyone we spoke to recognised it immediately. But existing tools don't address the full cycle. WhatsApp is built for conversation, not decisions. Google Photos requires setup and relies on everyone remembering to add their photos. Nothing was designed to take you from "hey, let's do something" to RSVP to shared memory in one flow.

The gap we wanted to fill: send one link, people commit without installing anything, photos get collected during and after the event, and the whole thing closes into something worth keeping.

---

## Approach

Before writing a line of code, we spent six weeks validating. We interviewed 23 people aged between 18 and 30 and ran six Figma prototype iterations. Each one tested, rebuilt, and refined based on what we heard.

A few things became clear: everyone coordinated through messaging apps, and most acknowledged it didn't work well. Photos from shared events almost always disappeared, usually because no one took the initiative to share them the next day. Two people we spoke to had already looked for an alternative to WhatsApp for event coordination and found nothing that fit.

The prototypes also helped us decide what not to build, at least not yet. Camera modes (a "disposable camera" feel for nights out) were genuinely popular in testing, but the appeal was aesthetic rather than functional; they didn't solve a real problem and would only make sense if the product found strong traction in nightlife specifically. Availability polls added coordination steps without meaningfully improving the final decision. An offline-first experience was flagged as important by a few, but almost everyone carries mobile data all the time. We deprioritised all three before starting developme; not because the ideas were wrong, but because none of them belonged in an MVP trying to prove the core loop.

One finding that shaped everything: users flagged that sharing post-event photos happens within 24 hours or not at all. That became a design constraint, not a feature.

---

## What We Built

Lazzo is structured around a single shareable link. The host creates an event in under 30 seconds on iOS  (title, date, location) and sends the link to wherever the group already coordinates. Guests open it on the web with no install required: they RSVP, upload photos during the event and in the 24 hours that follow, and the event closes into a Memory (private by default), curated recap. Hosts can export a Share Card (Stories/Posts format) to distribute across socials.

**iOS-first was deliberate.** Push notifications for RSVP reminders, upload windows, and memory alerts require native infrastructure. Our target audience is predominantly on iOS. And taking photos mid event is a meaningfully better experience in a native app.

**The 24-hour upload window is a designed constraint.** It creates urgency and matches the natural social window when people think about the event they just left. The deadline isn't arbitrary, it came directly from what people told us in research.

**The January pivot changed the trajectory of the project.** V1 required all guests to install the app. When we tested it, the feedback was unambiguous: guests felt obligated to install, and in the real world, they wouldn't. The install screen was the actual drop-off point, not anything inside the product.

The response was to rebuild the guest experience as a web app and ship it alongside the native host experience. We launched both at the end of February. The same pivot prompted us to remove four features that had been in V1: chat, groups, expenses, and availability polls. Not because they were bad ideas, they'd tested positively in Figma, but because they were competing with behaviours people already had. Removing them made the product sharper and the test much cleaner.

---

## Beta & Metrics

We instrumented a full analytics stack with PostHog before running any cohort tests: a guest funnel (invite open → RSVP → upload → memory view), a host loop (event created → shared → memory → repeat), and stability monitoring for both platforms. Testing is active and we're running the product with real friend groups on weekends and iterating based on what we observe.

The clearest pattern so far: the product performs best at larger events with a socially mixed group, 15+ people who don't all share an existing group chat. At smaller, close-knit gatherings, photo upload volume is lower. Not because the experience breaks, but because those groups already have informal sharing habits through WhatsApp and AirDrop. Lazzo doesn't need to displace that; it fills the space where those habits don't reach. We're continuing to test across different event types to validate where the strongest use case sits.

---

## What I'd Do Differently

The clearest signal from testing so far: photo upload behaviour correlates with event size and social mix. Large birthday parties and themed events with mixed groups produce strong contribution. Casual dinners between close friends produce almost none.

This suggests a tighter initial wedge than we assumed. If I were scoping the first cohort from scratch, I'd design specifically around larger social events, such as: nightlife, milestone birthdays, events where guests come from different circles. The product concept stays the same; the entry point changes.

I'd also have built the web companion from day one. The possibility was discussed early and set aside as a future problem. It turned out to be the most important unlock we made.

The most fundamental thing, though: we optimised for a polished, bug-free app before we had evidence that the core behaviour even existed. That's the right call once people rely on your product not when you're still testing whether the premise works.

---

## What I've Learned So Far

**1. "Would you use this?" is the wrong question.**
People answer based on what sounds reasonable, not how they actually behave. Figma tests whether someone understands an interface. Asking "would you upload photos after an event?" tests whether they're polite. The only valid test of a behaviour is the behaviour itself; and that requires real events, real guests, and no one in the room.

**2. The hardest friction to see is the one you've normalised.**
We assumed guests would install the app because we'd been building for that assumption for months. It took watching real people in test sessions doing it reluctantly because we were in the room to understand that the download screen was the real drop-off point, not anything inside the product. You can't see that in a Figma test.

**3. Cutting features is a product decision, not a concession.**
Between V1 and V2 we removed chat, groups, expenses, and availability polls. Each had received positive feedback during validation. Removing them made the remaining surface area faster to understand, and the beta signal much easier to read. Scope reduction as strategy, not retreat.

**4. Time-bounded design changes behaviour.**
The 24-hour upload window functions as a social cue as much as a product constraint. It signals: "this is the moment to contribute." The limit came from research, not from a technical reason. Designing around natural human time windows, rather than open-ended optionality, produces more consistent behaviour.

**5. Friends validate the experience; they don't validate the habit.**
Friends install because they trust you. They upload because they want to help. That's not product-market fit — it's loyalty. The real signal is whether the product changes behaviour in people who have no personal reason to care whether it succeeds.

---

## Links

- **App repository:** [github.com/El-Proyecto/lazzo-web-version](https://github.com/El-Proyecto/lazzo-web-version)
- **Web repository:** [github.com/El-Proyecto/lazzo-invites-web](https://github.com/El-Proyecto/lazzo-invites-web)
- **Website:** [getlazzo.com](https://getlazzo.com)
- **TestFlight:** Available on request — [realeventapp@gmail.com](mailto:realeventapp@gmail.com)

