import type { PostVisibility } from '../api/client'
import './VisibilityPicker.css'

type VisibilityPickerProps = {
  value: PostVisibility
  onChange: (value: PostVisibility) => void
}

const OPTIONS: {
  value: PostVisibility
  icon: string
  title: string
  description: string
}[] = [
  {
    value: 'PUBLIC',
    icon: '🌐',
    title: 'Public',
    description: 'Shows on the nearby feed',
  },
  {
    value: 'FOLLOWERS_ONLY',
    icon: '👥',
    title: 'Followers only',
    description: 'Only people who follow you',
  },
]

export function VisibilityPicker({ value, onChange }: VisibilityPickerProps) {
  return (
    <div className="visibility-picker">
      <span className="visibility-picker-label">Who can see this post?</span>
      <div className="visibility-picker-options" role="radiogroup" aria-label="Post visibility">
        {OPTIONS.map((option) => {
          const selected = value === option.value
          return (
            <button
              key={option.value}
              type="button"
              role="radio"
              aria-checked={selected}
              className={`visibility-card ${selected ? 'selected' : ''}`}
              onClick={() => onChange(option.value)}
            >
              <span className="visibility-card-icon" aria-hidden>
                {option.icon}
              </span>
              <span className="visibility-card-copy">
                <strong>{option.title}</strong>
                <span>{option.description}</span>
              </span>
              <span className="visibility-card-check" aria-hidden>
                {selected ? '✓' : ''}
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
