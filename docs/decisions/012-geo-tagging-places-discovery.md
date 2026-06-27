# ADR 012: Geo-Tagged Posts and Location Discovery

## Status

Accepted

## Context

Posts already store optional free-text `restaurant_name` and `restaurant_location` on `steak_posts` (V6). There are no coordinates, no place identity, no spatial indexes, and no map or “near me” discovery UI.

The product goal is:

1. When creating a post, attach a **geo-tag** tied to a restaurant/venue (name + location).
2. Let users **search around them** for public steak reviews.
3. Present results with a **visual map** (pins/clusters + photo cards).

This ADR compares map/geocoding providers, defines the database schema, API surface, and client stack. Implementation is **not** started in this ADR.

## Provider comparison

### Summary matrix

| Criterion | Google Places | Mapbox Search + Maps | OpenStreetMap (OSM) |
|-----------|---------------|----------------------|---------------------|
| **Restaurant / POI quality** | Best globally, especially chains and Google Maps listings | Good in major cities; weaker in some regions | Variable; community-maintained |
| **Autocomplete UX** | Places Autocomplete (session tokens) | Search Box API / Geocoding v6 | Nominatim search (basic) |
| **Stable place ID** | `place_id` (industry standard) | `mapbox_id` | OSM `node`/`way` id (fragile across edits) |
| **Reverse geocode (tap map)** | Geocoding API / Places Nearby | Geocoding v6 reverse | Nominatim reverse |
| **Map rendering** | Google Maps JS / Maps SDK | Mapbox GL JS / Maps SDK | Leaflet / `flutter_map` + raster tiles |
| **Clustering / map UX** | Via `@googlemaps/markerclusterer` or deck.gl | Built-in GL clustering, strong styling | Leaflet.markercluster + tiles |
| **Pricing** | Pay per Places/Maps request; free credit then usage-based | Free tier + predictable MAU-style pricing | Software free; **hosting** and tile policy costs |
| **API key exposure** | Restrict by HTTP referrer (web) / bundle id (mobile) | Public token + URL restrictions | Self-host Nominatim or use commercial OSM provider |
| **Terms: storing coords** | Place ID + limited fields OK; **cannot** bulk cache full Places dump | More flexible attribution; check ToS for retention | ODbL — share-alike if you distribute OSM DB extracts |
| **Backend proxy needed** | **Yes** — hide keys, enforce session token billing | **Yes** — hide secret token | **Yes** if self-hosting Nominatim |
| **Offline / privacy** | Google-dependent | Mapbox-dependent | Can self-host more control |

### Google Places + Google Maps

**Use for:** autocomplete “CUT Steakhouse Dubai”, rich restaurant metadata, best mobile parity.

| Piece | Product | Typical use in High Steaks |
|-------|---------|----------------------------|
| Autocomplete | Places API (New) — Autocomplete | Post create: search venue |
| Details | Place Details | Resolve `place_id` → lat/lng, name, address |
| Map | Maps JavaScript API / Maps SDK for iOS/Android | Explore screen |
| Nearby | Places Nearby Search (optional) | “Restaurants around pin” |

**Pros:** Highest-quality restaurant data; familiar UX; works well in UAE/GCC.

**Cons:**

- Cost grows with autocomplete sessions + map loads.
- [Places API Policies](https://developers.google.com/maps/documentation/places/web-service/policies): store `place_id` and allowed fields; refresh stale details; attribution required.
- Requires Google Cloud billing account.

**Client packages:** `@react-google-maps/api` or Google Maps JS loader (web); `google_maps_flutter` (mobile).

**Env vars:**

```text
GOOGLE_MAPS_API_KEY_WEB=...        # HTTP referrer restricted
GOOGLE_MAPS_API_KEY_ANDROID=...    # package + SHA-1
GOOGLE_MAPS_API_KEY_IOS=...        # bundle id
GOOGLE_PLACES_API_KEY_SERVER=...   # IP restricted — server Place Details only
```

### Mapbox Search + Mapbox GL

**Use for:** single vendor for **search + map + tiles**, consistent styling, strong custom map design.

| Piece | Product | Typical use |
|-------|---------|-------------|
| Search | Search Box API / Geocoding v6 | Venue search + reverse geocode |
| Map | Mapbox GL JS / Maps SDK Flutter | Explore map, clusters |
| Tiles | Mapbox-hosted | Raster/vector tiles |

**Pros:** One bill, excellent map rendering, good developer experience, offline packs possible.

**Cons:**

- Restaurant POI coverage can trail Google in some markets.
- Still needs API key on clients (public token) with URL/bundle restrictions.
- `mapbox_id` is not portable if you switch providers later.

**Client packages:** `mapbox-gl` + `@mapbox/search-js-react` (web); `mapbox_maps_flutter` (mobile).

**Env vars:**

```text
MAPBOX_ACCESS_TOKEN_PUBLIC=...   # client maps + search (restricted)
MAPBOX_ACCESS_TOKEN_SECRET=...   # optional server geocoding only
```

### OpenStreetMap stack (Nominatim + OSM tiles)

**Use for:** minimal licensing cost, self-hosted control, acceptable if POI quality is “good enough” for your markets.

| Piece | Tool | Notes |
|-------|------|-------|
| Search / geocode | **Nominatim** (self-host or [commercial providers](https://nominatim.org/release-docs/latest/admin/Overview/)) | Public nominatim.openstreetmap.org is **not** for production |
| Map tiles | OSM tile servers / **MapTiler** / self-hosted | Heavy use violates OSM tile usage policy without own CDN |
| Map UI | Leaflet (web), `flutter_map` (mobile) | Lightweight |

**Pros:** No Google/Mapbox bill for data; open data; self-host path.

**Cons:**

- **Ops burden** — Nominatim + tile server is a real service to run.
- Weaker restaurant branding (“that steak place in DIFC”) vs Google.
- OSM IDs change when mappers split/merge venues — need re-link strategy.
- Attribution required on map.

**Client packages:** `leaflet` + `react-leaflet` (web); `flutter_map` + `latlong2` (mobile).

**Env vars (self-hosted):**

```text
NOMINATIM_BASE_URL=https://nominatim.internal.example
OSM_TILE_URL=https://tiles.example/{z}/{x}/{y}.png
```

### Recommendation for High Steaks

| Phase | Recommendation |
|-------|----------------|
| **MVP (quality + speed)** | **Google Places** (autocomplete + details) + **Google Maps** on web/mobile |
| **Cost / vendor diversification later** | Abstract `places.provider` in DB (schema below supports all three) |
| **Avoid for prod MVP** | Public Nominatim only — rate limits and ToS |

Use a **provider abstraction** in the API (`PlaceProvider` interface) so Mapbox or OSM can be added without schema migration.

---

## Data model decision

### Normalized `places` + optional FK on `steak_posts`

- One row per external venue (`provider` + `provider_place_id` unique).
- Multiple posts at the same restaurant share one `places` row.
- Keep existing `restaurant_name` / `restaurant_location` on `steak_posts` as **denormalized snapshot** at post time (display + fallback for legacy posts).
- Coordinates live on `places`; spatial index on `places.location` only.

### Visibility and privacy (query rules)

Public map / nearby APIs **must** filter:

```text
steak_posts.hidden = false
AND steak_posts.visibility = 'PUBLIC'
AND steak_posts.place_id IS NOT NULL
```

Do not expose `FOLLOWERS_ONLY` posts on public geo endpoints. Optional future: fuzz coordinates ±200 m for home-cook posts (`places.location_precision = 'APPROXIMATE'`).

---

## Exact database schema (Flyway V21)

MySQL **8.4** (current stack). UUIDs as `CHAR(36)` per ADR 007. Java migration if charset alignment needed (same pattern as V19/V20).

### `places` table

```sql
CREATE TABLE places (
    id                  CHAR(36)     NOT NULL,
    provider            VARCHAR(32)  NOT NULL,
    provider_place_id   VARCHAR(255) NOT NULL,
    name                VARCHAR(120) NOT NULL,
    formatted_address   VARCHAR(255) NULL,
    locality            VARCHAR(120) NULL,
    admin_area          VARCHAR(120) NULL,
    country_code        CHAR(2)      NULL,
    latitude            DECIMAL(9, 6) NOT NULL,
    longitude           DECIMAL(9, 6) NOT NULL,
    location            POINT        NOT NULL SRID 4326,
    location_precision  VARCHAR(16)  NOT NULL DEFAULT 'EXACT',
    created_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT uk_places_provider_place UNIQUE (provider, provider_place_id),
    CONSTRAINT chk_places_provider CHECK (provider IN ('google', 'mapbox', 'osm')),
    CONSTRAINT chk_places_precision CHECK (location_precision IN ('EXACT', 'APPROXIMATE')),
    CONSTRAINT chk_places_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_places_longitude CHECK (longitude BETWEEN -180 AND 180),
    SPATIAL INDEX idx_places_location (location),
    INDEX idx_places_name (name),
    INDEX idx_places_locality (locality)
);
```

**Column notes:**

| Column | Purpose |
|--------|---------|
| `provider` | `google` \| `mapbox` \| `osm` |
| `provider_place_id` | Opaque ID from that provider |
| `location` | MySQL `POINT` for `ST_Distance_Sphere` / bounding queries |
| `latitude` / `longitude` | Denormalized for JSON API without WKB parsing |
| `location_precision` | `EXACT` (restaurant pin) vs `APPROXIMATE` (privacy fuzz) |

**Point insert convention (API/service layer):**

```sql
ST_GeomFromText(CONCAT('POINT(', :longitude, ' ', :latitude, ')'), 4326)
```

MySQL `POINT` is **(X, Y) = (longitude, latitude)**.

### `steak_posts` changes

```sql
ALTER TABLE steak_posts
    ADD COLUMN place_id CHAR(36) NULL AFTER restaurant_location,
    ADD CONSTRAINT fk_steak_posts_place
        FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE SET NULL;

CREATE INDEX idx_steak_posts_place_created
    ON steak_posts (place_id, created_at DESC);
```

**Legacy posts:** `place_id` NULL — excluded from map until manually re-tagged or batch geocoded (out of scope for v1).

**Do not drop** `restaurant_name` / `restaurant_location` in v1 — UI can show snapshot if place row deleted.

### Optional v2: `place_stats` materialized view / table

For fast “12 reviews, avg 4.6” on map pins:

```sql
CREATE TABLE place_stats (
    place_id        CHAR(36)    NOT NULL PRIMARY KEY,
    post_count      INT         NOT NULL DEFAULT 0,
    avg_rating      DECIMAL(3,2) NULL,
    last_post_at    TIMESTAMP   NULL,
    CONSTRAINT fk_place_stats_place FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE CASCADE
);
```

Updated on post create/delete via application event or trigger — defer until map aggregate UI is built.

---

## API design

### Permissions (new scopes)

| Scope | Purpose |
|-------|---------|
| `places:read` | Nearby places/posts, place detail (all authenticated USER+) |
| `posts:write` | Already exists — extended multipart fields |

Add to USER/MODERATOR/ADMIN roles in Flyway (same pattern as V5 subscriptions).

### Endpoints

#### Place resolution (server proxies provider — keys never in untrusted clients for Details)

```http
GET /places/autocomplete?q={text}&lat={lat}&lng={lng}
```

Response:

```json
{
  "suggestions": [
    {
      "provider": "google",
      "providerPlaceId": "ChIJ...",
      "name": "CUT Dubai",
      "formattedAddress": "DIFC, Dubai",
      "latitude": 25.2100,
      "longitude": 55.2800
    }
  ]
}
```

Implementation: call provider autocomplete; return minimal fields only.

```http
POST /places/resolve
Content-Type: application/json

{
  "provider": "google",
  "providerPlaceId": "ChIJ..."
}
```

Response: `PlaceSummary` — upserts `places` row, returns `id` (UUID) for attaching to post.

#### Create / update post (extend existing multipart)

New optional fields:

```text
placeId          — UUID from POST /places/resolve (preferred)
```

If `placeId` set, server copies `name` / `formatted_address` into `restaurant_name` / `restaurant_location` snapshot.

Validation: `placeId` must exist; user cannot spoof coords without a resolved place row.

#### Discovery

```http
GET /places/nearby?lat=25.2048&lng=55.2708&radiusM=5000&page=0&size=20
```

Response page of `PlaceNearbySummary`:

```json
{
  "id": "uuid",
  "name": "CUT Dubai",
  "latitude": 25.2100,
  "longitude": 55.2800,
  "distanceM": 842,
  "postCount": 12,
  "avgRating": 4.5,
  "coverImageUrl": "/uploads/..."
}
```

```http
GET /places/{placeId}/posts?page=0&size=20
```

Public posts at that place (same visibility rules as profile posts).

```http
GET /posts/nearby?lat=&lng=&radiusM=&page=&size=
```

Flat post list sorted by distance (simpler than place aggregate; optional if `/places/nearby` exists).

### Core SQL: places within radius

```sql
SELECT
    p.id,
    p.name,
    p.latitude,
    p.longitude,
    ST_Distance_Sphere(
        p.location,
        ST_GeomFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)
    ) AS distance_m
FROM places p
WHERE ST_Distance_Sphere(
        p.location,
        ST_GeomFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)
      ) <= :radiusM
ORDER BY distance_m
LIMIT :limit OFFSET :offset;
```

### Core SQL: posts at nearby places (with aggregates)

```sql
SELECT
    pl.id AS place_id,
    pl.name,
    pl.latitude,
    pl.longitude,
    COUNT(sp.id) AS post_count,
    AVG(sp.rating) AS avg_rating,
    MIN(ST_Distance_Sphere(pl.location, ST_GeomFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326))) AS distance_m
FROM places pl
INNER JOIN steak_posts sp ON sp.place_id = pl.id
WHERE sp.hidden = false
  AND sp.visibility = 'PUBLIC'
  AND ST_Distance_Sphere(pl.location, ST_GeomFromText(CONCAT('POINT(', :lng, ' ', :lat, ')'), 4326)) <= :radiusM
GROUP BY pl.id, pl.name, pl.latitude, pl.longitude
ORDER BY distance_m
LIMIT :limit OFFSET :offset;
```

**Radius cap:** `radiusM` max 50_000 (50 km) server-side to prevent full table scan abuse.

**Bounding-box prefilter (performance at scale):**

```sql
AND pl.latitude BETWEEN :minLat AND :maxLat
AND pl.longitude BETWEEN :minLng AND :maxLng
```

Compute bbox from lat/lng + radius before spatial filter.

---

## Backend modules (Java)

| Class | Responsibility |
|-------|----------------|
| `Place` / `PlaceRepository` | JPA entity + spatial queries (native SQL or Hibernate Spatial) |
| `PlaceService` | Upsert by provider id, nearby search |
| `GooglePlaceClient` | Autocomplete + details (MVP) |
| `MapboxPlaceClient` | Optional adapter |
| `OsmNominatimClient` | Optional adapter |
| `PlaceController` | `/places/*` |
| `SteakPostService` | Accept `placeId` on create/update |

**Dependency note:** Hibernate 6 + `hibernate-spatial` optional; native queries avoid extra dependency for v1.

**Config (`application.yml`):**

```yaml
app:
  geo:
    default-radius-m: 5000
    max-radius-m: 50000
    place-provider: google   # google | mapbox | osm
  google:
    places-api-key: ${GOOGLE_PLACES_API_KEY:}
  mapbox:
    access-token: ${MAPBOX_ACCESS_TOKEN:}
  nominatim:
    base-url: ${NOMINATIM_BASE_URL:}
```

---

## Client stack

### Web (`high-steak-web`)

| Concern | Google (recommended MVP) | Mapbox | OSM |
|---------|--------------------------|--------|-----|
| Map page | `@react-google-maps/api` | `mapbox-gl` | `leaflet` + `react-leaflet` |
| Autocomplete | Places Autocomplete widget → session token → server resolve | Mapbox Search JS | Custom Nominatim typeahead via API proxy |
| User location | `navigator.geolocation` | same | same |
| New route | `/explore` (map + bottom sheet) | same | same |
| Post form | Extend `PostForm.tsx` — place picker component | same | same |

### Mobile (`high-steak-mobile`)

| Concern | Google | Mapbox | OSM |
|---------|--------|--------|-----|
| Map | `google_maps_flutter` | `mapbox_maps_flutter` | `flutter_map` |
| Autocomplete | `google_places_flutter` or server-only autocomplete | Mapbox Search SDK | API proxy only |
| Permissions | `geolocator` package | same | same |
| New screen | `ExploreScreen` + tab/shell entry | same | same |
| Post editor | Extend `post_editor_screen.dart` | same | same |

**Shared client flow:**

```text
1. User types restaurant → GET /places/autocomplete
2. User picks suggestion → POST /places/resolve → placeId
3. Submit post with placeId (+ existing images/title/rating)
4. Explore: device location → GET /places/nearby → map markers → tap → GET /places/{id}/posts
```

---

## JPA entity sketch (`Place.java`)

```java
@Entity
@Table(name = "places")
public class Place {
    @Id
    private UUID id;

    @Column(nullable = false, length = 32)
    private String provider;

    @Column(name = "provider_place_id", nullable = false)
    private String providerPlaceId;

    @Column(nullable = false, length = 120)
    private String name;

    // ... formattedAddress, locality, adminArea, countryCode

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal longitude;

    // location POINT mapped via @Formula or native insert only in v1
}
```

`SteakPost` addition:

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "place_id")
private Place place;
```

---

## OpenAPI additions (sketch)

```yaml
PlaceSummary:
  type: object
  required: [id, provider, name, latitude, longitude]
  properties:
    id: { type: string, format: uuid }
    provider: { type: string, enum: [google, mapbox, osm] }
    providerPlaceId: { type: string }
    name: { type: string }
    formattedAddress: { type: string, nullable: true }
    latitude: { type: number, format: double }
    longitude: { type: number, format: double }

PlaceNearbySummary:
  allOf:
    - $ref: '#/components/schemas/PlaceSummary'
    - type: object
      properties:
        distanceM: { type: integer }
        postCount: { type: integer }
        avgRating: { type: number, format: double, nullable: true }
        coverImageUrl: { type: string, nullable: true }
```

---

## Cost order-of-magnitude (monitor in prod)

| Provider | MVP traffic (low thousands MAU) | Risk |
|----------|----------------------------------|------|
| Google | Often within monthly credit; autocomplete sessions dominate | Bill spike if autocomplete not debounced |
| Mapbox | 25k+ free map loads/month tier | Search + maps both bill |
| OSM self-host | EC2 + Postgres for Nominatim + tile CDN | Engineer time >> API fees |

**Mitigation:** debounce autocomplete (300 ms), server-side caching of `places` rows (upsert = cache), max radius, pagination only.

---

## Implementation phases

| Phase | Deliverable |
|-------|-------------|
| **1** | V21 migration, `PlaceService`, `/places/resolve`, `placeId` on create post |
| **2** | `/places/nearby`, `/places/{id}/posts`, web place picker |
| **3** | Web `/explore` map + mobile explore screen |
| **4** | `place_stats` aggregates, filters (rating, tags) |
| **5** | Optional Mapbox/OSM provider adapters |

---

## Consequences

- New third-party dependency and secrets in Helm/K8s.
- Location data → privacy policy and App Store location purpose strings.
- Legacy posts without `place_id` invisible on map until re-tagged.
- Google provider lock-in reduced by `provider` + `provider_place_id` abstraction.
- MySQL spatial queries need integration tests with known coordinates.

## References

- `steak_posts.restaurant_name`, `restaurant_location` — V6
- `PostVisibility` — V9 (PUBLIC only on geo endpoints)
- **ADR 007** — UUID primary keys
- [Google Places API policies](https://developers.google.com/maps/documentation/places/web-service/policies)
- [Mapbox Search API](https://docs.mapbox.com/api/search/)
- [Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/)
- MySQL `ST_Distance_Sphere` — MySQL 8.4 ref manual
