import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export function NotificationSettingsPage() {
  const { user } = useAuth()

  if (!user) return null

  return <Navigate to={`/users/${user.id}?edit=1#email-settings`} replace />
}
