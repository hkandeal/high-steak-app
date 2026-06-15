import { useId, useState } from 'react'
import './AuthorPostModerationNotice.css'

type AuthorPostModerationNoticeProps = {
  reason?: string | null
  variant?: 'card' | 'banner'
}

export function AuthorPostModerationNotice({
  reason,
  variant = 'card',
}: AuthorPostModerationNoticeProps) {
  const [expanded, setExpanded] = useState(false)
  const detailsId = useId()

  return (
    <div
      className={`author-moderation-notice author-moderation-notice--${variant} ${expanded ? 'expanded' : ''}`}
    >
      <button
        type="button"
        className="author-moderation-notice-toggle"
        aria-expanded={expanded}
        aria-controls={detailsId}
        onClick={() => setExpanded((current) => !current)}
      >
        <span className="author-moderation-notice-icon" aria-hidden="true">
          ⚠
        </span>
        <span className="author-moderation-notice-summary">
          <span className="author-moderation-notice-title">Removed from public feeds</span>
          {!expanded && reason && (
            <span className="author-moderation-notice-hint">Moderator left a note</span>
          )}
        </span>
        <span className="author-moderation-notice-chevron" aria-hidden="true">
          {expanded ? '▾' : '▸'}
        </span>
      </button>

      {expanded && (
        <div id={detailsId} className="author-moderation-notice-details">
          <p className="author-moderation-notice-text">
            A moderator hid this post. Other members cannot see it in feeds or on your public
            profile. Only you and moderators can still open it.
          </p>
          {reason ? (
            <div className="author-moderation-notice-reason">
              <span className="author-moderation-notice-reason-label">Moderator note</span>
              <p>{reason}</p>
            </div>
          ) : (
            <p className="author-moderation-notice-no-reason">No reason was provided.</p>
          )}
        </div>
      )}
    </div>
  )
}
