import { Link } from 'react-router-dom'
import { useModerationNoticesContext, type ModerationNotice } from '../context/ModerationNoticesContext'
import { useAuth } from '../context/AuthContext'
import { markModerationPostsSeen, markRestoredNoticesSeen } from '../utils/moderationNotices'
import { listItemBackState } from '../navigation'
import './NotificationsPage.css'

function markNoticeSeen(userId: string, notice: ModerationNotice) {
  if (notice.kind === 'hidden') {
    markModerationPostsSeen(userId, [notice.post.id])
    return
  }
  if (notice.post.moderationRestoredAt) {
    markRestoredNoticesSeen(userId, [
      { id: notice.post.id, moderationRestoredAt: notice.post.moderationRestoredAt },
    ])
  }
}

export function NotificationsPage() {
  const { user, token } = useAuth()
  const { allNotices, unreadCount, loading, reload } = useModerationNoticesContext()

  function markAllRead() {
    if (!user) return
    markModerationPostsSeen(
      user.id,
      allNotices.filter((notice) => notice.kind === 'hidden').map((notice) => notice.post.id),
    )
    markRestoredNoticesSeen(
      user.id,
      allNotices
        .filter((notice) => notice.kind === 'restored' && notice.post.moderationRestoredAt)
        .map((notice) => ({
          id: notice.post.id,
          moderationRestoredAt: notice.post.moderationRestoredAt!,
        })),
    )
    void reload()
  }

  if (!token || !user) return null

  return (
    <section className="notifications-page">
      <header className="notifications-header">
        <div>
          <h1>Notifications</h1>
          <p className="muted">Updates when moderators hide or restore your posts.</p>
        </div>
        {unreadCount > 0 && (
          <button type="button" className="btn ghost small" onClick={markAllRead}>
            Mark all read
          </button>
        )}
      </header>

      {loading && <p className="muted">Loading…</p>}

      {!loading && allNotices.length === 0 && (
        <div className="empty-feed">
          <p>No moderation notices right now.</p>
        </div>
      )}

      <ul className="notifications-list">
        {allNotices.map((notice) => (
          <li
            key={`${notice.kind}-${notice.post.id}-${notice.post.moderationRestoredAt ?? 'hidden'}`}
            className={`notification-item ${notice.kind === 'restored' ? 'notification-item--restored' : ''}`}
          >
            <div className="notification-item-body">
              <p className="notification-item-title">
                {notice.kind === 'hidden'
                  ? 'Post removed from feeds'
                  : 'Post restored to feeds'}
              </p>
              <p>
                <strong>{notice.post.title}</strong>
                {notice.kind === 'hidden'
                  ? ' is hidden from public feeds.'
                  : ' is visible in public feeds again.'}
              </p>
              {notice.kind === 'hidden' && notice.post.moderationReason && (
                <p className="notification-item-reason">
                  <span>Reason:</span> {notice.post.moderationReason}
                </p>
              )}
              <time className="notification-item-time">
                {notice.kind === 'restored' && notice.post.moderationRestoredAt
                  ? new Date(notice.post.moderationRestoredAt).toLocaleString()
                  : new Date(notice.post.createdAt).toLocaleString()}
              </time>
            </div>
            <Link
              to={`/posts/${notice.post.id}`}
              state={listItemBackState('/notifications', 'Back to notifications')}
              className="btn ghost small"
              onClick={() => markNoticeSeen(user.id, notice)}
            >
              View post
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}
