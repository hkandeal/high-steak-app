import { useCallback, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchBookmarkedPosts,
  FEED_PAGE_SIZE,
  postImageUrl,
  primaryPostImage,
  unbookmarkPost,
  type SteakPost,
} from '../api/client'
import { BackLink } from '../components/BackLink'
import { AuthorAvatar } from '../components/AuthorAvatar'
import { ImageLightbox } from '../components/ImageLightbox'
import { PostCardMenu, type PostCardMenuItem } from '../components/PostCardMenu'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { StarRating } from '../components/StarRating'
import { useAuth } from '../context/AuthContext'
import { useImageLightbox } from '../hooks/useImageLightbox'
import { useInfinitePostFeed } from '../hooks/useInfinitePostFeed'
import { listItemBackState } from '../navigation'
import './FeedPage.css'

export function BookmarksPage() {
  const { token, hasScope } = useAuth()
  const [actionError, setActionError] = useState<string | null>(null)
  const [pendingBookmarkId, setPendingBookmarkId] = useState<string | null>(null)
  const { lightbox, openLightbox, closeLightbox } = useImageLightbox()

  const loadPage = useCallback(
    async (page: number) => {
      if (!token) {
        return { content: [], page: 0, size: FEED_PAGE_SIZE, totalElements: 0, totalPages: 0 }
      }
      return fetchBookmarkedPosts(token, { page, size: FEED_PAGE_SIZE })
    },
    [token],
  )

  const { posts, setPosts, loading, loadingMore, error, hasMore, sentinelRef } = useInfinitePostFeed(
    loadPage,
    token ?? 'none',
  )

  async function handleUnbookmark(post: SteakPost) {
    if (!token || pendingBookmarkId) return
    setPendingBookmarkId(post.id)
    setActionError(null)
    try {
      await unbookmarkPost(token, post.id)
      setPosts((current) => current.filter((item) => item.id !== post.id))
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to remove bookmark')
    } finally {
      setPendingBookmarkId(null)
    }
  }

  function buildMenuItems(post: SteakPost): PostCardMenuItem[] {
    if (!hasScope('bookmarks:write')) return []
    return [
      {
        kind: 'action',
        label: pendingBookmarkId === post.id ? 'Removing…' : 'Remove bookmark',
        onSelect: () => {
          void handleUnbookmark(post)
        },
      },
    ]
  }

  return (
    <section className="feed-page">
      <BackLink to="/feed" label="Back to feed" />

      <header className="feed-header">
        <div>
          <h1>Bookmarks</h1>
          <p>Steak posts you saved for later.</p>
        </div>
      </header>

      {loading && <p className="muted">Loading bookmarks…</p>}
      {(error || actionError) && <p className="form-error">{error ?? actionError}</p>}

      {!loading && !error && posts.length === 0 && (
        <div className="empty-feed">
          <p>No bookmarks yet. Save posts you like from the feed.</p>
          <Link to="/feed" className="btn primary">
            Browse the feed
          </Link>
        </div>
      )}

      {!loading && !error && posts.length > 0 && (
        <div className="post-grid">
          {posts.map((post) => {
            const menuItems = buildMenuItems(post)
            return (
              <article key={post.id} className="post-card">
                <div className="post-card-media-wrap">
                  <div className="post-card-media">
                    <button
                      type="button"
                      className="post-image-lightbox-trigger"
                      onClick={() =>
                        openLightbox(
                          post.imageUrls.map((url) => postImageUrl(url)),
                          0,
                          post.title,
                        )
                      }
                      aria-label={`View photos for ${post.title}`}
                    >
                      <div className="post-image-wrap">
                        <img
                          src={postImageUrl(primaryPostImage(post))}
                          alt={post.title}
                          loading="lazy"
                        />
                        {post.imageUrls.length > 1 && (
                          <span className="photo-count">+{post.imageUrls.length - 1}</span>
                        )}
                        {post.visibility === 'FOLLOWERS_ONLY' && (
                          <span className="visibility-badge">Followers only</span>
                        )}
                      </div>
                    </button>
                  </div>
                  {menuItems.length > 0 && (
                    <PostCardMenu label={`Actions for ${post.title}`} items={menuItems} />
                  )}
                </div>
                <div className="post-body">
                  <div className="post-meta">
                    <Link
                      to={`/users/${post.author.id}`}
                      state={listItemBackState('/bookmarks', 'Back to bookmarks')}
                      className="post-author"
                    >
                      <AuthorAvatar
                        displayName={post.author.displayName}
                        avatarThumbnailUrl={post.author.avatarThumbnailUrl}
                        avatarUrl={post.author.avatarUrl}
                      />
                      <span className="author">{post.author.displayName}</span>
                    </Link>
                    <time>{new Date(post.createdAt).toLocaleDateString()}</time>
                  </div>
                  <Link
                    to={`/posts/${post.id}`}
                    state={listItemBackState('/bookmarks', 'Back to bookmarks')}
                    className="post-title-link"
                  >
                    <h2>{post.title}</h2>
                  </Link>
                  <StarRating value={post.rating} readOnly />
                  <ReviewTagChips tags={post.tags ?? []} compact />
                  {post.restaurantName && (
                    <p className="post-restaurant">{post.restaurantName}</p>
                  )}
                  {post.comment && <p className="post-comment">{post.comment}</p>}
                </div>
              </article>
            )
          })}
        </div>
      )}

      {hasMore && !loading && (
        <div ref={sentinelRef} className="infinite-scroll-sentinel">
          {loadingMore && <p className="muted">Loading more bookmarks…</p>}
        </div>
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
