import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchPosts, postImageUrl, type SteakPost } from '../api/client'
import { StarRating } from '../components/StarRating'
import { useAuth } from '../context/AuthContext'
import './FeedPage.css'

export function FeedPage() {
  const { isAuthenticated } = useAuth()
  const [posts, setPosts] = useState<SteakPost[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchPosts()
      .then(setPosts)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load feed'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <section className="feed-page">
      <header className="feed-header">
        <div>
          <h1>Steak feed</h1>
          <p>Fresh from the grill — rated by the community.</p>
        </div>
        {isAuthenticated && (
          <Link to="/post/new" className="btn primary">
            + Rate a steak
          </Link>
        )}
      </header>

      {loading && <p className="muted">Loading sizzling posts…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && !error && posts.length === 0 && (
        <div className="empty-feed">
          <p>No steaks yet. Be the first to fire up the grill!</p>
          {isAuthenticated ? (
            <Link to="/post/new" className="btn primary">
              Post your first steak
            </Link>
          ) : (
            <Link to="/register" className="btn primary">
              Join and post
            </Link>
          )}
        </div>
      )}

      <div className="post-grid">
        {posts.map((post) => (
          <article key={post.id} className="post-card">
            <div className="post-image-wrap">
              <img src={postImageUrl(post.imageUrl)} alt={post.title} loading="lazy" />
            </div>
            <div className="post-body">
              <div className="post-meta">
                <span className="author">@{post.author.username}</span>
                <time>{new Date(post.createdAt).toLocaleDateString()}</time>
              </div>
              <h2>{post.title}</h2>
              <StarRating value={post.rating} readOnly />
              {post.comment && <p className="post-comment">{post.comment}</p>}
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
