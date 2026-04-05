# Lazzo — Validation Guide (Cohort #1)

**Purpose:** Separate real product signals from false positives. This guide defines what to observe, what to ask, and how to interpret results during the 4–5 test events in Phase 2.

**Key principle:** Friends will be polite. Polite ≠ validated. We need **behavioral data** (what they did) over **opinion data** (what they said they liked).

---

## 1) What We're Validating (and What We're Not)

### Validating (must answer with confidence after cohort)

| Question | Success signal | Failure signal |
|----------|---------------|----------------|
| Can guests RSVP without help? | ≥80% RSVP without host intervening | Host has to explain the link/flow verbally |
| Do guests upload photos? | ≥2 contributors per event, ≥60% events with uploads | Only host uploads, or zero uploads |
| Is the recap viewed? | Guests open recap link or mention it | Nobody looks at the memory after the event |
| Does the host find the flow intuitive? | Creates event + shares link in <2min without guidance | Needs to re-read briefing or ask questions |
| Is the 24h upload window understood? | Guests upload after the event ends | Guests think uploads close when event ends |

### NOT validating (defer to later cohorts)

- Visual polish / brand appeal (friends don't care)
- Willingness to pay
- Whether strangers understand the concept
- Sharing/virality (too small a sample)
- Repeat host behavior (only 1 event per host)

---

## 2) Observation Framework

### Before the event (setup phase)

**What to observe:**
- How long does the host take to create the event? (Target: <30s)
- Does the host understand the confirm flow? (Location + date + 1 "Can" vote)
- Does the host share the link naturally (WhatsApp/group chat) or hesitate?
- Does the host need to explain to guests what Lazzo is, or does the link speak for itself?

**Red flags:**
- Host asks "how do I share this?"
- Host sends a screenshot of the app instead of the link
- Host needs to confirm the event manually and doesn't understand why it's still "Pending"

**What to log:**
```
Event: [event name]
Host: [name]
Time to create: [seconds]
Shared via: [whatsapp/imessage/other]
Did host need help?: [yes/no + what]
```

### During the event (live phase)

**What to observe:**
- Do guests open the link and upload photos without being prompted?
- Does anyone ask "how do I add photos?"
- Does the host use the camera button in the app?
- Does the host use the time controls (extend/end)?
- Are there any errors/crashes during upload?

**Red flags:**
- Guests open the link but don't upload — the CTA is unclear
- Photos fail to upload silently (guest thinks it worked but it didn't)
- The live page doesn't show new photos in real-time
- Host doesn't realize the event is "live" (missed the phase transition)

**What to log:**
```
Event: [event name]
# of guests who opened link: [n]
# of guests who uploaded: [n]
# of photos uploaded (app): [n]
# of photos uploaded (web): [n]
Upload errors observed: [describe]
Did host prompt guests to upload?: [organically / had to push / no uploads]
```

### After the event (recap phase)

**What to observe:**
- Do guests upload more photos in the 24h window?
- Does the host open the "Memory Ready" notification?
- Does the host generate a Share Card?
- Does the host share the memory anywhere (IG, WhatsApp)?
- Do guests revisit the link to see the recap?

**Red flags:**
- Nobody uploads in the 24h window (they think it's over)
- Host doesn't notice the "Memory Ready" notification
- Share Card doesn't look good or is confusing to generate
- Guests don't know the recap exists

**What to log:**
```
Event: [event name]
Photos added in 24h window: [n]
Host saw "Memory Ready"?: [yes/no]
Share Card generated?: [yes/no]
Share Card shared to: [ig/whatsapp/none]
Guests revisited recap?: [yes/no/unknown]
```

---

## 3) Questions to Ask (Post-Event)

### Timing
Ask within **24–48h** after the event. Memory fades fast. Don't wait for all events to complete — debrief each one individually.

### Questions for the Host

**Open-ended first** (don't lead):

1. **"Como correu o evento com o Lazzo?"** — Let them talk freely. Note what they mention first (positive or negative).

2. **"Houve algum momento em que não soubeste o que fazer?"** — Identifies confusion points. If they say "não", follow up: "Nem quando partilhaste o link? Nem durante o evento?"

3. **"Os teus amigos conseguiram usar o link sem tu explicares?"** — This is the #1 signal. If the host had to explain the flow, the product failed at self-service.

4. **"Viste a memória depois do evento? O que achaste?"** — Tests if the recap moment landed emotionally.

5. **"Se voltasses a ter um evento, usavas o Lazzo ou fazias como antes?"** — The "would you use it again" question. **Beware:** friends will say yes. Pay more attention to *how quickly* and *how enthusiastically* they answer.

**Specific probes** (only after open-ended):

6. **"Quantas fotos achas que o grupo fez upload?"** — Compare their perception with reality. If they think "lots" but reality is 3, the product felt active even without heavy usage (good). If they think "some" but reality is 20, the gallery wasn't noticed (bad).

7. **"Partilhaste ou pensaste em partilhar a memória em algum lado?"** — Sharing intent matters more than actual shares at this scale.

8. **"O que faltou? O que achas que devia haver e não havia?"** — Feature request signal. Note if multiple hosts say the same thing.

### Questions for Guests (pick 2–3 per event)

Keep it short. Guests have low investment. Ask via text message, not a formal survey.

1. **"Ei, conseguiste abrir aquele link do evento? Custou-te alguma coisa?"** — Casual. Tests if the web flow was friction-free.

2. **"Viste as fotos depois do evento no link?"** — Tests recap awareness.

3. **"Fizeste upload de fotos? Se não, porquê?"** — Tests upload motivation. The "porquê" is gold: "não sabia que podia", "não encontrei o botão", "não me apeteceu", "esqueci-me" are all different problems.

---

## 4) Interpreting Results — Signal vs Noise

### False positives (looks good, means nothing)

| What you see | Why it's misleading |
|---|---|
| "A app é fixe!" | Friends being polite. Zero signal. |
| Host shares the link immediately | They're doing it because you asked, not because the product compelled them |
| 100% RSVP rate | Friends respond to social pressure, not product quality |
| "Eu usaria de novo" | Unless they create a 2nd event unprompted, it's just politeness |

### Real signals (pay attention)

| What you see | What it means |
|---|---|
| Guest uploads photos **without being asked** | The product communicated the value proposition |
| Host opens "Memory Ready" **same day** | The recap moment has emotional pull |
| Guest says "ah, não sabia que podia pôr fotos" | The upload CTA failed — UX problem |
| Host shares the Share Card on Instagram | Real sharing behavior (even with friends, IG is intentional) |
| Guest revisits the link days later | The memory has lasting value |
| Host says "isto fez-me lembrar de [competitor]" | Positioning unclear — need to understand what they mean |
| Multiple guests fail at OTP step | Auth friction is real — blocking conversion |

### The killer question test

After all events are done, ask yourself:

> **"If we removed the briefing document and just sent the TestFlight + link, would the same thing happen?"**

If the answer is "no, they needed the briefing to understand" → the product isn't self-explanatory yet.

---

## 5) What to Measure (Quantitative)

### From PostHog (if instrumented)

| Metric | Target | How to check |
|---|---|---|
| `invite_link_opened` → `rsvp_submitted` | ≥50% conversion | PostHog funnel |
| `rsvp_submitted` time_to_rsvp | Median <60s | PostHog property |
| `photo_uploaded` per event | ≥5 photos, ≥2 contributors | PostHog event count |
| `recap_viewed` | ≥1 per event | PostHog event |
| `share_card_generated` | Track baseline | PostHog event |

### Manual tracking (if PostHog gaps exist)

Create a simple spreadsheet per event:

| Field | Event 1 | Event 2 | Event 3 | Event 4 | Event 5 |
|-------|---------|---------|---------|---------|---------|
| Host name | | | | | |
| Event type (dinner/party/etc) | | | | | |
| # guests invited (link sent to) | | | | | |
| # guests who opened link | | | | | |
| # RSVPs (Can / Maybe / Can't) | | | | | |
| # photos uploaded (total) | | | | | |
| # unique uploaders | | | | | |
| # photos from host | | | | | |
| # photos from guests (web) | | | | | |
| Photo uploads in 24h window | | | | | |
| Host needed help? (Y/N + what) | | | | | |
| Guests needed help? (Y/N + what) | | | | | |
| Memory Ready opened by host? | | | | | |
| Share Card generated? | | | | | |
| Share Card shared where? | | | | | |
| Guests revisited recap? | | | | | |
| Top friction point | | | | | |
| Top positive moment | | | | | |

---

## 6) During the Event — Your Role as Observer

### What you SHOULD do

- **Be present** at the event (you or co-founder at each one)
- **Watch, don't help.** If someone struggles, note it down. Don't jump in to explain unless they're completely stuck.
- **Time things:** discreetly note how long guests take from opening link → RSVP → first upload
- **Screenshot errors:** if anything breaks, screenshot immediately
- **Note the environment:** WiFi? Cellular? Which phone/browser? These matter for debugging.

### What you SHOULD NOT do

- Don't say "try uploading a photo" — if they don't do it naturally, that's a signal
- Don't explain what the app does beyond what the host briefing covers
- Don't apologize for bugs in advance ("it's beta so...") — that primes them to be lenient
- Don't ask leading questions during the event ("isn't this cool?")
- Don't fix bugs live — note them and fix after

### The "silent test" moments

These are the most valuable data points:

1. **The moment a guest opens the link for the first time** — Do they understand what they're looking at? Do they scroll? Do they hesitate?
2. **The moment someone takes a photo at the event** — Do they think to upload it to Lazzo, or just to their camera roll?
3. **The morning after** — Does anyone mention the event/photos? Does the host check the app?

---

## 7) Post-Cohort Analysis

After all 4–5 events, compile results and answer these questions:

### Go / No-Go for Cohort #2

| Question | Go signal | No-Go signal |
|---|---|---|
| Can guests RSVP without help? | ≥4/5 events had self-service RSVPs | Multiple events needed verbal explanation |
| Do people upload? | ≥3/5 events had guest uploads (not just host) | Only hosts uploaded, or zero uploads in most events |
| Is the recap valued? | ≥3/5 hosts opened Memory Ready within 24h | Hosts ignored the recap notification |
| Are there blocking bugs? | Zero crash-level bugs; minor UX issues only | Crashes or data loss in any event |
| Did the OTP flow work? | ≥90% of guests completed OTP without issues | Multiple guests stuck at OTP verification |

### Top 3 improvements for Cohort #2

After analyzing all events, pick **exactly 3** things to fix:

1. **The #1 drop-off point** — Where did the most people stop or get confused?
2. **The #1 "missing" thing** — What did multiple people expect that wasn't there?
3. **The #1 technical issue** — What broke or was unreliable?

Don't try to fix everything. Fix three things well.

---

## 8) Anti-patterns to Avoid

### The "demo effect"
You demo the app to the host before the event. They understand it perfectly... because you showed them. The briefing should be the only guide. If it doesn't work alone, the briefing (and product) need improvement.

### The "power user bias"
You and your co-founder are in each event. Your behavior (taking photos, uploading, sharing) will influence others. **Track your own uploads separately.** The real signal is what others do, not what you do.

### Survivor bias
If 3/5 hosts had great events and 2/5 didn't respond or had issues, don't just celebrate the 3. The 2 are the learning.

### Feature-request trap
Friends will suggest features. Most of those features are solutions to **unstated problems.** When someone says "it should have X", ask: **"What were you trying to do when you wished for that?"** The problem is actionable; the feature suggestion usually isn't.

### Confirmation bias
You built this. You want it to work. Be honest about what you see. The best thing that can happen in this cohort is **finding clear problems** — that means you have clear things to fix before showing it to strangers.

---

## 9) Summary: The 3 Things That Must Be True

After Cohort #1, if these three things are true, you're ready for Cohort #2:

1. **Guests can participate via web without verbal help** — the link is self-explanatory
2. **At least some guests upload photos** — the memory value proposition works
3. **The host sees the memory recap and feels something** — the emotional payoff exists

If even one of these is false, fix it before expanding.

---

## Appendix: Event Log Template

Copy this for each event:

```
## Event: [name]
**Date:** [date]
**Host:** [name]
**Type:** [dinner/party/hangout/etc]
**Location:** [indoor/outdoor, wifi/cellular]
**# invited:** [n]
**# RSVPs:** Can [n] / Maybe [n] / Can't [n]
**# attended:** [n]

### Setup
- Host created event without help: [Y/N]
- Time to create event: [estimate]
- Host confirmed event without help: [Y/N]
- Link shared via: [whatsapp/imessage/other]
- Guests needed explanation beyond link: [Y/N + details]

### Live
- # photos uploaded during event: [n]
- # unique uploaders during event: [n]
- Uploads from app (host): [n]
- Uploads from web (guests): [n]
- Upload errors: [describe]
- Did host prompt guests to upload: [organically/pushed/no]
- Did host use time controls (extend/end): [Y/N]

### Recap
- # photos added in 24h window: [n]
- Host opened Memory Ready: [Y/N, when]
- Share Card generated: [Y/N]
- Share Card shared to: [where]
- Guests revisited recap: [Y/N/unknown]

### Qualitative
- Host quote (verbatim): "[...]"
- Guest quote (verbatim): "[...]"
- Top friction point:
- Top positive moment:
- Unexpected behavior:

### Bugs / Issues
- [describe any bugs, with screenshots if possible]

### Score (honest assessment)
- Guest self-service: [1-5]
- Upload participation: [1-5]
- Recap emotional payoff: [1-5]
- Overall: [1-5]
```
