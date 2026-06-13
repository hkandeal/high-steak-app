import type { ReviewTag } from '../api/client'
import './ReviewTagChips.css'

type ReviewTagChipsProps = {
  tags: ReviewTag[]
  compact?: boolean
}

export function ReviewTagChips({ tags, compact = false }: ReviewTagChipsProps) {
  if (tags.length === 0) return null

  return (
    <ul className={`review-tag-chips ${compact ? 'compact' : ''}`}>
      {tags.map((tag) => (
        <li
          key={tag.id}
          className={`review-tag-chip ${tag.sentiment === 'POSITIVE' ? 'positive' : 'negative'}`}
        >
          #{tag.label}
        </li>
      ))}
    </ul>
  )
}
