# Lazzo

**Plan fast, remember forever.**

Lazzo is a mobile app that turns event planning and shared memories into one flow. Create an event in seconds, share a link for guests to RSVP and add photos from the app or the web, no install required. When the event is over, everyone gets a shared memory and hosts can generate shareable cards for socials. Built by two 3rd year CS students from IST. Currently in closed beta (TestFlight).

---

## Screenshots

_Screenshots coming soon. Add images of the Home, Event, and Memory screens in `docs/screenshots/` to showcase the app._

---

## Built with

- **App:** Flutter (Dart 3), Riverpod
- **Backend & auth:** Supabase
- **Analytics:** PostHog
- **Integrations:** deep links, QR codes, image picker/compression, native share, calendar export, push notifications

The web experience for guests lives in a separate repository and shares the same Supabase backend:
https://github.com/El-Proyecto/lazzo-invites-web

---

## Running the project locally

**Prerequisites:** Flutter SDK (3.5+), Xcode (iOS) or Android Studio. An iOS simulator or device is enough to run the app.

1. Clone the repo.
2. Copy `.env.example` to `.env` and add your [Supabase](https://supabase.com) project URL and anon key (Settings → API in the dashboard). Do not commit `.env`.
3. Copy those values into `lib/env.dart` so the app can connect (see `.env.example` for the variable names). Keep real credentials out of version control.
4. Run `flutter pub get` then `flutter run`.

The web companion does not need to be running to use the app.

---

## Current status

- **Closed beta** — iOS via TestFlight; guests can participate on the web at [getlazzo.com](https://getlazzo.com/).
- **How to get access:** Reach out via [getlazzo.com](https://getlazzo.com/) or [realeventapp@gmail.com](mailto:realeventapp@gmail.com).

---

## Links

- **Website:** [getlazzo.com](https://getlazzo.com/)
- **TestFlight:** [Join the beta (TestFlight)](#) — _link will be added here when available._

---

For architecture, feature development, and agent rules, see the documentation in the repo (e.g. `AGENTS.md` and `.agents/`).
