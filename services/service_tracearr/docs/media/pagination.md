# Media Pagination & Infinite Scrolling (`service_tracearr/docs/media`)

This document describes the cursor-based pagination mechanism and `EasyRefresh` integration in the Media Tab.

---

## 1. Pagination Architecture

```mermaid
graph TD
    UserScroll[User Scrolls Down ListView] -->|Triggers onLoad| EasyRefresh[EasyRefresh Widget]
    EasyRefresh -->|Calls loadMore()| Notifier[TracearrRecentPaginatedNotifier]
    Notifier -->|Checks isLoadingMore / hasMore| Guard{Lock Available?}
    Guard -->|No / Locked| Ignore[No-op / Ignore]
    Guard -->|Yes| Fetch[Repository.getRecentlyAddedPage(cursor, libraryId)]
    Fetch -->|GET /api/v1/media/recent| API[Tracearr Backend]
    API -->> Fetch: TracearrRecentlyAddedPage(items, nextCursor)
    Fetch -->> Notifier: Deduplicate items & update state
    Notifier -->> EasyRefresh: Finish load (Success / NoMore)
```

---

## 2. Invariants & Protections

1. **Strict Concurrency Guard**:
   ```dart
   if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) return;
   ```
2. **Deduplication**:
   When appending a new page, incoming items are filtered against existing loaded IDs to prevent duplicate tiles when database insertions happen concurrently on the backend:
   ```dart
   final existingIds = state.items.map((i) => i.id).toSet();
   final uniqueNewItems = page.items.where((i) => !existingIds.contains(i.id)).toList();
   ```
3. **Cursor Termination**: If `page.nextCursor == null`, `hasMore` is set to `false`, signaling `EasyRefresh` that all pages have been fetched.
4. **Error Recovery**: Network or API errors during `loadMore()` reset `isLoadingMore: false` without purging already-loaded items from the user's view.
