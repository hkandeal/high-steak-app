import { useEffect, useState } from 'react'
import { fetchReviewTags, type ReviewTag } from '../api/client'
import { useAuth } from '../context/AuthContext'
import './ReviewTagPicker.css'

type ReviewTagPickerProps = {
  selectedIds: string[]
  onChange: (ids: string[]) => void
}

export function ReviewTagPicker({ selectedIds, onChange }: ReviewTagPickerProps) {
  const { token } = useAuth()
  const [positive, setPositive] = useState<ReviewTag[]>([])
  const [negative, setNegative] = useState<ReviewTag[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return
    setLoading(true)
    setError(null)
    fetchReviewTags(token)
      .then((catalog) => {
        setPositive(catalog.positive)
        setNegative(catalog.negative)
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load tags'))
      .finally(() => setLoading(false))
  }, [token])

  function toggleTag(tagId: string) {
    if (selectedIds.includes(tagId)) {
      onChange(selectedIds.filter((id) => id !== tagId))
      return
    }
    if (selectedIds.length >= 12) return
    onChange([...selectedIds, tagId])
  }

  if (loading) {
    return <p className="muted review-tag-picker-loading">Loading quick tags…</p>
  }

  if (error) {
    return <p className="form-error">{error}</p>
  }

  return (
    <div className="review-tag-picker">
      <div className="review-tag-picker-header">
        <span className="field-label">Quick tags</span>
        <span className="review-tag-picker-hint">Tap what stood out — good or bad</span>
      </div>

      <section className="review-tag-group">
        <h3>What was great</h3>
        <div className="review-tag-options">
          {positive.map((tag) => (
            <button
              key={tag.id}
              type="button"
              className={`review-tag-option positive ${selectedIds.includes(tag.id) ? 'selected' : ''}`}
              onClick={() => toggleTag(tag.id)}
            >
              #{tag.label}
            </button>
          ))}
        </div>
      </section>

      <section className="review-tag-group">
        <h3>What missed</h3>
        <div className="review-tag-options">
          {negative.map((tag) => (
            <button
              key={tag.id}
              type="button"
              className={`review-tag-option negative ${selectedIds.includes(tag.id) ? 'selected' : ''}`}
              onClick={() => toggleTag(tag.id)}
            >
              #{tag.label}
            </button>
          ))}
        </div>
      </section>

      {selectedIds.length > 0 && (
        <p className="review-tag-picker-count">{selectedIds.length} tag{selectedIds.length === 1 ? '' : 's'} selected</p>
      )}
    </div>
  )
}
