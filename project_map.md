# SparkDo — Project Architecture Map

## Overview

| Aspect | Value |
|--------|-------|
| **Primary Framework** | SwiftUI (iOS 17+), `@Observable` macro |
| **UIKit Usage** | None — pure SwiftUI |
| **Dependency Management** | Zero third-party dependencies (no SPM/CocoaPods/Carthage) |
| **Architecture Pattern** | Lightweight MVVM — `@Observable` services injected via central `AppState` coordinator |
| **Persistence Layer** | SwiftData (7 `@Model` classes, local SQLite, CloudKit disabled) |
| **Networking Stack** | None (StoreKit 2 is the only external communication) |
| **Minimum Deployment** | iOS 17.0, iPhone + iPad |

---

## Entry Point & Dependency Graph

```
SparkDoApp.swift (@main)
│
├── ModelContainer
│   Schema: Quest, SparkTransaction, Streak, PowerUp,
│           DailyChallenge, PlayerProfile, Achievement
│   Config: local SQLite, no CloudKit
│
└── AppState (lazy init in .onAppear)
    │
    ├── Services (all receive ModelContext via constructor injection)
    │   ├── SparkEngine          — XP calculation, leveling, bonus tracking
    │   ├── StreakManager         — Forgiving streak with shield days
    │   ├── ChallengeGenerator   — Daily challenge templates
    │   ├── QuestSurfacingEngine — Quest sorting/recommendation
    │   └── StoreKitManager      — StoreKit 2 IAP (independent, no ModelContext)
    │
    ├── Singletons / Statics
    │   ├── SoundManager.shared  — AVAudioPlayer wrapper (singleton)
    │   └── HapticsManager       — UIFeedbackGenerator (static enum)
    │
    ├── Loaded Entities
    │   ├── PlayerProfile        — Singleton from DB (or freshly created)
    │   ├── Streak               — Singleton from DB (or freshly created)
    │   └── DailyChallenge       — Today's challenge (or freshly generated)
    │
    └── ContentView (TabView, 5 tabs)
        ├── Tab 0: DashboardView
        │   ├── SparkCounterView
        │   ├── DailyChallengeCard
        │   ├── StreakFlameView (→ StreakDetailSheet)
        │   └── QuickActionButtons → QuestBoard / SpinWheel / Sprint
        │
        ├── Tab 1: QuestBoardView
        │   ├── QuestCardView (swipe-to-complete/skip)
        │   ├── SpinWheelView (sheet)
        │   └── QuestTimerView (fullScreenCover)
        │
        ├── Tab 2: (intercepted → RapidCaptureView sheet)
        │   └── Also accessible: QuestCraftView
        │
        ├── Tab 3: ProgressTabView
        │   ├── ProgressMapView
        │   ├── AchievementsView (→ AchievementDetailSheet)
        │   └── PowerUpShopView
        │
        └── Tab 4: SettingsView
            └── PaywallView (sheet)
```

---

## Module Dependency Matrix

| Module | Depends On |
|--------|-----------|
| **Models/** | Foundation, SwiftData (standalone, no cross-model deps except Quest→Quest self-ref) |
| **Services/** | Models, SwiftData ModelContext, AVFoundation (SoundManager), UIKit (HapticsManager), StoreKit (StoreKitManager) |
| **Extensions/** | SwiftUI only (standalone utilities) |
| **Views/Dashboard/** | Models, Services (via AppState), Extensions |
| **Views/QuestBoard/** | Models, Services (via AppState), Extensions |
| **Views/Capture/** | Models, SwiftData ModelContext, Extensions |
| **Views/Progress/** | Models, Services (via AppState), Extensions |
| **Views/Shop/** | Models, Services, Extensions |
| **Views/Settings/** | Models, Services (StoreKit), Extensions |
| **Widgets/** | WidgetKit, Models (stub loaders — no shared App Group yet) |
| **LiveActivity/** | ActivityKit, WidgetKit, Extensions |
| **App/** | Everything above |

---

## Persistence Schema

```
┌─────────────────┐     ┌──────────────────┐
│     Quest       │──┐  │ SparkTransaction │
│ @Model          │  │  │ @Model           │
│ - title         │  │  │ - amount         │
│ - xpValue       │  │  │ - source (enum)  │
│ - energyLevel   │  │  │ - earnedAt       │
│ - status (enum) │  │  └──────────────────┘
│ - estimatedMin  │  │
│ - parentQuest?──│──┘  ┌──────────────────┐
│ - childQuests[] │     │   Streak         │
└─────────────────┘     │ @Model           │
                        │ - currentDays    │
┌─────────────────┐     │ - shieldDays     │
│ PlayerProfile   │     │ - lastActiveDate │
│ @Model          │     └──────────────────┘
│ - totalSparks   │
│ - level         │     ┌──────────────────┐
│ - isPremium     │     │  Achievement     │
│ - questsCompleted│    │ @Model           │
└─────────────────┘     │ - key, name      │
                        │ - rarity (enum)  │
┌─────────────────┐     │ - isUnlocked     │
│   PowerUp       │     └──────────────────┘
│ @Model          │
│ - category (enum)│    ┌──────────────────┐
│ - sparkCost     │     │ DailyChallenge   │
│ - isPurchased   │     │ @Model           │
└─────────────────┘     │ - targetCount    │
                        │ - bonusSparks    │
                        └──────────────────┘
```

---

## File Inventory (40 files, ~5,245 lines)

| Directory | Files | Purpose |
|-----------|-------|---------|
| `SparkDo/` | `SparkDoApp.swift` | App entry point, ModelContainer |
| `App/` | `AppState.swift` | Central coordinator, service initialization |
| `Models/` | 7 files | SwiftData `@Model` entities |
| `Services/` | 7 files | Business logic, haptics, sound, StoreKit |
| `Views/Dashboard/` | 4 files | Home screen components |
| `Views/QuestBoard/` | 4 files | Task board, spin wheel, timer |
| `Views/Capture/` | 2 files | Brain dump, detailed quest creation |
| `Views/Progress/` | 3 files | Map, achievements, weekly recap |
| `Views/Shop/` | 1 file | Cosmetic power-up store |
| `Views/Settings/` | 2 files | Settings, paywall |
| `Views/` | `ContentView.swift` | Root TabView + navigation |
| `Widgets/` | 2 files | WidgetKit small/medium widgets |
| `LiveActivity/` | 1 file | ActivityKit for focus sprints |
| `Extensions/` | 3 files | Theme, confetti, shimmer |
