# Media Subsystem Architecture (`service_tracearr/docs/media`)

This document details the architecture, models, and presentation flow of the Media subsystem.

---

## 1. Subsystem Purpose

The Media subsystem provides fleet-wide library statistics, content-type filtering, cursor-paginated recently ingested media catalogs, and comprehensive media intelligence hubs (`TracearrMediaDetailScreen`).

---

## 2. Component Structure

```
lib/src/media/
├── media_tab.dart                      - Top-level scaffold with EasyRefresh & storage bar.
├── tracearr_media_url_resolver.dart    - Resolves proxy artwork and media server deep links.
├── screens/
│   ├── tracearr_media_detail_screen.dart - Deep intelligence hub for Movie/Show/Season/Episode.
│   └── widgets/
│       ├── media_availability_card.dart  - Multi-server physical storage and player launch actions.
│       ├── media_dedicated_history_feed.dart - Dedicated playback history per title.
│       ├── media_tv_hierarchy_view.dart  - Season accordions and on-demand episode breakdown.
│       └── media_watchers_leaderboard.dart - Top audience leaderboard per title.
└── widgets/
    ├── media_storage_summary_bar.dart   - Library rollups and content-type chips.
    ├── recently_added_card.dart         - List-mode item card with Sxx:Eyy and added timestamp.
    ├── recently_added_grid.dart         - Responsive 2-to-6 column grid / list switcher.
    └── recently_added_poster_tile.dart  - Grid-mode 2:3 vertical poster tile.
```

---

## 3. Information Architecture by Media Type

```
+---------------------------------------------------------------------------------------------------+
| MOVIE DETAIL                                                                                      |
| 1. Hero Backdrop + Identity + External Chips (IMDb / TMDb / TheTVDB)                              |
| 2. Cross-Server Availability Matrix (4K UHD vs 1080p + Direct Player Launch Action)               |
| 3. Lifetime Telemetry Stats Grid (Total Plays, Watch Time in Hours, 30D/7D counts)               |
| 4. Top Watchers Leaderboard (Ranked audience viewers)                                             |
| 5. Dedicated Playback History Feed (Historical sessions with transcode diagnostics)              |
+---------------------------------------------------------------------------------------------------+
| TV SHOW DETAIL                                                                                    |
| 1. Hero Backdrop + Identity + External Chips                                                      |
| 2. TV Hierarchy Accordion (Seasons & on-demand Episodes) <- PROMOTED TO TOP                       |
| 3. Cross-Server Availability Matrix (Fleet copies & versions)                                     |
| 4. Lifetime Stats & Top Watchers Leaderboard                                                      |
| 5. Dedicated Playback History Feed                                                                |
+---------------------------------------------------------------------------------------------------+
| SEASON DETAIL                                                                                     |
| 1. Hero Backdrop + Identity + Series Action Chip                                                  |
| 2. Direct Season Episode List (Flat episode list with interactive navigation rows)                |
| 3. Availability Matrix, Lifetime Stats, Top Watchers, & Dedicated History                         |
+---------------------------------------------------------------------------------------------------+
| EPISODE DETAIL                                                                                    |
| 1. Hero Backdrop + Identity + Sxx:Eyy + Series Action Chip (with origin context)                  |
| 2. Stream Availability Matrix (Direct player launcher)                                            |
| 3. Lifetime Stats & Episode Watchers                                                              |
| 4. Dedicated Playback History Feed -> [Opens Stream Transcode Diagnostics Sheet]                  |
+---------------------------------------------------------------------------------------------------+
```
