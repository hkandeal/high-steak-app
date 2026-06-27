import { useFeedLayout } from '../context/FeedLayoutContext'
import './FeedLayoutToggle.css'

type FeedLayoutToggleProps = {
  variant?: 'header' | 'compact'
}

export function FeedLayoutToggle({ variant = 'header' }: FeedLayoutToggleProps) {
  const { layout, setLayout } = useFeedLayout()

  return (
    <div
      className={`feed-layout-toggle feed-layout-toggle-${variant}`}
      role="group"
      aria-label="Feed layout"
    >
      <button
        type="button"
        className={`feed-layout-toggle-option ${layout === 'grid' ? 'active' : ''}`}
        aria-pressed={layout === 'grid'}
        aria-label="Grid view"
        title="Grid view"
        onClick={() => setLayout('grid')}
      >
        <span className="feed-layout-toggle-icon" aria-hidden="true">
          ⊞
        </span>
        <span className="feed-layout-toggle-label">Grid</span>
      </button>
      <button
        type="button"
        className={`feed-layout-toggle-option ${layout === 'list' ? 'active' : ''}`}
        aria-pressed={layout === 'list'}
        aria-label="List view"
        title="List view"
        onClick={() => setLayout('list')}
      >
        <span className="feed-layout-toggle-icon" aria-hidden="true">
          ☰
        </span>
        <span className="feed-layout-toggle-label">List</span>
      </button>
    </div>
  )
}
