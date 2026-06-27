# Incident Report: Production API outage — Flyway V21 migration failure

| Field | Value |
|-------|-------|
| **Date** | 2026-06-27 |
| **Severity** | High (API unavailable during rollout; partial service during staggered deploy) |
| **Duration** | ~Several hours across two deploy attempts (api:24 → api:25); resolved after manual DB repair |
| **Affected service** | `high-steak-api` (production, `apps` namespace) |
| **Status** | Resolved |
| **Related** | Prior incident: V17 (`notification preferences`), 2026-06-20 — same root cause class |

---

## Summary

Deploying the geo-tagging feature (Flyway **V21 — geo places**) caused the new API pod to **crash-loop** on startup. Flyway recorded the migration as failed (`flyway_schema_history.success = 0`). Subsequent deploys — including a code hotfix — did not recover service until the failed history row was **manually deleted** from production MySQL and the pod was restarted.

This is the **second production outage** caused by the same class of Flyway/MySQL charset mismatch (first: **V17**, one week earlier). Documented rules and runbook guidance existed after V17 but were not followed when authoring or deploying V21.

---

## Impact

- **User-facing:** API returned errors for requests routed to the new crashing pod during rollout. An older API replica continued serving traffic briefly, masking full outage.
- **Features blocked:** Geo-tagging / places API (V21–V22) unavailable until migration succeeded.
- **Operational:** On-call time spent diagnosing, shipping hotfix PR #60, redeploying (api:25), and finally running manual prod DB cleanup.

---

## Timeline (UTC, approximate)

| Time | Event |
|------|-------|
| — | PR #59 (`feature/geo-tagging`) merged to `main` |
| — | **api:24** deployed; new API pod starts crash-looping |
| — | Logs: `FlywayValidateException: Detected failed migration to version 21 (geo places)` |
| — | Hotfix PR #60 merged — removes explicit `utf8mb4_0900_ai_ci` from V21 SQL |
| — | **api:25** deployed; pod **still** crash-loops (failed Flyway history row not cleared) |
| ~09:45 | Manual prod intervention: `DELETE FROM flyway_schema_history WHERE version = '21' AND success = 0` |
| ~09:46 | API pod restarted; Flyway applies V21 + V22 successfully; health check `UP` |

---

## Technical root cause

### 1. Migration failure (first deploy — api:24)

`V21__geo_places.sql` created the `places` table with:

```sql
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
```

Production MySQL uses `connectionCollation=utf8mb4_unicode_ci`. Legacy tables (`steak_posts`, `users`) retain older table-level charsets from the initial schema (V1). When V21 attempted:

```sql
ALTER TABLE steak_posts
    ADD CONSTRAINT fk_steak_posts_place
        FOREIGN KEY (place_id) REFERENCES places (id)
```

MySQL rejected the foreign key due to **charset/collation mismatch** between `places.id` and `steak_posts.place_id`. Flyway marked version 21 as `success = 0`.

### 2. Extended outage (second deploy — api:25)

The hotfix correctly removed the explicit charset override, but **deploying fixed code alone cannot recover** from a failed migration. Flyway validates `flyway_schema_history` **before** running migrations. With `version = 21, success = 0` present, startup fails immediately with the same validation error — without re-attempting the migration.

In this incident, there was **no partial schema** left in prod (no `places` table, no `place_id` column). Only the stale failed history row blocked recovery.

### 3. Why this happened again after V17

On **2026-06-20**, V17 (`user_notification_preferences`) failed in prod for the identical reason: explicit `utf8mb4_0900_ai_ci` on `CHAR(36)` FK columns. That incident produced:

- Commit `9d6eff1` — charset fix for V17/V18
- `docs/runbook.md` → **Production Flyway failures**
- `.cursor/rules/api-flyway.mdc` — FK charset guidance

V21 reintroduced the same anti-pattern (`utf8mb4_0900_ai_ci` on a new table with FK to legacy tables). ADR 012 even noted “Java migration if charset alignment needed (same pattern as V19/V20)” but V21 shipped as raw SQL with explicit collation.

---

## Detection

- Kubernetes: new `high-steak-api` pod in `CrashLoopBackOff`
- Application log:

  ```
  FlywayValidateException: Validate failed: Migrations have failed validation
  Detected failed migration to version 21 (geo places).
  Please remove any half-completed changes then run repair to fix the schema history.
  ```

- Health: `https://steaks.apps.hossam.io/api/health` intermittently OK while old replica still running

---

## Resolution

1. Connected to prod MySQL (`db-apps-mysql-deployment`, namespace `apps`)
2. Confirmed: `flyway_schema_history` had `version = 21, success = 0`; no partial objects
3. Ran: `DELETE FROM flyway_schema_history WHERE version = '21' AND success = 0`
4. Deleted / restarted crash-looping API pod
5. Flyway applied V21 and V22 on startup; `success = 1` for both
6. Health check confirmed: `{"status":"UP","service":"high-steak-api"}`

---

## What went well

- Old API replica kept partial service during staggered rollout
- Runbook and prior V17 documentation made diagnosis faster on the second attempt
- Hotfix branch workflow (`hotfix/flyway-v21-geo-places`) was used correctly for code fix
- Manual prod DB repair was surgical (single `DELETE` — no schema objects to drop)

---

## What went poorly

- **Repeat failure:** Same charset mistake as V17 one week earlier
- **Deploy without DB repair:** api:25 shipped assuming code fix alone would recover prod
- **No prod-like migration test:** Docker Compose and H2 tests did not catch MySQL FK charset mismatch
- **Blocking migrations at startup:** API cannot start until Flyway succeeds — failed migration = total pod failure
- **Environment drift:** Prod MySQL 5.6.x (per pod logs) vs local/docs assuming 8.x; legacy `latin1` / mixed collations not exercised in CI

---

## Action items

| Priority | Action | Owner | Status |
|----------|--------|-------|--------|
| P0 | Merge `hotfix/flyway-v21-java-migration` — convert V21 to Java migration matching `steak_posts.id` charset (V19/V20 pattern) | Eng | Open |
| P0 | Add **pre-deploy checklist** to release process: if any Flyway migration ships, verify prod `flyway_schema_history` has no `success = 0` rows before/after deploy | Eng/Ops | Open |
| P1 | Add CI job: run migrations against **MySQL 5.6/8 container with prod-like charset** (`latin1` legacy tables + `utf8mb4_unicode_ci` connection) — not only H2 | Eng | Open |
| P1 | Add Cursor rule / PR template checkbox: “New migration with `CHAR(36)` FK → Java migration or plain `CHAR(36)` only; no `utf8mb4_0900_ai_ci`” | Eng | Partial (rule exists; not enforced) |
| P1 | Document **mandatory recovery order** in runbook: (1) DB cleanup, (2) deploy — with explicit “deploy-only will NOT fix failed history row” callout | Eng | Done (2026-06-27 runbook update) |
| P2 | Consider running Flyway as a **Kubernetes init Job** before API rollout, so migration failure does not crash the serving pod | Eng/Ops | Open |
| P2 | Long-term: plan charset normalization migration for legacy tables (V16 widened text columns only; table defaults still mixed) | Eng | Open |
| P2 | Add staging environment that mirrors prod MySQL charset state for migration dry-runs | Ops | Open |

---

## Lessons learned

1. **Flyway failure is a database state problem, not just a code problem.** A failed row in `flyway_schema_history` blocks all future deploys until manually repaired or `flyway repair` is run.

2. **Local dev lies about prod.** Homogeneous Docker MySQL and H2 cannot validate FK charset alignment against a years-old schema with mixed collations.

3. **Documented incidents must change authoring habits.** After V17, the fix was documented but V21 repeated the mistake. Migrations touching `CHAR(36)` FKs should default to the **Java migration template** (V19/V20), not SQL, until legacy charset debt is resolved.

4. **Startup migrations amplify blast radius.** Any migration error becomes a hard outage. Separating schema migration from app serving reduces risk.

---

## References

- Runbook: `docs/runbook.md` → Production Flyway failures
- Rules: `.cursor/rules/api-flyway.mdc`
- ADR: `docs/decisions/012-geo-tagging-places-discovery.md`
- Hotfix PR #60: `hotfix/flyway-v21-geo-places`
- Prior fix: commit `9d6eff1` (V17 charset)
- Follow-up branch: `hotfix/flyway-v21-java-migration`

---

## Appendix: Recovery SQL (V21)

```sql
-- Inspect
SELECT version, description, success FROM flyway_schema_history WHERE version = '21';

-- If partial schema exists, drop FK / column / places table first (see runbook)

-- Required when migration failed with no partial objects:
DELETE FROM flyway_schema_history WHERE version = '21' AND success = 0;

-- Restart API pod, then verify:
SELECT version, success FROM flyway_schema_history WHERE version IN ('21', '22');
```
