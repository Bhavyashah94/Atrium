# Overview & Fleet Pulse Subsystem (`service_tracearr/docs/overview`)

This document describes the fleet health monitoring, 24-hour summary tiles, and activity trend histogram.

---

## 1. Overview Tab Architecture

```
lib/src/overview/
├── overview_tab.dart                 - Multi-provider dashboard layout.
└── widgets/
    ├── activity_trend_chart.dart     - 7-day bar chart / histogram with daily buckets.
    ├── fleet_summary_card.dart       - Health badge, connected servers, and version string.
    ├── live_stream_status_card.dart  - Direct play vs. hardware transcode breakout tiles.
    └── today_metrics_bar.dart        - 24h metrics (Plays, Watch Hours, Security Incidents).
```

---

## 2. Multi-Provider Aggregation

`OverviewTab` combines multiple providers without blocking the UI:
- **Fleet Health Banner**: Watches `tracearrHealthProvider`.
- **Live Stream Distribution**: Watches `tracearrActiveStreamsProvider`, deriving real-time counts for Direct Play, Direct Stream, HW Transcode, and SW Transcode.
- **24-Hour Pulse**: Watches `tracearrStatsTodayComputedProvider` for aggregated fleet plays and watch hours.
- **7-Day Trend Histogram**: Watches `tracearrActivityTrendsProvider` for historical daily volume.

---

## 3. Resilience & Failure Isolation

Each section on `OverviewTab` handles error states locally. If the 7-day trend API returns a 500 error, the rest of the dashboard (fleet health, active stream counts, 24h summary tiles) continues to function seamlessly.
