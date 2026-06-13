import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  addPostComment,
  fetchPost,
  fetchPostComments,
  postImageUrl,
  type PostComment,
  type SteakPost,
} from '../api/client'
import { StarRating } from '../components/StarRating'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { PageBackLink } from '../components/BackLink'
import { useAuth } from '../context/AuthContext'
import './PostDetailPage.css'

export function PostDetailPage() {
  const { postId } = useParams<{ postId: string }>()
  const { token, isAuthenticated, hasScope, user } = useAuth()
  const [post, setPost] = useState<SteakPost | null>(null)
  const [comments, setComments] = useState<PostComment[]>([])
  const [activeImage, setActiveImage] = useState(0)
  const [commentBody, setCommentBody] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const canComment = isAuthenticated && hasScope('comments:write')
  const canEdit = isAuthenticated && hasScope('posts:write') && user?.id === post?.author.id

  useEffect(() => {
    if (!postId || !token) return
    setLoading(true)
    setError(null)
    Promise.all([fetchPost(postId, token), fetchPostComments(postId, token)])
      .then(([postData, commentsData]) => {
        setPost(postData)
        setComments(commentsData)
        setActiveImage(0)
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load post'))
      .finally(() => setLoading(false))
  }, [postId, token])

  async function handleSubmitComment(e: FormEvent) {
    e.preventDefault()
    if (!token || !post || !commentBody.trim()) return
    setSubmitting(true)
    setError(null)
    try {
      const created = await addPostComment(token, post.id, commentBody.trim())
      setComments((current) => [...current, created])
      setCommentBody('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add comment')
    } finally {
      setSubmitting(false)
    }
  }

  if (!postId) {
    return <p className="form-error">Post not found.</p>
  }

  return (
    <section className="post-detail-page">
      <PageBackLink defaultTo="/feed" defaultLabel="Back to feed" />

      {loading && <p className="muted">Loading post…</p>}
      {error && <p className="form-error">{error}</p>}

      {post && (
        <>
          <div className="post-detail-grid">
            <div className="post-gallery">
              <div className="post-gallery-main">
                <img
                  src={postImageUrl(post.imageUrls[activeImage] ?? '')}
                  alt={post.title}
                />
              </div>
              {post.imageUrls.length > 1 && (
                <div className="post-gallery-thumbs">
                  {post.imageUrls.map((url, index) => (
                    <button
                      key={`${url}-${index}`}
                      type="button"
                      className={`thumb ${index === activeImage ? 'active' : ''}`}
                      onClick={() => setActiveImage(index)}
                    >
                      <img src={postImageUrl(url)} alt="" />
                    </button>
                  ))}
                </div>
              )}
            </div>

            <div className="post-detail-body">
              <div className="post-meta">
                <Link to={`/users/${post.author.id}`} className="author">
                  {post.author.displayName}
                </Link>
                <time>{new Date(post.createdAt).toLocaleString()}</time>
              </div>
              <h1>{post.title}</h1>
              {canEdit && (
                <div className="post-editor-actions">
                  <Link to={`/posts/${post.id}/edit`} className="btn ghost small">
                    Edit post
                  </Link>
                </div>
              )}
              <StarRating value={post.rating} readOnly />
              <ReviewTagChips tags={post.tags ?? []} />
              {post.restaurantName && (
                <p className="post-venue">
                  <strong>{post.restaurantName}</strong>
                  {post.restaurantLocation && <span> · {post.restaurantLocation}</span>}
                </p>
              )}
              {post.comment && <p className="post-caption">{post.comment}</p>}
            </div>
          </div>

          <section className="comments-section">
            <h2>Comments ({comments.length})</h2>

            {canComment ? (
              <form className="comment-form" onSubmit={handleSubmitComment}>
                <textarea
                  value={commentBody}
                  onChange={(e) => setCommentBody(e.target.value)}
                  rows={3}
                  placeholder="Share your thoughts…"
                  required
                />
                <button type="submit" className="btn primary" disabled={submitting || !commentBody.trim()}>
                  {submitting ? 'Posting…' : 'Post comment'}
                </button>
              </form>
            ) : (
              <p className="muted comment-login-hint">
                <Link to="/login">Log in</Link> to leave a comment.
              </p>
            )}

            <ul className="comment-list">
              {comments.map((comment) => (
                <li key={comment.id} className="comment-item">
                  <div className="comment-meta">
                    <Link to={`/users/${comment.author.id}`}>{comment.author.displayName}</Link>
                    <time>{new Date(comment.createdAt).toLocaleString()}</time>
                  </div>
                  <p>{comment.body}</p>
                </li>
              ))}
            </ul>

            {!loading && comments.length === 0 && (
              <p className="muted">No comments yet. Be the first!</p>
            )}
          </section>
        </>
      )}
    </section>
  )
}
