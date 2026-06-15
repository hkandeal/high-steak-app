const HIDDEN_STORAGE_PREFIX = 'high-steak-moderation-seen'
const RESTORED_STORAGE_PREFIX = 'high-steak-moderation-restored-seen'

function hiddenStorageKey(userId: string) {
  return `${HIDDEN_STORAGE_PREFIX}:${userId}`
}

function restoredStorageKey(userId: string) {
  return `${RESTORED_STORAGE_PREFIX}:${userId}`
}

export function restoredNoticeKey(postId: string, restoredAt: string) {
  return `${postId}:${restoredAt}`
}

export function getSeenModerationPostIds(userId: string): Set<string> {
  try {
    const raw = localStorage.getItem(hiddenStorageKey(userId))
    if (!raw) return new Set()
    const parsed = JSON.parse(raw) as string[]
    return new Set(parsed)
  } catch {
    return new Set()
  }
}

export function getSeenRestoredNoticeKeys(userId: string): Set<string> {
  try {
    const raw = localStorage.getItem(restoredStorageKey(userId))
    if (!raw) return new Set()
    const parsed = JSON.parse(raw) as string[]
    return new Set(parsed)
  } catch {
    return new Set()
  }
}

export function markModerationPostsSeen(userId: string, postIds: string[]) {
  const seen = getSeenModerationPostIds(userId)
  for (const id of postIds) seen.add(id)
  localStorage.setItem(hiddenStorageKey(userId), JSON.stringify([...seen]))
}

export function markRestoredNoticesSeen(
  userId: string,
  notices: Array<{ id: string; moderationRestoredAt: string }>,
) {
  const seen = getSeenRestoredNoticeKeys(userId)
  for (const notice of notices) {
    seen.add(restoredNoticeKey(notice.id, notice.moderationRestoredAt))
  }
  localStorage.setItem(restoredStorageKey(userId), JSON.stringify([...seen]))
}

export function isRestoredNoticeUnseen(
  userId: string,
  postId: string,
  restoredAt: string,
): boolean {
  return !getSeenRestoredNoticeKeys(userId).has(restoredNoticeKey(postId, restoredAt))
}

export function countUnseenModerationPosts(userId: string, hiddenPostIds: string[]): number {
  const seen = getSeenModerationPostIds(userId)
  return hiddenPostIds.filter((id) => !seen.has(id)).length
}

export function countUnseenRestoredPosts(
  userId: string,
  posts: Array<{ id: string; moderationRestoredAt?: string | null }>,
): number {
  return posts.filter(
    (post) =>
      post.moderationRestoredAt &&
      isRestoredNoticeUnseen(userId, post.id, post.moderationRestoredAt),
  ).length
}
