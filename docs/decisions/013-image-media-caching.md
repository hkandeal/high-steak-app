# ADR 013: Image and Media Caching (Phase 1)

## Status

Accepted — Phase 1 implemented

## Context

Post photos and avatars are served from `/api/uploads/**` as static files. Clients previously:

- Fetched **full-resolution** originals for feed cards, map pins, and thumbnails.
- Had **no explicit HTTP cache policy** on uploads (Spring `ResourceHandler` defaults).
- Mobile used plain `Image.network` with only Flutter’s small in-memory cache (no disk cache).
- Web relied on opportunistic browser caching without `Cache-Control` guidance.

Users reported slow repeat navigation: every screen load felt like images came from the server again.

Avatar feed thumbnails (64×64 JPEG, server-generated) already exist; **post images** do not have feed-sized variants yet.

## Decision

### Phase 1 (this ADR)

1. **Server — long-lived HTTP cache for uploads**  
   Set `Cache-Control: public, max-age=31536000, immutable` on `/uploads/**`.  
   Upload filenames are UUID-based and not overwritten in place, so aggressive caching is safe.

2. **Mobile — disk + memory image cache**  
   Use `cached_network_image` via a shared `CachedApiImage` widget:
   - Disk cache through `flutter_cache_manager` (package default).
   - `memCacheWidth` / `memCacheHeight` on list/feed surfaces to decode smaller bitmaps.
   - Full resolution retained for lightbox / detail where appropriate.

3. **Web — browser cache + lazy loading**  
   Use a shared `CachedImage` component (`loading="lazy"`, `decoding="async"`) for API-served media.  
   Effective caching comes from server `Cache-Control`; the component standardizes loading behavior.

### Phase 2 (future, not in scope)

- Server-generated **post image thumbnails** (feed vs detail URLs), similar to `AvatarThumbnailService`.
- CDN in front of `/uploads/**` in production.
- Optional client JSON cache (stale-while-revalidate) for feeds — separate from media.

## Consequences

### Positive

- Repeat views of the same image URL avoid network on mobile (disk) and web (HTTP cache).
- Smaller decode work on mobile feeds reduces jank and memory pressure.
- No API contract change; same `imageUrls` paths.

### Negative / limits

- Phase 1 still downloads **full-size** JPEGs on first load (bandwidth unchanged until Phase 2).
- Cache invalidation for a replaced file at the **same URL** would not occur (we avoid this by UUID filenames).
- Avatar thumbnail paths under `/uploads/thumbs/` also get immutable caching once generated.

## References

- `WebConfig.java` — upload resource handler cache policy
- `apps/high-steak-mobile/lib/widgets/cached_api_image.dart`
- `apps/high-steak-web/src/components/CachedImage.tsx`
- ADR 012 — geo / map (cover images on pins)
