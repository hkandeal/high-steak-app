import { postImageUrl } from '../api/client'
import { displayInitials } from '../utils/displayInitials'
import { CachedImage } from './CachedImage'
import './AuthorAvatar.css'

type AuthorAvatarProps = {
  displayName: string
  avatarUrl?: string | null
  avatarThumbnailUrl?: string | null
  size?: 'sm' | 'md'
}

export function AuthorAvatar({
  displayName,
  avatarUrl,
  avatarThumbnailUrl,
  size = 'sm',
}: AuthorAvatarProps) {
  const path = avatarThumbnailUrl ?? avatarUrl
  const src = path ? postImageUrl(path) : null

  return (
    <span className={`author-avatar author-avatar--${size}`} aria-hidden="true">
      {src ? <CachedImage src={src} alt="" /> : <span>{displayInitials(displayName)}</span>}
    </span>
  )
}
