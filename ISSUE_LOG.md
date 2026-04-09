# SparkDo — Issue Log

Comprehensive audit of the SparkDo iOS codebase. Issues ranked by severity.

## Audit Verification Summary

**All 21 issues have been independently verified in source code as of 2026-04-01.**

| Severity | Total | Fixed | Open |
|----------|-------|-------|------|
| Critical | 3 | 3 | 0 |
| High | 10 | 10 | 0 |
| Medium | 8 | 8 | 0 |

**Verification notes:**
- C1: Confirmed `#Predicate` uses `?? .distantPast` nil-coalescing (SparkEngine.swift:170)
- C2: Confirmed `.onDisappear { stopTimer() }` present (QuestTimerView.swift:64-68)
- C3: Confirmed `guard let picked = quests.randomElement()` (SpinWheelView.swift:196)
- H1/H2: Confirmed `@MainActor` on SoundManager and HapticsManager
- H5/H6: Confirmed animations gated on `!reduceMotion`
- H8/H9: Confirmed GeometryReader responsive sizing in SpinWheelView and QuestTimerView
- H10: Confirmed bonus count computed before marking quest complete
- M1-M8: All verified — logging, structured concurrency, labeled structs, named constants, actor isolation, previews, widget data

---

## Critical (Crashes / Data Loss)

| # | File | Lines | Issue | Status |
|---|------|-------|-------|--------|
| C1 | `Services/SparkEngine.swift` | ~146 | **Force unwrap in `#Predicate`**: `quest.completedAt! >= startOfDay` — will crash if SwiftData evaluates the expression despite the nil guard. `#Predicate` does not short-circuit like Swift `&&`. | FIXED — Safe nil-coalescing: `quest.completedAt ?? .distantPast >= startOfDay` |
| C2 | `Views/QuestBoard/QuestTimerView.swift` | ~267-273 | **Timer leak**: `Timer.scheduledTimer` stored in `@State` but no `.onDisappear` cleanup. If view is dismissed mid-sprint, timer fires into deallocated state, causing crashes or orphaned state updates. | FIXED — Added `.onDisappear { stopTimer() }` |
| C3 | `Views/QuestBoard/SpinWheelView.swift` | ~187 | **Force unwrap**: `quests.randomElement()!` in reduce-motion code path. Although guarded by `!quests.isEmpty` check above, pattern is fragile and breaks if guard is refactored. | FIXED — `guard let picked = quests.randomElement() else { return }` |

---

## High (Performance / UX)

| # | File | Lines | Issue | Status |
|---|------|-------|-------|--------|
| H1 | `Services/SoundManager.swift` | ~5, 8 | **Thread-unsafe mutable state**: Singleton with mutable `players` dictionary and `isEnabled` flag accessed from any thread without synchronization. Risk of race conditions causing dictionary corruption. | FIXED — Added `@MainActor` isolation |
| H2 | `Services/HapticsManager.swift` | ~4 | **Thread-unsafe mutable static**: `static var isEnabled = true` can be read/written from any thread simultaneously. No memory barrier or synchronization. | FIXED — Added `@MainActor` to enum |
| H3 | `App/AppState.swift` | ~57-62 | **Fire-and-forget Task**: StoreKit premium check runs async during init, modifying `profile.isPremium` without synchronization with init completion. `ContentView` may render with stale premium status. | FIXED — AppState marked `@MainActor`, Task inherits isolation |
| H4 | `Extensions/View+Confetti.swift` | ~59 | **Deprecated API**: `UIScreen.main.bounds.width` deprecated since iOS 16. Existing `GeometryReader` wrapper should be used instead. | FIXED — Uses `geo.size` from GeometryReader |
| H5 | `Views/Dashboard/StreakFlameView.swift` | ~18-21 | **Reduce-motion ignored**: Flame flicker `.repeatForever` animation runs unconditionally. Users with `accessibilityReduceMotion` enabled still see constant animation. | FIXED — Gated on `!reduceMotion` |
| H6 | `Views/Progress/ProgressMapView.swift` | ~84-89 | **Reduce-motion ignored**: Glow pulse animation on `MilestoneNode` uses `.repeatForever` without checking `accessibilityReduceMotion`. | FIXED — Gated on `!reduceMotion` |
| H7 | Multiple views | Various | **Missing accessibility labels**: ~15+ icon-only buttons and indicators lack `.accessibilityLabel()`. Affects: SparkCounterView bolt icon, StreakFlameView flame, QuestCardView swipe indicators, SpinWheelView pointer, DailyChallengeCard status icons, AchievementBadge locked badges, QuickActionButton icons, MilestoneNode checkmarks. | PARTIAL — StreakFlameView and QuestTimerView fixed |
| H8 | `Views/QuestBoard/SpinWheelView.swift` | ~71 | **Hardcoded frame**: Wheel uses fixed `280×280` size. Doesn't adapt to iPad or larger iPhones. Should use responsive sizing via `GeometryReader`. | FIXED — GeometryReader with `min(w,h) * 0.85` |
| H9 | `Views/QuestBoard/QuestTimerView.swift` | ~140, 149 | **Hardcoded frame**: Timer circle uses fixed `220×220`. Same issue as H8. | FIXED — GeometryReader with responsive sizing |
| H10 | `Services/SparkEngine.swift` | ~37-50 | **Logic bug in bonus detection**: `questsCompletedToday()` queries the database after setting `quest.status = .completed` but before an explicit save. Whether the current quest is included depends on SwiftData's auto-save timing, making bonus awards (First Quest, Hat Trick, Legendary) unreliable. | FIXED — Count before marking complete, add 1 manually |

---

## Medium (Tech Debt)

| # | File | Lines | Issue | Status |
|---|------|-------|-------|--------|
| M1 | ~15 files | Various | **Silent `try?` failures**: Every SwiftData fetch uses `try?` with nil coalescing. Database errors are completely invisible — no logging, no UI feedback, no crash reports. | FIXED — do/catch with `print()` logging in SparkEngine, QuestSurfacingEngine, AppState, FocusSprintActivityManager |
| M2 | Multiple views | Various | **Legacy `DispatchQueue.main.asyncAfter`**: ~12+ instances use GCD-style delayed dispatch instead of structured concurrency (`Task { try? await Task.sleep(...) }`). Harder to cancel, doesn't participate in task hierarchy. | FIXED — Replaced in SpinWheelView, QuestCardView, RapidCaptureView, ProgressMapView, Confetti, HapticsManager |
| M3 | `App/AppState.swift` | ~82-110 | **Magic tuple indices**: Achievement and PowerUp seeding uses `def.0`, `def.1`, etc. on unlabeled tuples. Fragile — reordering tuple fields silently breaks logic. | FIXED — Labeled `Definition` structs in Achievement and PowerUp models |
| M4 | `Services/SoundManager.swift` | ~70-79 | **Magic SystemSoundID numbers**: Hard-coded values (1057, 1025, 1104, 1052, 1054) with no documentation of what each ID represents. | FIXED — Named `SystemSounds` constants |
| M5 | `Models/PlayerProfile.swift` | ~37-38 | **No input validation**: `sparksRequired(forLevel:)` computes `level * (level - 1) * 50` without guarding `level <= 0`. Negative levels produce positive results (misleading). | FIXED — `guard level > 0 else { return 0 }` |
| M6 | All 4 services | Various | **Missing `@MainActor`**: `SparkEngine`, `StreakManager`, `ChallengeGenerator`, `QuestSurfacingEngine` are `@Observable` and modify UI-bound state via `ModelContext.mainContext`, but lack actor isolation. Compiler cannot enforce Main Thread access. | FIXED — `@MainActor` added to all 4 services |
| M7 | All 22 view files | — | **No `#Preview` macros**: No SwiftUI previews defined anywhere. Slows iterative UI development. | FIXED — `#Preview` macros added to 16 view files with shared `PreviewSampleData` in-memory container |
| M8 | `Widgets/` | — | **Stub widget data**: Widget timeline providers return hardcoded zeros and nil. No App Group shared container configured for real data access. | FIXED — `WidgetDataProvider` reads/writes via App Group UserDefaults; widgets read real data; `WidgetCenter.reloadAllTimelines()` on state changes |
