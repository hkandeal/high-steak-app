import './PostBookmarkButton.css'

type PostBookmarkButtonProps = {
  bookmarked: boolean
  busy?: boolean
  postTitle: string
  onToggle: () => void
}

export function PostBookmarkButton({
  bookmarked,
  busy = false,
  postTitle,
  onToggle,
}: PostBookmarkButtonProps) {
  const label = busy
    ? 'Saving bookmark'
    : bookmarked
      ? `Remove bookmark for ${postTitle}`
      : `Bookmark ${postTitle}`

  return (
    <button
      type="button"
      className={`post-bookmark-button ${bookmarked ? 'active' : ''}`}
      aria-pressed={bookmarked}
      aria-label={label}
      disabled={busy}
      onClick={(event) => {
        event.stopPropagation()
        onToggle()
      }}
    >
      <svg viewBox="0 0 24 24" aria-hidden="true" className="post-bookmark-icon">
        <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
      </svg>
    </button>
  )
}
