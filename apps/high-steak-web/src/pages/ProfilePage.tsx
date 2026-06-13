import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  fetchUserPosts,
  fetchUserProfile,
  postImageUrl,
  primaryPostImage,
  subscribeToUser,
  unsubscribeFromUser,
  updateProfile,
  type SteakPost,
  type UserPublicProfile,
} from '../api/client'
import { AvatarCropModal } from '../components/AvatarCropModal'
import { PageBackLink } from '../components/BackLink'
import { StarRating } from '../components/StarRating'
import { ReviewTagChips } from '../components/ReviewTagChips'
import { useAuth } from '../context/AuthContext'
import { listItemBackState } from '../navigation'
import { displayInitials } from '../utils/displayInitials'
import { validateImageFile, validateProfileForm } from '../utils/validation'
import { API_CONSTRAINTS, MAX_IMAGE_MB } from '../api/constraints'
import './ProfilePage.css'

export function ProfilePage() {
  const { userId } = useParams<{ userId: string }>()
  const { user, token, isAuthenticated, hasScope, applyToken } = useAuth()
  const [profile, setProfile] = useState<UserPublicProfile | null>(null)
  const [posts, setPosts] = useState<SteakPost[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [pendingFollow, setPendingFollow] = useState(false)
  const [editing, setEditing] = useState(false)
  const [displayName, setDisplayName] = useState('')
  const [email, setEmail] = useState('')
  const [avatarFile, setAvatarFile] = useState<File | null>(null)
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null)
  const [cropImageSrc, setCropImageSrc] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const isOwnProfile = isAuthenticated && user?.id === userId
  const canFollow = isAuthenticated && hasScope('subscriptions:write') && !isOwnProfile
  const canPost = isOwnProfile && hasScope('posts:write')

  useEffect(() => {
    if (!userId || !token) return
    setLoading(true)
    setError(null)
    Promise.all([fetchUserProfile(userId, token), fetchUserPosts(userId, token)])
      .then(([profileData, postsData]) => {
        setProfile(profileData)
        setPosts(postsData)
        setDisplayName(profileData.displayName)
        setEmail(user?.email ?? '')
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load profile'))
      .finally(() => setLoading(false))
  }, [userId, token, user?.email])

  useEffect(() => {
    if (isOwnProfile && user) {
      setEmail(user.email)
      setDisplayName(user.displayName)
    }
  }, [isOwnProfile, user])

  function startEditing() {
    if (!user) return
    setDisplayName(user.displayName)
    setEmail(user.email)
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
    const validationError = validateProfileForm({ displayName, email, avatar: avatarFile })
    if (validationError) {
      setError(validationError)
      return
    }
    setSaving(true)
    setError(null)
    try {
      const response = await updateProfile(token, {
        displayName,
        email,
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

  if (!userId) {
    return <p className="form-error">User not found.</p>
  }

  const avatarSrc = avatarPreview
    ?? (profile?.avatarUrl ? postImageUrl(profile.avatarUrl) : null)

  return (
    <section className="profile-page">
      <PageBackLink defaultTo="/feed" defaultLabel="Back to feed" />

      {loading && <p className="muted">Loading profile…</p>}
      {error && <p className="form-error">{error}</p>}

      {profile && !editing && (
        <header className="profile-header">
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
            </p>
          </div>
          <div className="profile-actions">
            {canPost && (
              <Link to="/post/new" className="btn primary">
                Rate a steak
              </Link>
            )}
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
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              maxLength={API_CONSTRAINTS.email.max}
              required
            />
          </label>
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

      {!loading && !error && posts.length === 0 && (
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
        {posts.map((post) => (
          <Link
            key={post.id}
            to={`/posts/${post.id}`}
            state={listItemBackState(`/users/${userId}`, 'Back to profile')}
            className="post-card post-card-link"
          >
            <div className="post-image-wrap">
              <img src={postImageUrl(primaryPostImage(post))} alt={post.title} loading="lazy" />
            </div>
            <div className="post-body">
              <div className="post-meta">
                <time>{new Date(post.createdAt).toLocaleDateString()}</time>
              </div>
              <h2>{post.title}</h2>
              <StarRating value={post.rating} readOnly />
              <ReviewTagChips tags={post.tags ?? []} compact />
              {post.restaurantName && (
                <p className="post-restaurant">{post.restaurantName}</p>
              )}
            </div>
          </Link>
        ))}
      </div>

      {cropImageSrc && (
        <AvatarCropModal
          imageSrc={cropImageSrc}
          onCancel={handleCropCancel}
          onComplete={handleCropComplete}
        />
      )}
    </section>
  )
}
