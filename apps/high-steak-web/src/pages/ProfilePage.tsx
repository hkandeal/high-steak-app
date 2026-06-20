import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  bookmarkPost,
  deletePost,
  fetchUserPosts,
  fetchUserProfile,
  FEED_PAGE_SIZE,
  hidePost,
  postImageUrl,
  primaryPostImage,
  setUserBlocked,
  unbookmarkPost,
  unhidePost,
  subscribeToUser,
  unsubscribeFromUser,
  updateProfile,
  type SteakPost,
  type UserPublicProfile,
} from '../api/client'
import { AvatarCropModal } from '../components/AvatarCropModal'
import { AuthorPostModerationNotice } from '../components/AuthorPostModerationNotice'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { HidePostDialog } from '../components/HidePostDialog'
import { ImageLightbox } from '../components/ImageLightbox'
import { PageBackLink } from '../components/BackLink'
import { PostCardMenu, type PostCardMenuItem } from '../components/PostCardMenu'
import { StarRating } from '../components/StarRating'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { useAuth } from '../context/AuthContext'
import { useModerationNoticesContext } from '../context/ModerationNoticesContext'
import { useInfinitePostFeed } from '../hooks/useInfinitePostFeed'
import { useImageLightbox } from '../hooks/useImageLightbox'
import { listItemBackState } from '../navigation'
import { displayInitials } from '../utils/displayInitials'
import { validateImageFile, validateProfileForm } from '../utils/validation'
import { API_CONSTRAINTS, MAX_IMAGE_MB } from '../api/constraints'
import '../components/AuthorPostModerationNotice.css'
import '../components/ManagementPage.css'
import './FeedPage.css'
import './ProfilePage.css'

export function ProfilePage() {
  const { userId } = useParams<{ userId: string }>()
  const { user, token, isAuthenticated, hasScope, applyToken } = useAuth()
  const { hiddenPosts: moderatedHiddenPosts } = useModerationNoticesContext()
  const [profile, setProfile] = useState<UserPublicProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [pendingFollow, setPendingFollow] = useState(false)
  const [editing, setEditing] = useState(false)
  const [displayName, setDisplayName] = useState('')
  const [avatarFile, setAvatarFile] = useState<File | null>(null)
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null)
  const [cropImageSrc, setCropImageSrc] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [blockingUser, setBlockingUser] = useState(false)
  const [hideTarget, setHideTarget] = useState<SteakPost | null>(null)
  const [hiding, setHiding] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<SteakPost | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [pendingBookmarkId, setPendingBookmarkId] = useState<string | null>(null)
  const [profileAlertExpanded, setProfileAlertExpanded] = useState(false)
  const { lightbox, openLightbox, closeLightbox } = useImageLightbox()

  const isOwnProfile = isAuthenticated && user?.id === userId
  const canFollow = isAuthenticated && hasScope('subscriptions:write') && !isOwnProfile
  const canPost = isOwnProfile && hasScope('posts:write')
  const canModerateProfile = hasScope('posts:moderate') && !isOwnProfile
  const canBlockProfile =
    hasScope('users:block') && !isOwnProfile && profile?.role === 'USER'

  const loadPostsPage = useCallback(
    async (page: number) => {
      if (!token || !userId) {
        return { content: [], page: 0, size: FEED_PAGE_SIZE, totalElements: 0, totalPages: 0 }
      }
      return fetchUserPosts(userId, token, { page, size: FEED_PAGE_SIZE })
    },
    [token, userId],
  )

  const {
    posts,
    setPosts,
    loading: postsLoading,
    loadingMore: postsLoadingMore,
    error: postsError,
    hasMore: postsHasMore,
    sentinelRef: postsSentinelRef,
  } = useInfinitePostFeed(loadPostsPage, `${userId}:${token ?? 'anon'}`)

  useEffect(() => {
    if (!userId || !token) return
    setLoading(true)
    setError(null)
    fetchUserProfile(userId, token)
      .then((profileData) => {
        setProfile(profileData)
        setDisplayName(profileData.displayName)
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load profile'))
      .finally(() => setLoading(false))
  }, [userId, token])

  useEffect(() => {
    if (isOwnProfile && user) {
      setDisplayName(user.displayName)
    }
  }, [isOwnProfile, user])

  function startEditing() {
    if (!user) return
    setDisplayName(user.displayName)
    setAvatarFile(null)
    if (avatarPreview) URL.revokeObjectURL(avatarPreview)
    setAvatarPreview(null)
    if (cropImageSrc) URL.revokeObjectURL(cropImageSrc)
    setCropImageSrc(null)
    setEditing(true)
  }

  function handleAvatarPick(file: File | null) {
    if (!file) return
    const imageError = validateImageFile(file)
    if (imageError) {
      setError(imageError)
      return
    }
    setError(null)
    if (cropImageSrc) URL.revokeObjectURL(cropImageSrc)
    setCropImageSrc(URL.createObjectURL(file))
  }

  function handleCropCancel() {
    if (cropImageSrc) URL.revokeObjectURL(cropImageSrc)
    setCropImageSrc(null)
  }

  function handleCropComplete(file: File) {
    if (cropImageSrc) URL.revokeObjectURL(cropImageSrc)
    setCropImageSrc(null)
    if (avatarPreview) URL.revokeObjectURL(avatarPreview)
    setAvatarFile(file)
    setAvatarPreview(URL.createObjectURL(file))
  }

  async function handleSaveProfile(e: FormEvent) {
    e.preventDefault()
    if (!token) return
    const validationError = validateProfileForm({ displayName, avatar: avatarFile })
    if (validationError) {
      setError(validationError)
      return
    }
    setSaving(true)
    setError(null)
    try {
      const response = await updateProfile(token, {
        displayName,
        avatar: avatarFile,
      })
      applyToken(response.token)
      setProfile((current) =>
        current
          ? {
              ...current,
              displayName: response.user.displayName,
              avatarUrl: response.user.avatarUrl,
            }
          : current,
      )
      setEditing(false)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update profile')
    } finally {
      setSaving(false)
    }
  }

  async function toggleFollow() {
    if (!token || !profile || !canFollow) return
    setPendingFollow(true)
    setError(null)
    try {
      if (profile.subscribed) {
        await unsubscribeFromUser(token, profile.id)
        setProfile({ ...profile, subscribed: false })
      } else {
        await subscribeToUser(token, profile.id)
        setProfile({ ...profile, subscribed: true })
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update follow status')
    } finally {
      setPendingFollow(false)
    }
  }

  async function confirmHide(reason: string) {
    if (!token || !hideTarget || !canModerateProfile) return
    setHiding(true)
    setError(null)
    try {
      const updated = await hidePost(token, hideTarget.id, reason)
      setPosts((current) =>
        canModerateProfile && !isOwnProfile
          ? current.filter((post) => post.id !== hideTarget.id)
          : current.map((post) => (post.id === hideTarget.id ? updated : post)),
      )
      if (!isOwnProfile) {
        setProfile((current) =>
          current ? { ...current, postCount: Math.max(0, current.postCount - 1) } : current,
        )
      }
      setHideTarget(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to block post from feed')
    } finally {
      setHiding(false)
    }
  }

  async function handleUnhidePost(postId: string) {
    if (!token || !canModerateProfile) return
    setError(null)
    try {
      const updated = await unhidePost(token, postId)
      setPosts((current) => current.map((post) => (post.id === postId ? updated : post)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to restore post')
    }
  }

  async function handleBlockUser() {
    if (!token || !profile || !canBlockProfile) return
    setBlockingUser(true)
    setError(null)
    try {
      const nextBlocked = !profile.blocked
      await setUserBlocked(token, profile.id, nextBlocked)
      setProfile({ ...profile, blocked: nextBlocked })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update account status')
    } finally {
      setBlockingUser(false)
    }
  }

  function buildPostMenuItems(post: SteakPost): PostCardMenuItem[] {
    const items: PostCardMenuItem[] = []

    if (!isOwnProfile && hasScope('bookmarks:write')) {
      items.push({
        kind: 'action',
        label:
          pendingBookmarkId === post.id
            ? 'Saving…'
            : post.bookmarked
              ? 'Remove bookmark'
              : 'Bookmark',
        onSelect: () => {
          void toggleBookmark(post)
        },
      })
    }

    if (isOwnProfile && hasScope('posts:write')) {
      items.push({ kind: 'link', label: 'Edit post', to: `/posts/${post.id}/edit` })
    }
    if (isOwnProfile && hasScope('posts:delete:own')) {
      items.push({
        kind: 'action',
        label: 'Delete post',
        tone: 'danger',
        onSelect: () => setDeleteTarget(post),
      })
    }
    if (canModerateProfile) {
      if (post.hidden) {
        items.push({
          kind: 'action',
          label: 'Restore to feed',
          onSelect: () => {
            void handleUnhidePost(post.id)
          },
        })
      } else {
        items.push({
          kind: 'action',
          label: 'Block from feed',
          tone: 'danger',
          onSelect: () => setHideTarget(post),
        })
      }
    }

    return items
  }

  async function toggleBookmark(post: SteakPost) {
    if (!token || pendingBookmarkId) return
    setPendingBookmarkId(post.id)
    setError(null)
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
      setError(err instanceof Error ? err.message : 'Failed to update bookmark')
    } finally {
      setPendingBookmarkId(null)
    }
  }

  async function confirmDeletePost() {
    if (!token || !deleteTarget) return
    setDeleting(true)
    setError(null)
    try {
      await deletePost(token, deleteTarget.id)
      setPosts((current) => current.filter((post) => post.id !== deleteTarget.id))
      setProfile((current) =>
        current ? { ...current, postCount: Math.max(0, current.postCount - 1) } : current,
      )
      setDeleteTarget(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete post')
    } finally {
      setDeleting(false)
    }
  }

  const hiddenPostCount = isOwnProfile ? moderatedHiddenPosts.length : 0

  if (!userId) {
    return <p className="form-error">User not found.</p>
  }

  const avatarSrc = avatarPreview
    ?? (profile?.avatarUrl ? postImageUrl(profile.avatarUrl) : null)

  return (
    <section className="profile-page">
      <PageBackLink defaultTo="/feed" defaultLabel="Back to feed" />

      {loading && <p className="muted">Loading profile…</p>}
      {(error || postsError) && <p className="form-error">{error ?? postsError}</p>}

      {profile && !editing && (
        <header className="profile-header">
          <div className="profile-header-main">
            <div className="profile-avatar">
              {avatarSrc ? (
                <img src={avatarSrc} alt="" />
              ) : (
                <span>{displayInitials(profile.displayName)}</span>
              )}
            </div>
            <div className="profile-info">
              <h1>{profile.displayName}</h1>
              <p className="profile-username">@{profile.username}</p>
              <p className="profile-meta">
                {profile.postCount} {profile.postCount === 1 ? 'post' : 'posts'}
                {profile.blocked && (
                  <>
                    {' '}
                    · <span className="status-badge blocked">Blocked</span>
                  </>
                )}
              </p>
            </div>
          </div>
          <div className="profile-actions">
            {isOwnProfile && (
              <button type="button" className="btn ghost" onClick={startEditing}>
                Edit profile
              </button>
            )}
            {canFollow && (
              <button
                type="button"
                className={`btn ${profile.subscribed ? 'ghost' : 'primary'}`}
                disabled={pendingFollow}
                onClick={toggleFollow}
              >
                {pendingFollow ? '…' : profile.subscribed ? 'Unfollow' : 'Follow'}
              </button>
            )}
            {canBlockProfile && (
              <button
                type="button"
                className={`btn ghost ${profile.blocked ? '' : 'danger-text'}`}
                disabled={blockingUser}
                onClick={() => {
                  void handleBlockUser()
                }}
              >
                {blockingUser ? '…' : profile.blocked ? 'Unblock user' : 'Block user'}
              </button>
            )}
          </div>
        </header>
      )}

      {profile && editing && isOwnProfile && (
        <form className="profile-edit" onSubmit={handleSaveProfile}>
          <h2>Edit profile</h2>
          <div className="profile-edit-avatar">
            <div className="profile-avatar">
              {avatarSrc ? (
                <img src={avatarSrc} alt="" />
              ) : (
                <span>{displayInitials(displayName)}</span>
              )}
            </div>
            <label className="btn ghost small">
              Change avatar
              <span className="field-hint">Max {MAX_IMAGE_MB} MB</span>
              <input
                type="file"
                accept="image/*"
                hidden
                onChange={(e) => {
                  handleAvatarPick(e.target.files?.[0] ?? null)
                  e.target.value = ''
                }}
              />
            </label>
          </div>
          <label>
            Display name
            <input
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              minLength={API_CONSTRAINTS.displayName.min}
              maxLength={API_CONSTRAINTS.displayName.max}
              required
            />
          </label>
          <label>
            Email
            <input type="email" value={user?.email ?? ''} disabled readOnly />
          </label>
          <p className="profile-edit-note">Email cannot be changed after registration.</p>
          <p className="profile-edit-note">Username @{profile.username} cannot be changed.</p>
          <div className="profile-edit-actions">
            <button type="button" className="btn ghost" onClick={() => setEditing(false)}>
              Cancel
            </button>
            <button type="submit" className="btn primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save changes'}
            </button>
          </div>
        </form>
      )}

      {isOwnProfile && hiddenPostCount > 0 && !loading && !postsLoading && (
        <div className="profile-moderation-alert">
          <button
            type="button"
            className="profile-moderation-alert-toggle"
            aria-expanded={profileAlertExpanded}
            onClick={() => setProfileAlertExpanded((current) => !current)}
          >
            <span className="profile-moderation-alert-icon" aria-hidden="true">
              ⚠
            </span>
            <span className="profile-moderation-alert-summary">
              {hiddenPostCount === 1
                ? '1 post hidden from public feeds'
                : `${hiddenPostCount} posts hidden from public feeds`}
            </span>
            <span className="profile-moderation-alert-chevron" aria-hidden="true">
              {profileAlertExpanded ? '▾' : '▸'}
            </span>
          </button>
          {profileAlertExpanded && (
            <div className="profile-moderation-alert-details">
              <p>
                These posts were removed by moderation. You can still view them below, edit, or
                delete them.
              </p>
              <Link to="/notifications" className="profile-moderation-alert-link">
                View in notifications →
              </Link>
            </div>
          )}
        </div>
      )}

      {!loading && !postsLoading && !error && !postsError && posts.length === 0 && (
        <div className="empty-feed">
          <p>{isOwnProfile ? "You haven't posted yet." : 'No public posts yet.'}</p>
          {canPost && (
            <Link to="/post/new" className="btn primary">
              Rate your first steak
            </Link>
          )}
        </div>
      )}

      <div className="post-grid">
        {posts.map((post) => {
          const menuItems = buildPostMenuItems(post)
          const useInteractiveCard = menuItems.length > 0 || (isOwnProfile && post.hidden)

          if (useInteractiveCard) {
            return (
              <article
                key={post.id}
                className={`post-card ${isOwnProfile && post.hidden ? 'post-card--moderated' : ''}`}
              >
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
                      </div>
                    </button>
                  </div>
                  {menuItems.length > 0 && (
                    <PostCardMenu label={`Actions for ${post.title}`} items={menuItems} />
                  )}
                </div>
                <div className="post-body">
                  {isOwnProfile && post.hidden && (
                    <AuthorPostModerationNotice
                      reason={post.moderationReason}
                      variant="card"
                    />
                  )}
                  <div className="post-meta">
                    <time>{new Date(post.createdAt).toLocaleDateString()}</time>
                  </div>
                  <Link
                    to={`/posts/${post.id}`}
                    state={listItemBackState(`/users/${userId}`, 'Back to profile')}
                    className="post-title-link"
                  >
                    <h2>{post.title}</h2>
                  </Link>
                  <StarRating value={post.rating} readOnly />
                  <ReviewTagChips tags={post.tags ?? []} compact />
                  {post.restaurantName && (
                    <p className="post-restaurant">{post.restaurantName}</p>
                  )}
                </div>
              </article>
            )
          }

          return (
            <article key={post.id} className="post-card">
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
                  <img src={postImageUrl(primaryPostImage(post))} alt={post.title} loading="lazy" />
                  {post.imageUrls.length > 1 && (
                    <span className="photo-count">+{post.imageUrls.length - 1}</span>
                  )}
                </div>
              </button>
              <div className="post-body">
                <div className="post-meta">
                  <time>{new Date(post.createdAt).toLocaleDateString()}</time>
                </div>
                <Link
                  to={`/posts/${post.id}`}
                  state={listItemBackState(`/users/${userId}`, 'Back to profile')}
                  className="post-title-link"
                >
                  <h2>{post.title}</h2>
                </Link>
                <StarRating value={post.rating} readOnly />
                <ReviewTagChips tags={post.tags ?? []} compact />
                {post.restaurantName && (
                  <p className="post-restaurant">{post.restaurantName}</p>
                )}
              </div>
            </article>
          )
        })}
      </div>

      {postsLoading && !loading && <p className="muted">Loading posts…</p>}

      {postsHasMore && !postsLoading && (
        <div ref={postsSentinelRef} className="infinite-scroll-sentinel">
          {postsLoadingMore && <p className="muted">Loading more posts…</p>}
        </div>
      )}

      {cropImageSrc && (
        <AvatarCropModal
          imageSrc={cropImageSrc}
          onCancel={handleCropCancel}
          onComplete={handleCropComplete}
        />
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
          void confirmDeletePost()
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
