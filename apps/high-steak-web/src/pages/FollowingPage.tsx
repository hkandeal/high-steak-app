import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  listSubscriptions,
  postImageUrl,
  unsubscribeFromUser,
  type SubscriptionSummary,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import { BackLink } from '../components/BackLink'
import { displayInitials } from '../utils/displayInitials'
import { listItemBackState } from '../navigation'
import './DiscoverPage.css'

export function FollowingPage() {
  const { token } = useAuth()
  const [subscriptions, setSubscriptions] = useState<SubscriptionSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [pendingUserId, setPendingUserId] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return
    setLoading(true)
    setError(null)
    listSubscriptions(token)
      .then(setSubscriptions)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load following'))
      .finally(() => setLoading(false))
  }, [token])

  async function handleUnfollow(userId: string) {
    if (!token) return
    setPendingUserId(userId)
    setError(null)
    try {
      await unsubscribeFromUser(token, userId)
      setSubscriptions((current) => current.filter((item) => item.user.id !== userId))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to unfollow')
    } finally {
      setPendingUserId(null)
    }
  }

  return (
    <section className="discover-page">
      <BackLink to="/feed" label="Back to feed" />

      <header className="discover-header">
        <div>
          <h1>Following</h1>
          <p>Chefs and steak lovers you follow.</p>
        </div>
      </header>

      {loading && <p className="muted">Loading…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && !error && subscriptions.length === 0 && (
        <div className="discover-empty">
          <p>You&apos;re not following anyone yet.</p>
          <Link to="/discover" className="btn primary">
            Find steak lovers
          </Link>
        </div>
      )}

      <ul className="discover-results">
        {subscriptions.map(({ user, subscribedAt }) => (
          <li key={user.id} className="discover-card">
            <div className="discover-avatar">
              {user.avatarUrl ? (
                <img src={postImageUrl(user.avatarUrl)} alt="" />
              ) : (
                <span>{displayInitials(user.displayName)}</span>
              )}
            </div>
            <div className="discover-info">
              <Link
                to={`/users/${user.id}`}
                state={listItemBackState('/following', 'Back to following')}
                className="discover-profile-link"
              >
                <strong>{user.displayName}</strong>
                <span className="discover-username">@{user.username}</span>
                <span className="discover-meta">
                  {user.postCount} {user.postCount === 1 ? 'post' : 'posts'} · followed{' '}
                  {new Date(subscribedAt).toLocaleDateString()}
                </span>
              </Link>
            </div>
            <button
              type="button"
              className="btn ghost small"
              disabled={pendingUserId === user.id}
              onClick={() => handleUnfollow(user.id)}
            >
              {pendingUserId === user.id ? '…' : 'Unfollow'}
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
