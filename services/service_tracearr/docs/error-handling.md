# Error Handling & Resilience (`service_tracearr`)

This document describes error boundaries, network failure handling, empty states, and section isolation in `service_tracearr`.

---

## 1. Core Error Philosophy

`service_tracearr` enforces strict **fault containment**:
- **Granular Failures**: A failure in a secondary data stream (e.g. Dedicated History failing to fetch) must **never** take down the entire screen (e.g. Media Details).
- **Graceful Degradation**: Empty feeds, missing artwork, or unresolvable URLs must render clean, informative fallbacks rather than raw error stack traces or blank screens.
- **No Leaked Internal IDs**: Internal GUIDs, tokens, and database keys must never be exposed to users in error banners or dialogs.

---

## 2. Section Isolation & Async Boundaries

### 2.1 Media Detail Screen Isolation
On `TracearrMediaDetailScreen`, three distinct async providers operate concurrently:
1. **`tracearrMediaDetailProvider`**: Core metadata, availability, stats, and watchers. If this fails, the screen displays a full-screen retry view.
2. **`tracearrMediaChildrenProvider`**: Season episodes in `MediaTvHierarchyView`. Each season accordion operates in its own `Consumer`. If one season fails to load, only that season displays an inline error message; all other seasons remain fully usable.
3. **`tracearrMediaHistoryProvider`**: `MediaDedicatedHistoryFeed` runs in its own `Consumer`. If the playback history API returns an error, the history box displays a localized error container with a retry button while leaving metadata and availability interactive.

### 2.2 Overview Tab Multi-Provider Resilience
`OverviewTab` aggregates four independent providers (`tracearrHealthProvider`, `tracearrStatsTodayComputedProvider`, `tracearrActiveStreamsProvider`, `tracearrActivityTrendsProvider`). If one provider fails (e.g. 7-day activity histogram returns 500), the health banner and active stream tiles continue to render normally.

---

## 3. Network & HTTP Status Handling

| HTTP Code / Exception | Handling Strategy | User Experience |
| :--- | :--- | :--- |
| **401 Unauthorized** | Caught by Dio interceptor; triggers Atrium instance re-authentication. | Redirects or prompts user to update API key. |
| **404 Not Found** | Throws typed `TracearrException('Item not found')`. | Displays empty state or user-friendly error card. |
| **500 Server Error** | Logged via standard logger; returns localized `error` state in Riverpod. | Inline retry button invalidating the failed provider family. |
| **SocketException / Timeout** | Caught by Dio; mapped to connectivity error message. | Displays offline indicator and retry button. |

---

## 4. Empty States Catalog

- **Recently Added Feed Empty**: Renders `EmptyState(icon: Icons.movie_outlined, title: 'No media items found', message: 'Try switching library filters...')`.
- **No Active Streams**: Renders `EmptyState(icon: Icons.play_disabled_outlined, title: 'No active streams', message: 'Servers are currently idle.')`.
- **No Dedicated Playback Sessions**: Renders `Container(child: Text('No watch sessions recorded for this item.'))`.
- **No Security Violations**: Renders `EmptyState(icon: Icons.shield_outlined, title: 'Fleet Secure', message: 'No policy violations recorded.')`.
