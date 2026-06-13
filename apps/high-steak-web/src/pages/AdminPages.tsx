import { useEffect, useState } from 'react'
import {
  deletePost,
  fetchHiddenPosts,
  listUsers,
  postImageUrl,
  primaryPostImage,
  updateUserRole,
  type SteakPost,
  type UserProfile,
} from '../api/client'
import { StarRating } from '../components/StarRating'
import { useAuth } from '../context/AuthContext'
import './FeedPage.css'

export function ModerationPage() {
  const { token } = useAuth()
  const [posts, setPosts] = useState<SteakPost[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return
    fetchHiddenPosts(token)
      .then(setPosts)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load hidden posts'))
      .finally(() => setLoading(false))
  }, [token])

  async function handleDelete(postId: string) {
    if (!token) return
    await deletePost(token, postId)
    setPosts((current) => current.filter((post) => post.id !== postId))
  }

  return (
    <section className="feed-page">
      <header className="feed-header">
        <div>
          <h1>Moderation</h1>
          <p>Hidden posts removed from the public feed.</p>
        </div>
      </header>

      {loading && <p className="muted">Loading hidden posts…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && !error && posts.length === 0 && (
        <div className="empty-feed">
          <p>No hidden posts right now.</p>
        </div>
      )}

      <div className="post-grid">
        {posts.map((post) => (
          <article key={post.id} className="post-card">
            <div className="post-image-wrap">
              <img src={postImageUrl(primaryPostImage(post))} alt={post.title} loading="lazy" />
            </div>
            <div className="post-body">
              <div className="post-meta">
                <span className="author">{post.author.displayName}</span>
                <time>{new Date(post.createdAt).toLocaleDateString()}</time>
              </div>
              <h2>{post.title}</h2>
              <StarRating value={post.rating} readOnly />
              {post.comment && <p className="post-comment">{post.comment}</p>}
              <div className="post-actions">
                <button type="button" className="btn ghost" onClick={() => handleDelete(post.id)}>
                  Delete permanently
                </button>
              </div>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

export function AdminUsersPage() {
  const { token } = useAuth()
  const [users, setUsers] = useState<UserProfile[]>([])
  const [assignedRoles, setAssignedRoles] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return
    listUsers(token)
      .then(setUsers)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load users'))
      .finally(() => setLoading(false))
  }, [token])

  async function handleRoleChange(userId: string, role: string) {
    if (!token) return
    await updateUserRole(token, userId, role)
    setAssignedRoles((current) => ({ ...current, [userId]: role }))
  }

  return (
    <section className="feed-page">
      <header className="feed-header">
        <div>
          <h1>User management</h1>
          <p>Assign roles to control API scopes and UI access. Current roles are not returned by the API — pick a role to assign.</p>
        </div>
      </header>

      {loading && <p className="muted">Loading users…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && !error && (
        <div className="admin-table-wrap">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Username</th>
                <th>Email</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id}>
                  <td>@{user.username}</td>
                  <td>{user.email}</td>
                  <td>
                    <select
                      value={assignedRoles[user.id] ?? 'USER'}
                      onChange={(e) => handleRoleChange(user.id, e.target.value)}
                    >
                      <option value="USER">USER</option>
                      <option value="MODERATOR">MODERATOR</option>
                      <option value="ADMIN">ADMIN</option>
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}
