import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  bookmarkPost,
  deletePost,
  fetchFollowingPosts,
  fetchPosts,
  FEED_PAGE_SIZE,
  hidePost,
  postImageUrl,
  primaryPostImage,
  subscribeToUser,
  unbookmarkPost,
  unsubscribeFromUser,
  type SteakPost,
} from '../api/client'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { HidePostDialog } from '../components/HidePostDialog'
import { ImageLightbox } from '../components/ImageLightbox'
import { PostBookmarkButton } from '../components/PostBookmarkButton'
import { AuthorAvatar } from '../components/AuthorAvatar'
import { AuthorFollowButton } from '../components/AuthorFollowButton'
import { PostCardMenu, type PostCardMenuItem } from '../components/PostCardMenu'
import { StarRating } from '../components/StarRating'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { useAuth } from '../context/AuthContext'
import { useInfinitePostFeed } from '../hooks/useInfinitePostFeed'
import { useImageLightbox } from '../hooks/useImageLightbox'
import { listItemBackState } from '../navigation'
import './FeedPage.css'

type FeedTab = 'everyone' | 'following'

export function FeedPage() {
  const { isAuthenticated, user, token, hasScope } = useAuth()
  const [tab, setTab] = useState<FeedTab>('everyone')
  const [deleteTarget, setDeleteTarget] = useState<SteakPost | null>(null)
  const [hideTarget, setHideTarget] = useState<SteakPost | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [hiding, setHiding] = useState(false)
  const [pendingBookmarkId, setPendingBookmarkId] = useState<string | null>(null)
  const [pendingFollowAuthorId, setPendingFollowAuthorId] = useState<string | null>(null)
  const { lightbox, openLightbox, closeLightbox } = useImageLightbox()

  const showFollowingTab = isAuthenticated && hasScope('subscriptions:read')

  useEffect(() => {
    if (tab === 'following' && !showFollowingTab) {
      setTab('everyone')
    }
  }, [tab, showFollowingTab])

  const loadPage = useCallback(
    async (page: number) => {
      if (!token) {
        return { content: [], page: 0, size: FEED_PAGE_SIZE, totalElements: 0, totalPages: 0 }
      }
      if (tab === 'following') {
        return fetchFollowingPosts(token, { page, size: FEED_PAGE_SIZE })
      }
      return fetchPosts(token, { page, size: FEED_PAGE_SIZE })
    },
    [tab, token],
  )

  const { posts, setPosts, loading, loadingMore, error, hasMore, sentinelRef } = useInfinitePostFeed(
    loadPage,
    `${tab}:${token ?? 'anon'}`,
  )
  const [actionError, setActionError] = useState<string | null>(null)

  async function handleDelete(postId: string) {
    if (!token) return
    await deletePost(token, postId)
    setPosts((current) => current.filter((post) => post.id !== postId))
  }

  async function confirmDelete() {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await handleDelete(deleteTarget.id)
      setDeleteTarget(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to delete post')
    } finally {
      setDeleting(false)
    }
  }

  async function confirmHide(reason: string) {
    if (!token || !hideTarget) return
    setHiding(true)
    setActionError(null)
    try {
      await hidePost(token, hideTarget.id, reason)
      setPosts((current) => current.filter((post) => post.id !== hideTarget.id))
      setHideTarget(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to hide post')
    } finally {
      setHiding(false)
    }
  }

  function canDeletePost(post: SteakPost) {
    if (hasScope('posts:delete:any')) return true
    if (hasScope('posts:delete:own') && user?.id === post.author.id) return true
    return false
  }

  function canEditPost(post: SteakPost) {
    return hasScope('posts:write') && user?.id === post.author.id
  }

  async function toggleBookmark(post: SteakPost) {
    if (!token || pendingBookmarkId) return
    setPendingBookmarkId(post.id)
    setActionError(null)
    try {
      if (post.bookmarked) {
        await unbookmarkPost(token, post.id)
        setPosts((current) =>
          current.map((item) => (item.id === post.id ? { ...item, bookmarked: false } : item)),
        )
      } else {
        await bookmarkPost(token, post.id)
        setPosts((current) =>
          current.map((item) => (item.id === post.id ? { ...item, bookmarked: true } : item)),
        )
      }
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to update bookmark')
    } finally {
      setPendingBookmarkId(null)
    }
  }

  async function toggleFollowAuthor(authorId: string, subscribed: boolean) {
    if (!token || pendingFollowAuthorId) return
    setPendingFollowAuthorId(authorId)
    setActionError(null)
    try {
      if (subscribed) {
        await unsubscribeFromUser(token, authorId)
      } else {
        await subscribeToUser(token, authorId)
      }
      setPosts((current) =>
        current.map((item) =>
          item.author.id === authorId
            ? { ...item, author: { ...item.author, subscribed: !subscribed } }
            : item,
        ),
      )
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to update follow')
    } finally {
      setPendingFollowAuthorId(null)
    }
  }

  function buildMenuItems(post: SteakPost): PostCardMenuItem[] {
    const items: PostCardMenuItem[] = []
    if (canEditPost(post)) {
      items.push({ kind: 'link', label: 'Edit post', to: `/posts/${post.id}/edit` })
    }
    if (hasScope('posts:moderate')) {
      items.push({
        kind: 'action',
        label: 'Block from feed',
        tone: 'danger',
        onSelect: () => setHideTarget(post),
      })
    }
    if (canDeletePost(post)) {
      items.push({
        kind: 'action',
        label: 'Delete post',
        tone: 'danger',
        onSelect: () => setDeleteTarget(post),
      })
    }
    return items
  }

  const emptyFollowing = tab === 'following' && !loading && !error && posts.length === 0

  return (
    <section className="feed-page">
      <header className="feed-header">
        <div>
          <h1>Steak feed</h1>
          <p>Fresh from the grill — rated by the community.</p>
        </div>
        {isAuthenticated && (
          <Link to="/post/new" className="btn primary feed-header-action">
            + Rate a steak
          </Link>
        )}
      </header>

      {showFollowingTab && (
        <div className="feed-tabs" role="tablist" aria-label="Feed">
          <button
            type="button"
            role="tab"
            aria-selected={tab === 'everyone'}
            className={`feed-tab ${tab === 'everyone' ? 'active' : ''}`}
            onClick={() => setTab('everyone')}
          >
            Everyone
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={tab === 'following'}
            className={`feed-tab ${tab === 'following' ? 'active' : ''}`}
            onClick={() => setTab('following')}
          >
            Following
          </button>
        </div>
      )}

      {loading && <p className="muted">Loading sizzling posts…</p>}
      {(error || actionError) && <p className="form-error">{error ?? actionError}</p>}

      {emptyFollowing && (
        <div className="empty-feed">
          <p>You&apos;re not following anyone yet.</p>
          <Link to="/discover" className="btn primary">
            Find steak lovers
          </Link>
        </div>
      )}

      {!loading && !error && tab === 'everyone' && posts.length === 0 && (
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

      {!loading && !error && posts.length > 0 && (
        <div className="post-grid">
          {posts.map((post) => {
            const menuItems = buildMenuItems(post)
            return (
              <article
                key={post.id}
                className={`post-card ${post.bookmarked ? 'post-card--bookmarked' : ''}`}
              >
                <div
                  className={`post-card-media-wrap ${post.visibility === 'FOLLOWERS_ONLY' ? 'has-visibility-badge' : ''}`}
                >
                  {hasScope('bookmarks:write') && (
                    <PostBookmarkButton
                      bookmarked={Boolean(post.bookmarked)}
                      busy={pendingBookmarkId === post.id}
                      postTitle={post.title}
                      onToggle={() => {
                        void toggleBookmark(post)
                      }}
                    />
                  )}
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
                      state={listItemBackState('/feed', 'Back to feed')}
                      className="post-author"
                    >
                      <AuthorAvatar
                        displayName={post.author.displayName}
                        avatarThumbnailUrl={post.author.avatarThumbnailUrl}
                        avatarUrl={post.author.avatarUrl}
                      />
                      <span className="author">{post.author.displayName}</span>
                    </Link>
                    <div className="post-meta-actions">
                      {tab === 'everyone'
                        && hasScope('subscriptions:write')
                        && post.author.subscribed != null && (
                        <AuthorFollowButton
                          subscribed={post.author.subscribed}
                          authorDisplayName={post.author.displayName}
                          busy={pendingFollowAuthorId === post.author.id}
                          onToggle={() => {
                            void toggleFollowAuthor(post.author.id, post.author.subscribed ?? false)
                          }}
                        />
                      )}
                      <time>{new Date(post.createdAt).toLocaleDateString()}</time>
                    </div>
                  </div>
                  <Link
                    to={`/posts/${post.id}`}
                    state={listItemBackState('/feed', 'Back to feed')}
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
          {loadingMore && <p className="muted">Loading more posts…</p>}
        </div>
      )}

      <HidePostDialog
        open={hideTarget !== null}
        postTitle={hideTarget?.title ?? ''}
        loading={hiding}
        onConfirm={(reason) => {
          void confirmHide(reason)
        }}
        onCancel={() => {
          if (!hiding) setHideTarget(null)
        }}
      />

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Delete this post?"
        message={
          deleteTarget
            ? `“${deleteTarget.title}” will be removed permanently. This cannot be undone.`
            : ''
        }
        confirmLabel="Delete post"
        cancelLabel="Keep post"
        variant="danger"
        loading={deleting}
        onConfirm={() => {
          void confirmDelete()
        }}
        onCancel={() => {
          if (!deleting) setDeleteTarget(null)
        }}
      />

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
