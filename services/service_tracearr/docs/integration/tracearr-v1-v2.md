# Tracearr API v1 and v2

> [!WARNING]
> Do not "clean up" the remaining v1 calls by pointing them at v2. Six of them
> have no v2 equivalent. Removing them removes the feature.

Atrium talks to both API generations. `TracearrRemoteDataSource` holds a
`RawPublicAPIV2Api` (required) and a `RawPublicAPIApi` (optional, v1), and
picks per call. v2 is the default; v1 is used only where v2 has no answer.

## Which generation serves what

Derived from `TracearrRemoteDataSource`. If you change a call's generation,
change this table in the same commit.

| v1 only (no v2 equivalent) | Why v1 |
| :--- | :--- |
| `getHealth` | Per-server connectivity, server type and live stream counts. v2 has no health or connectivity endpoint. |
| `getStatsToday` | Rolling 24h play totals and watch hours. v2 exposes no fleet aggregate. |
| `getActivity` | 7-day trend buckets for the Overview histogram. |
| `getStats` | Aggregate fleet stats. |
| `getViolations` | Sentinel policy violation ledger. |
| `terminateStream` | The only write path in the module. |

Everything else is v2: `getStreams`, `getHistory`, `getRecentlyAdded`,
`getLibraries`, `getMediaHistory`, the media family (`getMediaByRef`,
`getMediaStatsByRef`, `getMediaWatchersByRef`, `getMediaChildrenByRef`) and the
user family (`getUsers`, `getUserById`, `getUserStatsById`,
`getUserHistoryById`).

Note that live streams and recently-added are **v2**, not v1. v2's
server-agnostic ids do not prevent artwork resolution, because posters are
built from the `thumb_path` those responses already carry.

## Auth

Both generations authenticate the same way and only this way:

```
Authorization: Bearer trr_pub_<token>
```

There is no `x-api-key` fallback. The header does not appear anywhere in
Tracearr's server, so sending one is inert. `core_networking`'s
`AuthInterceptor` sets the bearer for `ServiceKind.tracearr`; note that the
branch is shared with `ServiceKind.speedtestTracker`, so changes there affect
both services.

The image proxy (`v1/images/proxy`) is the exception: it is deliberately
unauthenticated upstream, so plain `<img>`-style loads work without headers.
Do not attach the token to poster URLs.

## Identifier bridging

`/api/v2/public/media/{ref}` accepts either a canonical Tracearr UUID or a
downstream server rating key, so items coming from feeds that carry only a
rating key can route straight into a v2 detail screen. See
[identifiers.md](identifiers.md).

## Rate limits

Two limiters apply, both per minute and both keyed on `${ip}:${token}` once the
bearer validates:

- a global limiter, default 1000/min
- a publicV2-specific limiter, default **240/min**, admin-configurable

240 is the one that matters. Opening Overview costs 5 requests, so fan-out on
open is the thing to watch. `core_networking`'s `RateLimitInterceptor` retries
a 429 using `Retry-After`.
