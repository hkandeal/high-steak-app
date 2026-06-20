import { useEffect, useState } from 'react'
import {
  fetchNotificationPreferences,
  updateNotificationPreferences,
  type NotificationPreferences,
  type UpdateNotificationPreferences,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import { BackLink } from '../components/BackLink'
import './NotificationSettingsPage.css'

type PreferenceKey = keyof Omit<NotificationPreferences, never>

const PREFERENCE_FIELDS: {
  key: PreferenceKey
  label: string
  description: string
  master?: boolean
}[] = [
  {
    key: 'emailEnabled',
    label: 'Email notifications',
    description: 'Master switch for all High Steaks emails.',
    master: true,
  },
  {
    key: 'welcomeEmail',
    label: 'Welcome email',
    description: 'Sent once when you create your account.',
  },
  {
    key: 'commentEmail',
    label: 'New comments',
    description: 'When someone comments on your posts.',
  },
  {
    key: 'followerEmail',
    label: 'New followers',
    description: 'When someone follows you.',
  },
  {
    key: 'moderationEmail',
    label: 'Moderation updates',
    description: 'When a moderator hides or restores your posts.',
  },
]

export function NotificationSettingsPage() {
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

  return (
    <section className="notification-settings-page">
      <BackLink to="/feed" label="Back to feed" />

      <header className="notification-settings-header">
        <h1>Email notifications</h1>
        <p className="muted">Choose which emails High Steaks sends you.</p>
      </header>

      {loading && <p className="muted">Loading…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && prefs && (
        <ul className="notification-settings-list">
          {PREFERENCE_FIELDS.map(({ key, label, description, master }) => {
            const disabled = !master && !prefs.emailEnabled
            const checked = prefs[key]
            return (
              <li
                key={key}
                className={`notification-settings-item${master ? ' notification-settings-item--master' : ''}`}
              >
                <label className="notification-settings-label">
                  <input
                    type="checkbox"
                    checked={checked}
                    disabled={disabled || savingKey === key}
                    onChange={() => void handleToggle(key)}
                  />
                  <span className="notification-settings-text">
                    <strong>{label}</strong>
                    <span className="muted">{description}</span>
                  </span>
                </label>
              </li>
            )
          })}
        </ul>
      )}
    </section>
  )
}
