# Models & Data Layer Reference (`service_tracearr`)

This document describes the domain models in `lib/src/models/tracearr_models.dart` and their relationship to generated OpenAPI DTOs.

---

## 1. DTO vs. Domain Model Strategy

`service_tracearr` separates network DTOs from UI domain models:
- **Generated DTOs (`lib/src/generated/models/`)**: Mirrors backend JSON schemas verbatim. DTOs often contain loose types, optional nullable fields, and raw internal IDs.
- **Domain Models (`lib/src/models/tracearr_models.dart`)**: Strongly-typed, immutable Dart classes designed specifically for Atrium UI consumption.
- **Mappers (`lib/src/mappers/`)**: Pure functions that transform DTOs into Domain Models, resolving proxy image URLs and sanitizing string-encoded integers.

---

## 2. Core Domain Models Catalog

### 2.1 Media Domain Models

| Model Class | Source DTO | Purpose | Key Attributes |
| :--- | :--- | :--- | :--- |
| `TracearrRecentlyAddedItem` | `RecentlyAddedRecord` (v1) | Feed item in Media Tab. | `id`, `title`, `year`, `mediaType`, `seasonNumber`, `episodeNumber`, `parentRatingKey`, `grandparentRatingKey`, `resolvedPosterUrl`, `addedAt`, `removedAt`. |
| `TracearrRecentlyAddedPage` | `RecentlyAddedResponse` (v1) | Cursor-paginated page. | `items`, `nextCursor`. |
| `TracearrMediaDetail` | `MediaResource` + Stats + Watchers (v2) | Full intelligence hub for a title. | `id`, `title`, `year`, `mediaType`, `showMediaId`, `imdbId`, `tmdbId`, `tvdbId`, `availability`, `children`, `watchers`, `allTimePlays`, `allTimeWatchTimeMs`. |
| `TracearrMediaChild` | `MediaChild` (v2) | Child season or episode in hierarchy. | `id`, `title`, `mediaType`, `seasonNumber`, `episodeNumber`, `episodeCount`, `thumbUrl`. |
| `TracearrMediaAvailability` | `MediaAvailability` (v2) | Physical storage & server presence. | `serverId`, `serverType`, `ratingKey`, `libraryId`, `videoResolution`, `fileSize`, `addedAt`. |
| `TracearrMediaWatcher` | `Watcher` (v2) | Top audience viewer entry. | `userId`, `username`, `plays`, `watchTimeMs`, `distinctEpisodes`. |

---

### 2.2 Activity & Stream Models

| Model Class | Source DTO | Purpose | Key Attributes |
| :--- | :--- | :--- | :--- |
| `TracearrActiveSession` | `Session` (v1) | Real-time playing stream card. | `id`, `serverId`, `serverType`, `user`, `title`, `parentTitle`, `grandparentTitle`, `progressPercent`, `state`, `transcodeDecision`, `videoDecision`, `audioDecision`, `bandwidth`, `container`. |
| `TracearrHistoryItem` | `HistoryRecord` (v2) | Historical watch session row. | `id`, `serverId`, `serverName`, `user`, `title`, `mediaType`, `seasonNumber`, `episodeNumber`, `watchedAt`, `durationSeconds`, `percentComplete`, `transcodeDecision`. |
| `TracearrHistoryPage` | `HistoryResponse` (v2) | Paginated history log. | `items`, `page`, `totalPages`, `totalCount`. |

---

### 2.3 User Directory Models

| Model Class | Source DTO | Purpose | Key Attributes |
| :--- | :--- | :--- | :--- |
| `TracearrUserSummary` | `UserIdentity` + Stats (v2) | User list item on People tab. | `id`, `username`, `thumbUrl`, `totalPlays`, `watchTimeHours`, `lastSeen`. |
| `TracearrUserDetail` | `UserIdentity` + `UserStatsResponse` + History (v2) | Full user dossier. | `id`, `username`, `thumbUrl`, `totalPlays`, `watchTimeHours`, `topGenres`, `deviceBreakdown`, `recentHistory`. |

---

### 2.4 Overview & Fleet Models

| Model Class | Source DTO | Purpose | Key Attributes |
| :--- | :--- | :--- | :--- |
| `TracearrHealthResponse` | `HealthResponse` (v1) | Fleet server status. | `status`, `version`, `timestamp`, `servers` (`List<TracearrServerStatus>`). |
| `TracearrTodayStats` | `TodayStatsResponse` (v1) | 24-hour fleet pulse. | `activeStreams`, `todayPlays`, `watchTimeHours`, `alertsLast24h`. |
| `TracearrActivityTrend` | `ActivityResponse` (v1) | 7-day activity histogram. | `period`, `totalPlays`, `buckets` (`List<ActivityBucket>`). |

---

## 3. Mapper Transformations & Normalization

Mappers in `lib/src/mappers/` enforce critical normalization rules:
1. **Safe Integer Deserialization**: Legacy v1 endpoints occasionally encode integers as strings in JSON (e.g. `"year": "2024"`). Mappers use `int.tryParse()` to prevent runtime format exceptions.
2. **Artwork Resolution**: Resolves relative thumbnail paths (e.g. `/library/metadata/123/thumb`) into authenticated Atrium proxy URLs using `TracearrMediaUrlResolver`.
3. **Episode Poster Fallback**: For TV episodes, mappers prioritize `grandparentRatingKey` over `ratingKey` to ensure vertical 2:3 series poster artwork across Plex, Jellyfin, and Emby servers instead of stretched 16:9 still captures.
