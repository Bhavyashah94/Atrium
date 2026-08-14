# User Workflows & Behavioral Journeys (`service_tracearr`)

This document outlines the core end-to-end user journeys within `service_tracearr`.

---

## 1. Core Workflow Catalog

### Workflow 1: Discovering Recently Ingested Media
1. User opens **Media Tab**.
2. Top bar (`MediaStorageSummaryBar`) displays storage breakdown and content-type chips (e.g. `PLEX Movies (1200)`, `JELLYFIN TV Shows (450)`).
3. Grid/List catalog displays recently added items with relative timestamps (e.g. `Added 2h ago`), year, and `S{s}:E{e}` badges.
4. User scrolls downward: `EasyRefresh.onLoad` automatically triggers `TracearrRecentPaginatedNotifier.loadMore()`, appending deduplicated pages seamlessly.
5. User taps any card $\rightarrow$ routes to `TracearrMediaDetailScreen`.

---

### Workflow 2: TV Series Exploration & Contextual Sibling Navigation
1. User taps an episode (e.g. `Succession S02:E07`) from the Recently Added feed.
2. `TracearrMediaDetailScreen` opens with episode details, stream availability, and parent series link.
3. User taps the **`Series`** ActionChip.
4. The parent Show detail screen opens:
   - TV Hierarchy is promoted to primary position directly beneath header metadata.
   - **Season 2 is automatically expanded** (`initiallyExpanded: true`).
   - **Episode 7 is highlighted with `CURRENT` badge**.
5. User immediately sees adjacent sibling episodes (`Episode 6`, `Episode 8`) and can tap Episode 8 in **1 click**.

---

### Workflow 3: Investigating a Stream Transcode & Quality Issue
1. User views **Activity Tab** or **Overview Tab** and sees an active stream (or historical session).
2. Tapping the stream card opens `StreamDiagnosticsSheet` (or `HistorySessionDiagnosticsSheet` for history).
3. The diagnostics sheet displays:
   - Stream Decision: Direct Play vs. Hardware / Software Transcode.
   - Codecs & Container: Video (H.264 $\rightarrow$ HEVC), Audio (TrueHD 7.1 $\rightarrow$ AAC 2.0).
   - Bitrates: Source bitrate vs. Transcode stream bitrate.
   - Hardware Acceleration: Intel QuickSync / NVIDIA NVENC indicators.
   - Device & Client Profile: Apple TV, Chrome, Roku, etc.
4. Tapping the username in the sheet navigates directly to `TracearrUserDossierScreen`.

---

### Workflow 4: Audience Analysis for a Specific Title
1. User opens `TracearrMediaDetailScreen` for a movie (e.g. *Interstellar*).
2. **Top Watchers Leaderboard** displays the most active viewers ranked by play count and watch time.
3. Tapping a top watcher row navigates to `TracearrUserDossierScreen`, showing the user's complete viewing profile.
4. **Dedicated Playback History Feed** lists every historical session for *Interstellar* across all servers.

---

### Workflow 5: Security Violation & Concurrent Stream Triage
1. User receives an alert or navigates to **Security Tab**.
2. Active violations list displays concurrent stream limit breaches (e.g. "User streaming on 4 devices simultaneously").
3. User reviews IP address, geolocation, and active sessions.
4. Tapping **Acknowledge** fires `POST /api/v1/security/violations/{id}/acknowledge`, resolving the incident.
