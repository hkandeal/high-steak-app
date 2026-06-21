import { useEffect, useState } from 'react'
import {
  fetchNotificationPreferences,
  updateNotificationPreferences,
  type NotificationPreferences,
  type UpdateNotificationPreferences,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import './EmailNotificationSettings.css'

type PreferenceKey = keyof NotificationPreferences

type PreferenceTile = {
  key: PreferenceKey
  icon: string
  label: string
  description: string
  master?: boolean
}

const PREFERENCE_TILES: PreferenceTile[] = [
  {
    key: 'emailEnabled',
    icon: '✉️',
    label: 'Email from High Steaks',
    description: 'Master switch for all notification emails.',
    master: true,
  },
  {
    key: 'commentEmail',
    icon: '💬',
    label: 'New comments',
    description: 'When someone comments on your posts.',
  },
  {
    key: 'followerEmail',
    icon: '👥',
    label: 'New followers',
    description: 'When someone follows you.',
  },
  {
    key: 'moderationEmail',
    icon: '🛡',
    label: 'Moderation updates',
    description: 'When a moderator hides or restores your posts.',
  },
  {
    key: 'welcomeEmail',
    icon: '👋',
    label: 'Welcome email',
    description: 'Sent once when you create your account.',
  },
]

type EmailNotificationSettingsProps = {
  embedded?: boolean
}

export function EmailNotificationSettings({ embedded = false }: EmailNotificationSettingsProps) {
  const { token } = useAuth()
  const [prefs, setPrefs] = useState<NotificationPreferences | null>(null)
  const [loading, setLoading] = useState(true)
  const [savingKey, setSavingKey] = useState<PreferenceKey | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return
    setLoading(true)
    setError(null)
    fetchNotificationPreferences(token)
      .then(setPrefs)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load settings'))
      .finally(() => setLoading(false))
  }, [token])

  async function handleToggle(key: PreferenceKey) {
    if (!token || !prefs) return
    const nextValue = !prefs[key]
    const patch: UpdateNotificationPreferences = { [key]: nextValue }
    setSavingKey(key)
    setError(null)
    try {
      const updated = await updateNotificationPreferences(token, patch)
      setPrefs(updated)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save settings')
    } finally {
      setSavingKey(null)
    }
  }

  if (!token) return null

  const master = PREFERENCE_TILES.find((tile) => tile.master)
  const detailTiles = PREFERENCE_TILES.filter((tile) => !tile.master)

  return (
    <section
      className={`email-notification-settings${embedded ? ' email-notification-settings--embedded' : ''}`}
      id="email-settings"
      aria-labelledby="email-settings-heading"
    >
      <header className="email-notification-settings-header">
        <div className="email-notification-settings-intro">
          {!embedded && (
            <span className="email-notification-settings-badge" aria-hidden="true">
              ✉
            </span>
          )}
          <div>
            <h2 id="email-settings-heading">{embedded ? 'Email notifications' : 'Your inbox'}</h2>
            <p className="muted">Choose when High Steaks reaches out by email.</p>
          </div>
        </div>
      </header>

      {loading && <p className="muted">Loading email preferences…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && prefs && master && (
        <>
          <div className="email-notification-settings-master">
            <div className="email-notification-settings-master-text">
              <span className="email-notification-settings-tile-icon" aria-hidden="true">
                {master.icon}
              </span>
              <div>
                <strong>{master.label}</strong>
                <span className="muted">{master.description}</span>
              </div>
            </div>
            <label className="email-toggle">
              <input
                type="checkbox"
                role="switch"
                checked={prefs.emailEnabled}
                disabled={savingKey === master.key}
                onChange={() => void handleToggle(master.key)}
              />
              <span className="email-toggle-track" aria-hidden="true">
                <span className="email-toggle-thumb" />
              </span>
              <span className="visually-hidden">{master.label}</span>
            </label>
          </div>

          <div className={`email-notification-settings-grid${prefs.emailEnabled ? '' : ' is-muted'}`}>
            {detailTiles.map(({ key, icon, label, description }) => {
              const disabled = !prefs.emailEnabled || savingKey === key
              const checked = prefs[key]
              return (
                <label
                  key={key}
                  className={`email-notification-settings-tile${checked ? ' is-on' : ''}${disabled ? ' is-disabled' : ''}`}
                >
                  <input
                    type="checkbox"
                    checked={checked}
                    disabled={disabled}
                    onChange={() => void handleToggle(key)}
                  />
                  <span className="email-notification-settings-tile-icon" aria-hidden="true">
                    {icon}
                  </span>
                  <span className="email-notification-settings-tile-body">
                    <strong>{label}</strong>
                    <span className="muted">{description}</span>
                  </span>
                  <span className="email-notification-settings-tile-state" aria-hidden="true">
                    {checked ? 'On' : 'Off'}
                  </span>
                </label>
              )
            })}
          </div>
        </>
      )}
    </section>
  )
}
