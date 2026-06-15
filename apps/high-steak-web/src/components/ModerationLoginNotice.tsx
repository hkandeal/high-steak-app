import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useModerationNoticesContext } from '../context/ModerationNoticesContext'
import { useAuth } from '../context/AuthContext'
import {
  markModerationPostsSeen,
  markRestoredNoticesSeen,
} from '../utils/moderationNotices'
import type { ModerationNotice } from '../hooks/useModerationNotices'
import './ConfirmDialog.css'
import './ModerationLoginNotice.css'

function markNoticesSeen(userId: string, notices: ModerationNotice[]) {
  markModerationPostsSeen(
    userId,
    notices.filter((notice) => notice.kind === 'hidden').map((notice) => notice.post.id),
  )
  markRestoredNoticesSeen(
    userId,
    notices
      .filter((notice) => notice.kind === 'restored' && notice.post.moderationRestoredAt)
      .map((notice) => ({
        id: notice.post.id,
        moderationRestoredAt: notice.post.moderationRestoredAt!,
      })),
  )
}

export function ModerationLoginNotice() {
  const { user } = useAuth()
  const { unseenNotices, loading, reload } = useModerationNoticesContext()
  const [open, setOpen] = useState(false)
  const [dismissed, setDismissed] = useState(false)

  useEffect(() => {
    if (!loading && !dismissed && unseenNotices.length > 0) {
      setOpen(true)
    }
  }, [loading, unseenNotices.length, dismissed])

  function handleDismiss() {
    if (!user) return
    markNoticesSeen(user.id, unseenNotices)
    setDismissed(true)
    setOpen(false)
    void reload()
  }

  if (!open || unseenNotices.length === 0) return null

  const hiddenCount = unseenNotices.filter((notice) => notice.kind === 'hidden').length
  const restoredCount = unseenNotices.filter((notice) => notice.kind === 'restored').length

  let summary = 'You have moderation updates on your posts.'
  if (hiddenCount > 0 && restoredCount === 0) {
    summary =
      hiddenCount === 1
        ? 'One of your posts was removed from public feeds.'
        : `${hiddenCount} of your posts were removed from public feeds.`
  } else if (restoredCount > 0 && hiddenCount === 0) {
    summary =
      restoredCount === 1
        ? 'One of your posts was restored to public feeds.'
        : `${restoredCount} of your posts were restored to public feeds.`
  } else {
    summary = `${hiddenCount} hidden and ${restoredCount} restored post updates.`
  }

  return (
    <div className="confirm-dialog-backdrop">
      <div className="confirm-dialog moderation-login-notice" role="alertdialog" aria-modal="true">
        <h2>Moderation updates</h2>
        <p>{summary}</p>
        <ul className="moderation-login-notice-list">
          {unseenNotices.map((notice) => (
            <li
              key={`${notice.kind}-${notice.post.id}-${notice.post.moderationRestoredAt ?? 'hidden'}`}
              className={notice.kind === 'restored' ? 'moderation-login-notice-item--restored' : ''}
            >
              <strong>{notice.post.title}</strong>
              <span className="moderation-login-notice-kind">
                {notice.kind === 'hidden' ? 'Removed from feeds' : 'Restored to feeds'}
              </span>
              {notice.kind === 'hidden' && notice.post.moderationReason && (
                <span className="moderation-login-notice-reason">{notice.post.moderationReason}</span>
              )}
            </li>
          ))}
        </ul>
        <div className="confirm-dialog-actions">
          <Link to="/notifications" className="btn ghost" onClick={handleDismiss}>
            View all
          </Link>
          <button type="button" className="btn primary" onClick={handleDismiss}>
            Got it
          </button>
        </div>
      </div>
    </div>
  )
}
