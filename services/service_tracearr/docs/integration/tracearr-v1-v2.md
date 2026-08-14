# Tracearr API v1 vs. v2 Coexistence Strategy (`service_tracearr/docs/integration`)

> [!WARNING]
> **CRITICAL ARCHITECTURAL WARNING FOR CONTRIBUTORS**:
> Do not attempt to "clean up" or eliminate Tracearr v1 API calls in favor of v2 without reading this document. The coexistence of both API versions is an intentional, permanent architectural requirement.

---

## 1. Why Both API Generations Coexist

| Feature Area | API Used | Why v1 is Required / Irreplaceable | Why v2 is Required |
| :--- | :---: | :--- | :--- |
| **Recently Added Feed** | **v1** (`/api/v1/media/recent`) | Returns raw `rating_key`, `parent_rating_key`, `grandparent_rating_key`, `server_id`, and `server_type`. These are required by `TracearrMediaUrlResolver` to construct valid authenticated image proxy URLs on the client. | v2 endpoints abstract away server rating keys and server types into server-agnostic UUIDs that cannot resolve downstream server artwork. |
| **Fleet Health & Server List**| **v1** (`/api/v1/health`) | Returns server connectivity state (`online: true/false`), server types (Plex, Jellyfin, Emby), and per-server live stream counts. | v2 has no server health or connectivity endpoint. |
| **Active Live Streams** | **v1** (`/api/v1/activity`) | Returns real-time session state, buffer progress, bandwidth, and stream decision. | v2 is primarily focused on historical playback records. |
| **24h Fleet Stats & Trends**| **v1** (`/api/v1/stats/today`) | Returns aggregated 24h play totals, watch hours, and 7-day trend buckets. | v2 does not expose 24h fleet rolling aggregates. |
| **Media Details & Telemetry** | **v2** (`/api/v2/public/media/`)| — | Provides canonical media UUIDs, multi-server availability, watchers leaderboard, and TV hierarchy. |
| **User Directory & Dossiers** | **v2** (`/api/v2/public/users/`)| — | Provides user identities, favorite genres, lifetime stats, and per-user history. |
| **Dedicated Item History** | **v2** (`/api/v2/public/media/{ref}/history`) | — | Provides dedicated playback history filtered specifically to a single media item. |

---

## 2. Identifier Resolution Bridge

`TracearrMediaDetailScreen.navigate()` bridges v1 and v2 seamlessly:
- When opened from the v1 Recently Added feed, the item provides `mediaId ?? ratingKey ?? id`.
- The v2 backend endpoint `/api/v2/public/media/{ref}` natively accepts either:
  1. A canonical Tracearr v2 UUID (e.g. `c4b8e21a-...`)
  2. A downstream media server rating key (e.g. `46000`)
- This allows v1 ingestion feeds to route directly into v2 intelligence detail screens with zero friction.
