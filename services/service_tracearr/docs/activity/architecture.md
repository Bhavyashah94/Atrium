# Activity & Telemetry Subsystem (`service_tracearr/docs/activity`)

This document details the real-time active streaming, playback history, and transcode diagnostics architecture.

---

## 1. Component Overview

```
lib/src/activity/
├── activity_tab.dart                          - Feed toggle between Active Streams & Playback History.
└── widgets/
    ├── active_stream_card.dart                - Live stream card with progress, transcode pill, & user.
    ├── history_item_card.dart                 - Historical watch session row with duration & transcode.
    ├── stream_diagnostics_sheet.dart          - Live transcode diagnostics bottom sheet.
    └── history_session_diagnostics_sheet.dart - Historical playback session transcode sheet.
```

---

## 2. Live Streams vs. Historical Sessions

| Metric / Dimension | Active Streams (`ActiveStreamCard`) | Historical Sessions (`HistoryItemCard`) |
| :--- | :--- | :--- |
| **API Source** | `GET /api/v1/activity` (`tracearrActiveStreamsProvider`) | `GET /api/v2/public/history` (`tracearrHistoryProvider`) |
| **Lifecycle** | Ephemeral, polled / refreshed in real-time. | Immutable append-only audit log. |
| **Transcode Diagnostics** | Live bitrates, frame rates, hardware transcode decisions. | Historical completion %, codecs, and transcode mode. |
| **Navigation** | Tapping title/poster $\rightarrow$ `TracearrMediaDetailScreen`. | Tapping card $\rightarrow$ `HistorySessionDiagnosticsSheet`. Tapping avatar $\rightarrow$ `TracearrUserDossierScreen`. |

---

## 3. Stream Diagnostics & Hardware Acceleration

`StreamDiagnosticsSheet` and `HistorySessionDiagnosticsSheet` extract granular telemetry:
- **Decision**: `Direct Play` vs. `Direct Stream` vs. `Transcode`.
- **Video Stream**: Container (MKV/MP4), Resolution (4K $\rightarrow$ 1080p), Codec (HEVC $\rightarrow$ H.264), Dynamic Range (HDR10/Dolby Vision).
- **Audio Stream**: Channels (7.1 $\rightarrow$ 2.0), Codec (TrueHD $\rightarrow$ AAC).
- **HW Acceleration**: Indicates Intel QuickSync (QSV), NVIDIA NVENC, or Apple VideoToolbox.
- **Client & Player**: Player name, device model, operating system, and IP address.
