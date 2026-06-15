import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchAllMyPosts, type SteakPost } from '../api/client'
import {
  countUnseenModerationPosts,
  countUnseenRestoredPosts,
  getSeenModerationPostIds,
  isRestoredNoticeUnseen,
} from '../utils/moderationNotices'

export type ModerationNotice =
  | { kind: 'hidden'; post: SteakPost }
  | { kind: 'restored'; post: SteakPost }

function noticeTimestamp(notice: ModerationNotice): number {
  if (notice.kind === 'restored' && notice.post.moderationRestoredAt) {
    return new Date(notice.post.moderationRestoredAt).getTime()
  }
  return new Date(notice.post.createdAt).getTime()
}

export function useModerationNotices(token: string | null, userId: string | undefined) {
  const [hiddenPosts, setHiddenPosts] = useState<SteakPost[]>([])
  const [restoredPosts, setRestoredPosts] = useState<SteakPost[]>([])
  const [loading, setLoading] = useState(false)

  const reload = useCallback(async () => {
    if (!token || !userId) {
      setHiddenPosts([])
      setRestoredPosts([])
      return
    }
    setLoading(true)
    try {
      const posts = await fetchAllMyPosts(token)
      setHiddenPosts(posts.filter((post) => post.hidden))
      setRestoredPosts(
        posts.filter((post) => !post.hidden && post.moderationRestoredAt),
      )
    } catch {
      setHiddenPosts([])
      setRestoredPosts([])
    } finally {
      setLoading(false)
    }
  }, [token, userId])

  useEffect(() => {
    void reload()
  }, [reload])

  const allNotices = useMemo<ModerationNotice[]>(() => {
    const notices: ModerationNotice[] = [
      ...hiddenPosts.map((post) => ({ kind: 'hidden' as const, post })),
      ...restoredPosts.map((post) => ({ kind: 'restored' as const, post })),
    ]
    return notices.sort((a, b) => noticeTimestamp(b) - noticeTimestamp(a))
  }, [hiddenPosts, restoredPosts])

  const unseenNotices = useMemo(() => {
    if (!userId) return []
    const seenHidden = getSeenModerationPostIds(userId)
    return allNotices.filter((notice) => {
      if (notice.kind === 'hidden') {
        return !seenHidden.has(notice.post.id)
      }
      return (
        notice.post.moderationRestoredAt != null &&
        isRestoredNoticeUnseen(userId, notice.post.id, notice.post.moderationRestoredAt)
      )
    })
  }, [allNotices, userId, hiddenPosts, restoredPosts])

  const unreadCount =
    userId == null
      ? 0
      : countUnseenModerationPosts(
          userId,
          hiddenPosts.map((post) => post.id),
        ) + countUnseenRestoredPosts(userId, restoredPosts)

  return {
    hiddenPosts,
    restoredPosts,
    allNotices,
    unseenNotices,
    unreadCount,
    loading,
    reload,
  }
}
