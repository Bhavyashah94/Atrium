# Testing & Verification Guide (`service_tracearr`)

This document describes the test architecture, test suites, and verification procedures for `service_tracearr`.

---

## 1. Test Suite Structure

The package test suite resides in `services/service_tracearr/test/` and is structured into domain areas:

```
services/service_tracearr/test/
├── activity/
│   ├── activity_tab_test.dart                 - Stream rendering and history feeds.
│   ├── history_item_card_test.dart            - History row tap actions & navigation.
│   └── history_session_diagnostics_sheet_test.dart - Transcode metrics & hardware acceleration.
├── datasources/
│   └── tracearr_remote_data_source_test.dart  - Dio HTTP and OpenAPI client mapping.
├── mappers/
│   ├── tracearr_activity_mapper_test.dart     - Active session and trend DTO mapping.
│   ├── tracearr_history_mapper_test.dart      - Historical playback session mapping.
│   ├── tracearr_media_mapper_test.dart        - MediaResource and hierarchy mapping.
│   ├── tracearr_recent_mapper_test.dart       - Recently added and artwork resolution mapping.
│   └── tracearr_user_mapper_test.dart         - User identity and dossier stats mapping.
├── media/
│   └── media_tab_test.dart                    - Media tab, detail screens, hierarchy, & navigation.
├── overview/
│   └── overview_tab_test.dart                 - Health, 24h stats tiles, and trend histograms.
├── people/
│   └── people_tab_test.dart                   - User list and dossier rendering.
├── providers/
│   └── tracearr_providers_test.dart           - State machines, pagination, and notifiers.
├── repository/
│   └── tracearr_repository_test.dart          - Deduplication, fallback logic, and service API.
├── security/
│   └── security_tab_test.dart                 - Violation triage and acknowledgement.
├── tracearr_home_test.dart                    - Navigation bar and tab destination switching.
└── tracearr_parser_test.dart                  - Serialization and string-integer edge cases.
```

---

## 2. Key Verified Invariants

The test suite enforces critical behavioral contracts:
1. **Artwork Resolution Fallback**: Verifies that TV episodes prioritize `grandparentRatingKey` over `ratingKey` to produce vertical series posters across Plex, Jellyfin, and Emby.
2. **Episode $\rightarrow$ Series Contextual Navigation**: Verifies that jumping from an episode (e.g. S02E07) to the parent show forwards season/episode context, auto-expands Season 2, and renders the `CURRENT` badge on Episode 7.
3. **Hierarchy Promotion**: Verifies that `MediaTvHierarchyView` precedes `MediaAvailabilityCard` and stats on show detail screens.
4. **Pagination Concurrency & Deduplication**: Verifies that `TracearrRecentPaginatedNotifier` blocks concurrent requests during loading and filters out duplicate items across page boundaries.
5. **Non-Plex Feedback Notice**: Verifies that tapping non-Plex media availability launchers displays clean user guidance without exposing raw server GUIDs.

---

## 3. Running Tests & Static Analysis

### Run Full Test Suite
```bash
flutter test services/service_tracearr
```

### Run Static Analysis
```bash
flutter analyze services/service_tracearr
```

### Run Focused Tests
```bash
# Test Media workflow and detail screen
flutter test services/service_tracearr/test/media/media_tab_test.dart

# Test Providers and Paginated Notifiers
flutter test services/service_tracearr/test/providers/tracearr_providers_test.dart

# Test Repository Deduplication and Artwork Logic
flutter test services/service_tracearr/test/repository/tracearr_repository_test.dart
```
