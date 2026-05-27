import './StarRating.css'

type Props = {
  value: number
  onChange?: (value: number) => void
  readOnly?: boolean
}

export function StarRating({ value, onChange, readOnly }: Props) {
  return (
    <div className={`star-rating ${readOnly ? 'readonly' : ''}`} role="group" aria-label="Rating">
      {[1, 2, 3, 4, 5].map((star) => (
        <button
          key={star}
          type="button"
          className={star <= value ? 'star filled' : 'star'}
          disabled={readOnly}
          onClick={() => onChange?.(star)}
          aria-label={`${star} star${star > 1 ? 's' : ''}`}
        >
          ★
        </button>
      ))}
    </div>
  )
}
