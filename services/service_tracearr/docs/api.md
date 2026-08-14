# API Integration & Contract Reference (`service_tracearr`)

This document details the Tracearr v1 and v2 API contracts utilized by `service_tracearr`.

---

## 1. API Architecture & Versioning Strategy

Tracearr exposes two API generations:
- **v1 API (`RawPublicAPIApi`)**: Legacy server-centric API providing raw ingestion logs, server rating keys, direct health checks, stream termination, security violations, and 30-day activity rollups.
- **v2 API (`RawPublicAPIV2Api`)**: Modern media-centric and user-centric RESTful API providing canonical media entities, audience statistics, watchers leaderboards, user dossiers, and TV hierarchy trees.

---

## 2. Endpoints Inventory

### 2.1 Tracearr v1 Endpoints (`RawPublicAPIApi`)

| Endpoint Path | Generated Method | Purpose in Atrium |
| :--- | :--- | :--- |
| `GET /api/v1/health` | `getPublicHealth` | Fleet health, version string, server online statuses, and live stream counts. |
| `GET /api/v1/activity` | `getPublicActivity` | Active stream list, user playback state, stream bandwidth, and transcode decision. |
| `GET /api/v1/stats/today` | `getPublicStatsToday` | 24-hour fleet pulse (today plays, today watch hours, security alerts count). |
| `GET /api/v1/stats` | `getPublicStats` | 30-day aggregate statistics (total plays, total watch duration). |
| `GET /api/v1/violations` | `getPublicViolations` | Security incidents, concurrent stream rule violations, and unauthorized IPs. |
| `POST /api/v1/streams/terminate/{id}` | `postPublicStreamsTerminateById` | Terminate an active playback stream on a media server. |

### 2.2 Tracearr v2 Endpoints (`RawPublicAPIV2Api`)

| Endpoint Path | Generated Method | Purpose in Atrium |
| :--- | :--- | :--- |
| `GET /api/v2/public/streams` | `getPublicStreams` | Real-time active streams list. |
| `GET /api/v2/public/history` | `getPublicHistory` | Fleet-wide chronological watch history feed. |
| `GET /api/v2/public/media/recent` | `getPublicRecentlyAdded` | Cursor-paginated recently added media. |
| `GET /api/v2/public/libraries` | `getPublicLibraries` | Library storage rollups and media item counts. |
| `GET /api/v2/public/media/{ref}` | `getPublicMediaByRef` | Canonical media intelligence, availability copies, external IDs (IMDb/TMDb). |
| `GET /api/v2/public/media/{ref}/stats` | `getPublicMediaStatsByRef` | Lifetime, 30-day, and 7-day play counts and watch duration for a title. |
| `GET /api/v2/public/media/{ref}/watchers` | `getPublicMediaWatchersByRef` | Top audience leaderboard for a title, ranked by plays and watch time. |
| `GET /api/v2/public/media/{ref}/children` | `getPublicMediaChildrenByRef` | TV series hierarchy (seasons of a show, or episodes of a season). |
| `GET /api/v2/public/media/{ref}/history` | `getPublicMediaHistoryByRef` | Dedicated playback history for a single media title. |
| `GET /api/v2/public/users` | `getPublicUsers` | Registered user identities directory. |
| `GET /api/v2/public/users/{id}` | `getPublicUsersById` | User identity profile, avatar URL, and server account mapping. |
| `GET /api/v2/public/users/{id}/stats` | `getPublicUsersStatsById` | Lifetime user statistics, top genres, and device usage distribution. |
| `GET /api/v2/public/users/{id}/history` | `getPublicUsersHistoryById` | Chronological playback history for a specific user. |

---

## 3. OpenAPI Code Generation

- **Source Specifications**: `tool/v1.json` and `tool/v2.json`.
- **Generated Output**: `lib/src/generated/api/` (`raw_public_a_p_i_api.dart`, `raw_public_a_p_i_v2_api.dart`) and `lib/src/generated/models/`.
- **Contract Rule**: Generated files must never be edited manually. Any schema corrections should be applied to the OpenAPI specs or handled in the mapping layer.

---

## 4. Authentication Mechanism

- **Scheme**: Tracearr APIs (v1 and v2) strictly use **Bearer token authentication** (`Authorization: Bearer <token>`).
- **Interceptor**: Injected by `core_networking`'s `AuthInterceptor` when `InstanceAuth.apiKey` is configured for `ServiceKind.tracearr`.
- **No `x-api-key`**: Unlike `*arr` applications that expect `X-Api-Key` headers, Tracearr's backend authentication middleware does not accept `x-api-key` / `X-Api-Key` headers and rejects them with `401 Unauthorized` if `Authorization: Bearer` is missing.
- **Image Proxy**: Authenticated image requests to `/api/v1/images/proxy` pass `Authorization: Bearer $token` headers via `TracearrMediaUrlResolver.getImageHeaders()`.

