CREATE TABLE review_tags (
    id CHAR(36) NOT NULL PRIMARY KEY,
    slug VARCHAR(64) NOT NULL UNIQUE,
    label VARCHAR(120) NOT NULL,
    sentiment VARCHAR(16) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE post_review_tags (
    post_id CHAR(36) NOT NULL,
    tag_id CHAR(36) NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    CONSTRAINT fk_post_review_tags_post FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE,
    CONSTRAINT fk_post_review_tags_tag FOREIGN KEY (tag_id) REFERENCES review_tags (id)
);

CREATE INDEX idx_post_review_tags_tag ON post_review_tags (tag_id);

INSERT INTO review_tags (id, slug, label, sentiment, sort_order) VALUES
('a1000001-0000-4000-8000-000000000001', 'excellent-portion', 'ExcellentPortion', 'POSITIVE', 1),
('a1000001-0000-4000-8000-000000000002', 'steak-lovers', 'SteakLovers', 'POSITIVE', 2),
('a1000001-0000-4000-8000-000000000003', 'well-seasoned', 'WellSeasoned', 'POSITIVE', 3),
('a1000001-0000-4000-8000-000000000004', 'perfectly-cooked', 'PerfectlyCooked', 'POSITIVE', 4),
('a1000001-0000-4000-8000-000000000005', 'tender', 'Tender', 'POSITIVE', 5),
('a1000001-0000-4000-8000-000000000006', 'juicy', 'Juicy', 'POSITIVE', 6),
('a1000001-0000-4000-8000-000000000007', 'flavorful', 'Flavorful', 'POSITIVE', 7),
('a1000001-0000-4000-8000-000000000008', 'melt-in-your-mouth', 'MeltInYourMouth', 'POSITIVE', 8),
('a1000001-0000-4000-8000-000000000009', 'premium-quality', 'PremiumQuality', 'POSITIVE', 9),
('a1000001-0000-4000-8000-000000000010', 'great-presentation', 'GreatPresentation', 'POSITIVE', 10),
('a1000001-0000-4000-8000-000000000011', 'fresh-ingredients', 'FreshIngredients', 'POSITIVE', 11),
('a1000001-0000-4000-8000-000000000012', 'worth-the-price', 'WorthThePrice', 'POSITIVE', 12),
('a2000001-0000-4000-8000-000000000001', 'overcooked', 'Overcooked', 'NEGATIVE', 1),
('a2000001-0000-4000-8000-000000000002', 'undercooked', 'Undercooked', 'NEGATIVE', 2),
('a2000001-0000-4000-8000-000000000003', 'tough', 'Tough', 'NEGATIVE', 3),
('a2000001-0000-4000-8000-000000000004', 'dry', 'Dry', 'NEGATIVE', 4),
('a2000001-0000-4000-8000-000000000005', 'bland', 'Bland', 'NEGATIVE', 5),
('a2000001-0000-4000-8000-000000000006', 'too-salty', 'TooSalty', 'NEGATIVE', 6),
('a2000001-0000-4000-8000-000000000007', 'poor-seasoning', 'PoorSeasoning', 'NEGATIVE', 7),
('a2000001-0000-4000-8000-000000000008', 'chewy', 'Chewy', 'NEGATIVE', 8),
('a2000001-0000-4000-8000-000000000009', 'cold-food', 'ColdFood', 'NEGATIVE', 9),
('a2000001-0000-4000-8000-000000000010', 'small-portion', 'SmallPortion', 'NEGATIVE', 10),
('a2000001-0000-4000-8000-000000000011', 'overpriced', 'Overpriced', 'NEGATIVE', 11),
('a2000001-0000-4000-8000-000000000012', 'poor-value', 'PoorValue', 'NEGATIVE', 12),
('a2000001-0000-4000-8000-000000000013', 'slow-service', 'SlowService', 'NEGATIVE', 13),
('a2000001-0000-4000-8000-000000000014', 'poor-service', 'PoorService', 'NEGATIVE', 14);
