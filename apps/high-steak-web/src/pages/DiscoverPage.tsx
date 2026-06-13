import { Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import {
  searchUsers,
  subscribeToUser,
  unsubscribeFromUser,
  type UserPublicProfile,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import { BackLink } from '../components/BackLink'
import { displayInitials } from '../utils/displayInitials'
import { listItemBackState } from '../navigation'
import './DiscoverPage.css'

export function DiscoverPage() {
  const { token } = useAuth()
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')
  const [results, setResults] = useState<UserPublicProfile[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [pendingUserId, setPendingUserId] = useState<string | null>(null)

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedQuery(query.trim()), 300)
    return () => window.clearTimeout(timer)
  }, [query])

  useEffect(() => {
    if (!token || debouncedQuery.length < 2) {
      setResults([])
      setError(null)
      setLoading(false)
      return
    }

    setLoading(true)
    setError(null)
    searchUsers(token, debouncedQuery)
      .then(setResults)
      .catch((err) => setError(err instanceof Error ? err.message : 'Search failed'))
      .finally(() => setLoading(false))
  }, [token, debouncedQuery])

  async function toggleSubscription(user: UserPublicProfile) {
    if (!token) return
    setPendingUserId(user.id)
    setError(null)
    try {
      if (user.subscribed) {
        await unsubscribeFromUser(token, user.id)
        setResults((current) =>
          current.map((item) =>
            item.id === user.id ? { ...item, subscribed: false } : item,
          ),
        )
      } else {
        await subscribeToUser(token, user.id)
        setResults((current) =>
          current.map((item) =>
            item.id === user.id ? { ...item, subscribed: true } : item,
          ),
        )
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update subscription')
    } finally {
      setPendingUserId(null)
    }
  }

  return (
    <section className="discover-page">
      <BackLink to="/feed" label="Back to feed" />

      <header className="discover-header">
        <div>
          <h1>Find steak lovers</h1>
          <p>Search and follow fellow carnivores.</p>
        </div>
      </header>

      <div className="discover-search">
        <input
          type="search"
          placeholder="Search by username or display name…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
        />
      </div>

      {loading && <p className="muted">Searching…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && debouncedQuery.length > 0 && debouncedQuery.length < 2 && (
        <p className="muted">Type at least 2 characters to search.</p>
      )}

      {!loading && debouncedQuery.length >= 2 && results.length === 0 && !error && (
        <div className="discover-empty">
          <p>No users found for &ldquo;{debouncedQuery}&rdquo;.</p>
        </div>
      )}

      <ul className="discover-results">
        {results.map((user) => (
          <li key={user.id} className="discover-card">
            <div className="discover-avatar">
              {user.avatarUrl ? (
                <img src={user.avatarUrl} alt="" />
              ) : (
                <span>{displayInitials(user.displayName)}</span>
              )}
            </div>
            <div className="discover-info">
              <Link
                to={`/users/${user.id}`}
                state={listItemBackState('/discover', 'Back to steak lovers')}
                className="discover-profile-link"
              >
                <strong>{user.displayName}</strong>
                <span className="discover-username">@{user.username}</span>
                <span className="discover-meta">
                  {user.postCount} {user.postCount === 1 ? 'post' : 'posts'}
                </span>
              </Link>
            </div>
            <button
              type="button"
              className={`btn ${user.subscribed ? 'ghost' : 'primary'} small`}
              disabled={pendingUserId === user.id}
              onClick={() => toggleSubscription(user)}
            >
              {pendingUserId === user.id
                ? '…'
                : user.subscribed
                  ? 'Unfollow'
                  : 'Follow'}
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
