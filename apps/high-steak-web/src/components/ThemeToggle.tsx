import { useTheme } from '../context/ThemeContext'
import './ThemeToggle.css'

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()

  return (
    <div className="theme-toggle" role="group" aria-label="Color theme">
      <button
        type="button"
        className={`theme-toggle-option ${theme === 'ember' ? 'active' : ''}`}
        aria-pressed={theme === 'ember'}
        onClick={() => setTheme('ember')}
      >
        <span className="theme-toggle-icon" aria-hidden="true">
          🔥
        </span>
        <span className="theme-toggle-label">Ember</span>
      </button>
      <button
        type="button"
        className={`theme-toggle-option ${theme === 'steam' ? 'active' : ''}`}
        aria-pressed={theme === 'steam'}
        onClick={() => setTheme('steam')}
      >
        <span className="theme-toggle-icon" aria-hidden="true">
          ♨
        </span>
        <span className="theme-toggle-label">Steam</span>
      </button>
    </div>
  )
}
