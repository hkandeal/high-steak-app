import './AuthorFollowButton.css'

type AuthorFollowButtonProps = {
  subscribed: boolean
  authorDisplayName: string
  busy?: boolean
  onToggle: () => void
}

export function AuthorFollowButton({
  subscribed,
  authorDisplayName,
  busy = false,
  onToggle,
}: AuthorFollowButtonProps) {
  const label = busy
    ? 'Updating follow'
    : subscribed
      ? `Unfollow ${authorDisplayName}`
      : `Follow ${authorDisplayName}`

  return (
    <button
      type="button"
      className={`author-follow-button ${subscribed ? 'following' : ''}`}
      aria-pressed={subscribed}
      aria-label={label}
      disabled={busy}
      onClick={(event) => {
        event.preventDefault()
        event.stopPropagation()
        onToggle()
      }}
    >
      {busy ? '…' : subscribed ? 'Following' : 'Follow'}
    </button>
  )
}
