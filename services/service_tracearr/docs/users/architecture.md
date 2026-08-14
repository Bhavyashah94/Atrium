# User Directory & Dossier Subsystem (`service_tracearr/docs/users`)

This document describes user directory aggregation, audience metrics, and user dossier screens.

---

## 1. Subsystem Architecture

```
lib/src/people/
├── people_tab.dart                     - User directory list with search and lifetime play sorting.
├── screens/
│   └── tracearr_user_dossier_screen.dart - Deep user intelligence dossier.
└── widgets/
    └── user_summary_tile.dart          - User list item displaying avatar, plays, and watch hours.
```

---

## 2. User Dossier Intelligence (`TracearrUserDossierScreen`)

The User Dossier aggregates three asynchronous endpoints for a specific user:
1. **User Identity** (`GET /api/v2/public/users/{id}`): Display name, avatar URL, registered media server accounts.
2. **User Statistics** (`GET /api/v2/public/users/{id}/stats`):
   - Lifetime telemetry: Total plays, total watch duration in hours.
   - Favorite Genres breakdown (e.g. Action, Comedy, Sci-Fi).
   - Device distribution: Roku, Apple TV, Web, iOS, Android.
3. **User Playback History** (`GET /api/v2/public/users/{id}/history`): Chronological list of watch sessions executed by this user across the entire fleet.

---

## 3. Relationship with Media Watchers

The User subsystem forms a bidirectional relationship with the Media subsystem:
- **From Media $\rightarrow$ User**: Tapping any user in `MediaWatchersLeaderboard` navigates to `TracearrUserDossierScreen`.
- **From User $\rightarrow$ Media**: Tapping any media title in the User Dossier's recent history feed navigates to `TracearrMediaDetailScreen`.
