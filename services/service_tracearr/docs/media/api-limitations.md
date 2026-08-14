# Media API Boundaries & Limitations (`service_tracearr/docs/media`)

This document records the upstream API schema limitations and backend boundaries in the Media subsystem.

---

## 1. Documented Backend Boundaries

### 1.1 Direct Episode $\rightarrow$ Season UUID Resolution
- **Description**: The Tracearr v2 `MediaResource` DTO returns `show_media_id` ("Canonical id of the parent show"), but does **not** expose a `season_media_id` property.
- **Architectural Solution**: Direct Episode $\rightarrow$ Season UUID resolution is not supported by the API schema. Instead, Atrium implements the **Episode $\rightarrow$ Series Contextual Handshake**: jumping from an episode to its series auto-expands the matching season and highlights the originating episode.

---

### 1.2 Non-Plex Media Server Web Player Deep Links
- **Description**: The `MediaAvailability` DTO exposes `serverId` (server UUID), `serverType`, and `ratingKey`, but does **not** provide the downstream server's public web host URL.
- **Platform Difference**:
  - **Plex**: Can be launched globally via `https://app.plex.tv/desktop/#!/server/$machineId/details?key=...`.
  - **Jellyfin / Emby**: Requires direct host IP/domain addresses (e.g. `http://jellyfin.local:8096/#!/details?id=...`), which are not exposed in the Tracearr API surface.
- **Client Handling**: When non-Plex servers are tapped, Atrium displays: `"Direct web player launching is currently only supported for Plex servers."` rather than attempting to construct broken URLs or leaking internal GUIDs.

---

### 1.3 Library Names vs. Content-Type Rollups
- **Description**: `/api/v2/public/libraries` returns `LibraryRollup` objects containing `id`, `server_id`, `movie_count`, `show_count`, and `track_count`, but does not return custom human-assigned library name strings (e.g. "4K Movies").
- **Client Handling**: Content-type labels are dynamically derived:
  - If `movieCount > 0`: `Movies (${lib.itemCount})`
  - If `showCount > 0`: `TV Shows (${lib.itemCount})`
  - If `trackCount > 0`: `Music (${lib.itemCount})`
  - In multi-server fleets, the server type is prefixed (e.g. `PLEX Movies (1200)`, `JELLYFIN TV Shows (450)`).

---

### 1.4 Recently Added Episode Metadata Limitation

#### Upstream API Limitation
- **Description**: Tracearr's Recently Added endpoint (`GET /api/v2/public/recently-added`) does not currently serialize `show_title`, `season_number`, `episode_number`, or a canonical `show_media_id` on episode records in `RecentlyAddedRecord`.
- **Backend Discrepancy**: These fields are actively available through other Tracearr API surfaces (such as `/history` and `/streams`), confirming that the backend database possesses the underlying relational metadata, but the Recently Added serialization contract omits it.
- **No Batch Media Lookup**: There is no batch lookup endpoint (such as `POST /api/v2/public/media/batch` or `GET /api/v2/public/media?ids=...`) in either v1 or v2 APIs.
- **No N+1 Lookups**: Per-item `GET /api/v2/public/media/{ref}` lookups must **not** be performed to enrich cards in the Recently Added grid, as that creates an $N+1$ request pattern (e.g. 30 individual round trips per page).
- **Unreliable Regex Parsing**: Plex, Jellyfin, and Emby expose season and episode numbers as structured fields (`parentIndex`/`index` or `ParentIndexNumber`/`IndexNumber`), while canonical titles store clean strings without prefixes (e.g. `"Meet My Juniors, Nya"`). Regex heuristics (`SxxExx`) fail on >95% of indexed library items and must not be used as a primary solution.

#### Current Client Behavior
- The Recently Added grid and list render the metadata actually provided by the endpoint: poster artwork, item title, and media type badge.
- Tapping an item navigates to the full **Media Detail screen** (`TracearrMediaDetailScreen`), which loads `GET /api/v2/public/media/{ref}` to provide the complete series, season hierarchy, and episode context.
- This design is an **intentional boundary decision** to preserve low latency and zero network overhead, rather than an accidental omission.

#### Preferred Upstream Solution
To enable `S1:E2 • Show Title` rendering in Recently Added with **zero additional network requests**, Tracearr's backend should enhance `RecentlyAddedRecord` to include:
```json
{
  "id": "...",
  "media_type": "episode",
  "title": "Meet My Juniors, Nya",
  "show_title": "Chainsmoker Cat",
  "season_number": 1,
  "episode_number": 2,
  "show_media_id": "canonical_show_id"
}
```
- `show_title`, `season_number`, and `episode_number` are the minimum fields required for rich Recently Added episode presentation.
- `show_media_id` is additionally desirable for canonical parent-show identity and navigation, but is not strictly required just to render `S1:E2 • Show Title`.
- The preferred solution is an upstream Tracearr schema enhancement so data arrives directly in the existing response payload.

#### Architectural Principle
> [!IMPORTANT]
> **Do not compensate for missing upstream relational metadata with per-item network requests when the upstream system already possesses the data. Prefer an upstream contract improvement over an $N+1$ client-side workaround.**

