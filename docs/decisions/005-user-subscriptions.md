# ADR 005: User Feed Subscriptions

## Status

Accepted

## Context

Users wanted a way to follow other steak posters and see a personalized feed without mutual approval or private accounts. The public Everyone feed (`GET /posts`) should remain unchanged.

## Decision

- One-way subscriptions (Twitter-style follow) stored in `user_subscriptions` (subscriber → target)
- All authenticated roles (USER, MODERATOR, ADMIN) receive `users:discover`, `subscriptions:read`, and `subscriptions:write` scopes
- Discovery search requires min 2 characters; results exclude the caller
- Cannot subscribe to yourself (400); duplicate subscribe returns 409
- Following feed (`GET /posts/following`) returns non-hidden posts from subscribed users, newest first; empty following list returns `[]`
- User profile posts preview (`GET /users/{id}/posts`) is public (non-hidden posts only)
- Web: **Everyone | Following** tabs on `/feed`; `/discover` page for search and follow/unfollow

## Consequences

- No notifications, pagination, blocking, or follow requests in v1
- Mobile app not updated in this iteration
- JWT must include new scopes after migration; users may need to re-login to pick up permissions

## References

- `V5__user_subscriptions.sql`
- `SubscriptionService`, `UserDiscoveryService`
- `SubscriptionController`, `UserDiscoveryController`
- `apps/high-steak-web/src/pages/FeedPage.tsx`, `DiscoverPage.tsx`
