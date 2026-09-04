# DayByDay — Development Progression Plan

> Organizational work first, then correctness/security, then product/UX.
> Last updated: 2026-06-08

## Legend

### Priority
| Level | Meaning |
|-------|---------|
| **P0** | Blocker — before real users or major new features |
| **P1** | High — do early; unblocks clean development |
| **P2** | Medium — maintainability & polish |
| **P3** | Low — nice-to-have |

### Issue type
| Type | Addresses |
|------|-----------|
| **Org** | Structure, naming, conventions, dead code |
| **Arch** | Models, state, routing, layering |
| **DX** | Lints, tests, docs, developer workflow |
| **Bug** | Correctness |
| **Security** | Data protection |
| **Perf** | Performance |
| **UX** | User-facing experience |
| **Product** | Feature completeness |

---

## Phase 1 — Organizational foundation

**Goal:** One clear way to add screens, services, and data.

### 1.1 Project structure & conventions

- [ ] **1.1.1** Define folder layout (`lib/app/`, `lib/core/`, `lib/models/`, `lib/features/`) — **P1 · Org**
  - *Done when:* New files have an obvious home.
- [ ] **1.1.2** Fix file/folder naming (`asssessments.dart`, `progess_overview.dart`, etc.) — **P1 · Org**
  - *Done when:* No typo filenames; imports updated.
- [ ] **1.1.3** Remove or relocate dead code (`WelcomeScreen`, duplicate progress screens) — **P1 · Org**
  - *Done when:* Each screen has one purpose.
- [ ] **1.1.4** Document conventions (`docs/ARCHITECTURE.md` or `CONTRIBUTING.md`) — **P2 · Org / DX**
  - *Done when:* Structure and naming rules are written down.
- [ ] **1.1.5** Centralize design tokens (`app_colors.dart`, `app_theme.dart`) — **P1 · Org / UX**
  - *Done when:* Theme changes happen in one place.

### 1.2 Data layer organization

- [ ] **1.2.1** Introduce typed models (`UserProfile`, `CheckIn`, `Goal`, `JournalEntry`, `Insight`) — **P1 · Org / Arch**
  - *Done when:* Services return typed objects, not raw maps.
- [ ] **1.2.2** Firestore path constants — **P2 · Org**
  - *Done when:* Collection names not scattered as string literals.
- [ ] **1.2.3** Standardize date formatting (`DateUtils.formatDate`) — **P1 · Org / Bug**
  - *Done when:* Single `yyyy-MM-dd` implementation everywhere.
- [ ] **1.2.4** Clarify service vs repository role — **P2 · Org / Arch**
  - *Done when:* UI never touches Firestore directly.

### 1.3 State & dependency organization

- [ ] **1.3.1** Decide state approach (Provider vs Riverpod) — **P1 · Org / Arch**
  - *Done when:* Decision documented; no unused deps.
- [ ] **1.3.2** Register services at app root (`MultiProvider` / `ProviderScope`) — **P1 · Org / Arch**
  - *Done when:* Screens use injected services, not `final _x = XService()`.
- [ ] **1.3.3** Shared loading/error widgets — **P2 · Org / UX**
  - *Done when:* Reusable spinner, empty, and error states exist.
- [ ] **1.3.4** Remove unused dependency if not using Provider — **P2 · Org**

### 1.4 Navigation organization

- [ ] **1.4.1** Introduce `go_router` (central `lib/app/router.dart`) — **P1 · Org / Arch**
  - *Done when:* Main flows not scattered as `MaterialPageRoute`.
- [ ] **1.4.2** Auth redirect in one place (logged out → Login, not full onboarding) — **P0 · Org / Bug / UX**
  - *Done when:* Returning users go straight to login after sign-out.
- [ ] **1.4.3** Map tab vs stack navigation — **P2 · Org / Arch**
  - *Done when:* Rule exists for push vs tab switch.

### 1.5 UI component organization

- [ ] **1.5.1** Extract shared widgets (`SectionCard`, `StatRow`, `GoalProgressBar`, etc.) — **P1 · Org**
- [ ] **1.5.2** Extract mood chart (single `MoodChart` for Home, Overview, progress) — **P1 · Org**
- [ ] **1.5.3** Extract analytics helpers (average mood, period comparison) — **P1 · Org / Bug**
- [ ] **1.5.4** Screen responsibility matrix (documented) — **P2 · Org / Product**

### 1.6 Feature boundary cleanup

- [ ] **1.6.1** Define screen ownership (Home / Overview / Journal / Settings / Insights) — **P1 · Org / Product**
- [ ] **1.6.2** Merge or delete redundant progress screens — **P1 · Org**
- [ ] **1.6.3** Group features by folder (`features/check_in/`, `features/goals/`, etc.) — **P1 · Org**

### 1.7 Code hygiene & DX

- [ ] **1.7.1** Clean `signup_screen.dart` (imports, formatting) — **P1 · Org / DX**
- [ ] **1.7.2** Enable stricter lints in `analysis_options.yaml` — **P2 · DX**
- [ ] **1.7.3** Replace `print()` with `debugPrint` or logging — **P2 · DX**
- [ ] **1.7.4** Fix widget test (smoke test for `MyApp`) — **P2 · DX**
- [ ] **1.7.5** Add service unit test template — **P3 · DX**

---

## Phase 1 — Suggested execution order

### Week 1 — Structure & clarity
1. 1.1.1 Folder layout
2. 1.1.2 Fix naming
3. 1.1.5 Design tokens
4. 1.6.1 Screen ownership matrix
5. 1.6.3 Feature folders

### Week 2 — Data & deduplication
1. 1.2.1 Typed models
2. 1.2.3 Date utils
3. 1.5.3 Analytics helpers
4. 1.5.1 Shared widgets
5. 1.5.2 Mood chart

### Week 3 — Wiring & boundaries
1. 1.3.1–1.3.2 State / DI
2. 1.4.1 Router
3. 1.4.2 Auth redirect fix **(P0)**
4. 1.6.2 Merge redundant screens
5. 1.1.3 Remove dead code

### Week 4 — Polish org layer
1. 1.2.2 Firestore paths
2. 1.2.4 Service vs repository split
3. 1.3.3 Loading/error widgets
4. 1.7.1–1.7.2 Code hygiene
5. 1.1.4 Architecture doc

---

## Phase 2 — Correctness & security

*(After Phase 1 foundation)*

- [ ] **2.1** Firestore security rules (`request.auth.uid == userId`) — **P0 · Security**
- [ ] **2.2** Fix `GoalService.createGoal` document ID bug — **P0 · Bug**
- [ ] **2.3** Deterministic check-in IDs (`{date}_{timeOfDay}`) — **P0 · Bug**
- [ ] **2.4** Deploy Firestore composite indexes — **P1 · Perf / Bug**
- [ ] **2.5** Fix streak calculation (single range query, not 365 calls) — **P1 · Perf**
- [ ] **2.6** User display name from Firestore profile — **P2 · Bug / UX**

---

## Phase 3 — Product & UX

- [ ] **3.1** Wire Home insight card to `InsightsService` — **P1 · Product / UX**
- [ ] **3.2** Insights discoverability (tab or Overview prominence) — **P2 · Product / UX**
- [ ] **3.3** Pull-to-refresh on Home, Overview, Journal — **P2 · UX**
- [ ] **3.4** Implement or hide “Coming soon” settings items — **P2 · Product**
- [ ] **3.5** Wellness disclaimers & crisis resources — **P2 · Product / UX**
- [ ] **3.6** Offline feedback (Firestore persistence + messaging) — **P3 · UX**

---

## Phase 4 — Backend & scale

- [ ] **4.1** Cloud Function: account deletion — **P2 · Security / Product**
- [ ] **4.2** Cloud Function: scheduled reminders — **P3 · Product**
- [ ] **4.3** Server-side insight generation (optional) — **P3 · Arch / Product**

---

## Target folder structure

lib/ ├── app/ │ ├── main.dart │ ├── router.dart │ └── auth_wrapper.dart ├── core/ │ ├── constants/ │ ├── theme/ │ ├── utils/ │ └── widgets/ ├── models/ ├── repositories/ # or services/ with clear naming └── features/ ├── auth/ ├── onboarding/ ├── home/ ├── check_in/ ├── goals/ ├── journal/ ├── overview/ ├── insights/ ├── daily_patterns/ └── settings/


---

## Screen ownership matrix

| Screen | Primary job | Notes |
|--------|-------------|-------|
| **Home** | Today: check-ins, onboarding cards | Actions, not history |
| **Overview** | Historical stats: mood, goals, patterns, streak | Aggregates at a glance |
| **Journal** | Create/read journal entries | — |
| **Settings** | Account, sign out, config | Insights link or own tab |
| **Insights** | Personalized recommendations | Consider main nav tab |

**Merge/remove:** `progess_overview.dart` — consolidate with Overview or single goals detail screen.

---

## Quick start (minimum org set)

1. **P1 · Org** — Folder layout + feature folders (1.1.1, 1.6.3)
2. **P1 · Org** — Fix naming + dead code (1.1.2, 1.1.3)
3. **P1 · Org** — Typed models (1.2.1)
4. **P1 · Org** — Shared widgets + mood chart + analytics helpers (1.5.1–1.5.3)
5. **P1 · Arch** — Provider/DI at app root (1.3.1–1.3.2)
6. **P0 · Bug** — Auth redirect (1.4.2)
7. **P1 · Org** — Screen ownership + merge redundant screens (1.6.1–1.6.2)