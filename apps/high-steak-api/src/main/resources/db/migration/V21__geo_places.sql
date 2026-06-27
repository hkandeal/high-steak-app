CREATE TABLE places (
    id                  CHAR(36)      NOT NULL,
    provider            VARCHAR(32)   NOT NULL,
    provider_place_id   VARCHAR(255)  NOT NULL,
    name                VARCHAR(120)  NOT NULL,
    formatted_address   VARCHAR(255)  NULL,
    locality            VARCHAR(120)  NULL,
    admin_area          VARCHAR(120)  NULL,
    country_code        VARCHAR(2)    NULL,
    latitude            DECIMAL(9, 6) NOT NULL,
    longitude           DECIMAL(9, 6) NOT NULL,
    location_precision  VARCHAR(16)   NOT NULL DEFAULT 'EXACT',
    created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT uk_places_provider_place UNIQUE (provider, provider_place_id),
    CONSTRAINT chk_places_provider CHECK (provider IN ('google', 'mapbox', 'osm', 'manual')),
    CONSTRAINT chk_places_precision CHECK (location_precision IN ('EXACT', 'APPROXIMATE'))
);

CREATE INDEX idx_places_lat_lng ON places (latitude, longitude);
CREATE INDEX idx_places_name ON places (name);

ALTER TABLE steak_posts
    ADD COLUMN place_id CHAR(36) NULL;

ALTER TABLE steak_posts
    ADD CONSTRAINT fk_steak_posts_place
        FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE SET NULL;

CREATE INDEX idx_steak_posts_place_created ON steak_posts (place_id, created_at DESC);

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('places', 'read', NULL, 'places:read');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('USER', 'MODERATOR', 'ADMIN')
  AND p.scope = 'places:read';
