import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  addPostComment,
  fetchPost,
  fetchPostComments,
  FEED_PAGE_SIZE,
  postImageUrl,
  type SteakPost,
} from '../api/client'
import { StarRating } from '../components/StarRating'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { ImageLightbox } from '../components/ImageLightbox'
import { AuthorPostModerationNotice } from '../components/AuthorPostModerationNotice'
import { PageBackLink } from '../components/BackLink'
import { useAuth } from '../context/AuthContext'
import { useModerationNoticesContext } from '../context/ModerationNoticesContext'
import { useInfiniteComments } from '../hooks/useInfiniteComments'
import { useImageLightbox } from '../hooks/useImageLightbox'
import { markModerationPostsSeen, markRestoredNoticesSeen } from '../utils/moderationNotices'
import { API_CONSTRAINTS } from '../api/constraints'
import { validateCommentBody } from '../utils/validation'
import './PostDetailPage.css'

export function PostDetailPage() {
  const { postId } = useParams<{ postId: string }>()
  const { token, isAuthenticated, hasScope, user } = useAuth()
  const { reload: reloadModerationNotices } = useModerationNoticesContext()
  const [post, setPost] = useState<SteakPost | null>(null)
  const [activeImage, setActiveImage] = useState(0)
  const [commentBody, setCommentBody] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const { lightbox, openLightbox, closeLightbox } = useImageLightbox()

  const loadCommentsPage = useCallback(
    async (page: number) => {
      if (!token || !postId) {
        return { content: [], page: 0, size: FEED_PAGE_SIZE, totalElements: 0, totalPages: 0 }
      }
      return fetchPostComments(postId, token, { page, size: FEED_PAGE_SIZE })
    },
    [postId, token],
  )

  const {
    comments,
    setComments,
    totalElements,
    setTotalElements,
    loading: commentsLoading,
    loadingMore: commentsLoadingMore,
    error: commentsError,
    hasMore: commentsHasMore,
    sentinelRef: commentsSentinelRef,
  } = useInfiniteComments(loadCommentsPage, `${postId}:${token ?? 'anon'}`)

  const canComment = isAuthenticated && hasScope('comments:write')
  const canEdit = isAuthenticated && hasScope('posts:write') && user?.id === post?.author.id

  useEffect(() => {
    if (!postId || !token) return
    setLoading(true)
    setError(null)
    fetchPost(postId, token)
      .then((postData) => {
        setPost(postData)
        setActiveImage(0)
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load post'))
      .finally(() => setLoading(false))
  }, [postId, token])

  useEffect(() => {
    if (!post || !user || post.author.id !== user.id) return
    if (post.hidden) {
      markModerationPostsSeen(user.id, [post.id])
    } else if (post.moderationRestoredAt) {
      markRestoredNoticesSeen(user.id, [
        { id: post.id, moderationRestoredAt: post.moderationRestoredAt },
      ])
    } else {
      return
    }
    void reloadModerationNotices()
  }, [post, user, reloadModerationNotices])

  async function handleSubmitComment(e: FormEvent) {
    e.preventDefault()
    if (!token || !post || !commentBody.trim()) return
    const validationError = validateCommentBody(commentBody)
    if (validationError) {
      setError(validationError)
      return
    }
    setSubmitting(true)
    setError(null)
    try {
      const created = await addPostComment(token, post.id, commentBody.trim())
      setComments((current) => [...current, created])
      setTotalElements((count) => count + 1)
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

  const displayError = error ?? commentsError
  const galleryImages = post?.imageUrls.map((url) => postImageUrl(url)) ?? []

  return (
    <section className="post-detail-page">
      <PageBackLink defaultTo="/feed" defaultLabel="Back to feed" />

      {loading && <p className="muted">Loading post…</p>}
      {displayError && <p className="form-error">{displayError}</p>}

      {post && (
        <>
          {post.hidden && user?.id === post.author.id && (
            <AuthorPostModerationNotice reason={post.moderationReason} variant="banner" />
          )}

          <div className="post-detail-grid">
            <div className="post-gallery">
              <button
                type="button"
                className="post-gallery-main post-gallery-main-button"
                onClick={() => openLightbox(galleryImages, activeImage, post.title)}
                aria-label="View photo full size"
              >
                <img
                  src={postImageUrl(post.imageUrls[activeImage] ?? '')}
                  alt={post.title}
                />
                <span className="post-gallery-expand" aria-hidden="true">⤢</span>
              </button>
              {post.imageUrls.length > 1 && (
                <div className="post-gallery-thumbs">
                  {post.imageUrls.map((url, index) => (
                    <button
                      key={`${url}-${index}`}
                      type="button"
                      className={`thumb ${index === activeImage ? 'active' : ''}`}
                      onClick={() => setActiveImage(index)}
                      onDoubleClick={() => openLightbox(galleryImages, index, post.title)}
                      aria-label={`Show photo ${index + 1}`}
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
            <h2>Comments ({totalElements})</h2>

            {canComment ? (
              <form className="comment-form" onSubmit={handleSubmitComment}>
                <textarea
                  value={commentBody}
                  onChange={(e) => setCommentBody(e.target.value)}
                  rows={3}
                  placeholder="Share your thoughts…"
                  maxLength={API_CONSTRAINTS.commentBody.max}
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

            {commentsLoading && !loading && <p className="muted">Loading comments…</p>}

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

            {commentsHasMore && !commentsLoading && (
              <div ref={commentsSentinelRef} className="infinite-scroll-sentinel">
                {commentsLoadingMore && <p className="muted">Loading more comments…</p>}
              </div>
            )}

            {!loading && !commentsLoading && totalElements === 0 && (
              <p className="muted">No comments yet. Be the first!</p>
            )}
          </section>
        </>
      )}

      <ImageLightbox
        open={lightbox !== null}
        images={lightbox?.images ?? []}
        initialIndex={lightbox?.index ?? 0}
        alt={lightbox?.alt}
        onClose={closeLightbox}
      />
    </section>
  )
}
