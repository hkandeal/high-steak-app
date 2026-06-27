import { useCallback, useEffect, useRef, useState } from 'react'
import { useBlocker, useNavigate, useParams } from 'react-router-dom'
import { fetchPost, updatePost, type PlaceSummary, type PostVisibility } from '../api/client'
import { PageBackLink } from '../components/BackLink'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { PostForm, type PostFormHandle, type PostFormSubmitData } from '../components/PostForm'
import { useAuth } from '../context/AuthContext'
import '../components/PostForm.css'

export function EditPostPage() {
  const { postId } = useParams<{ postId: string }>()
  const { token, user } = useAuth()
  const navigate = useNavigate()
  const formRef = useRef<PostFormHandle>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notAllowed, setNotAllowed] = useState(false)
  const [isDirty, setIsDirty] = useState(false)
  const [leaveDialogOpen, setLeaveDialogOpen] = useState(false)
  const [savingLeave, setSavingLeave] = useState(false)
  const [initial, setInitial] = useState<{
    title: string
    comment: string
    rating: number
    restaurantName: string
    restaurantLocation: string
    place: PlaceSummary | null
    tagIds: string[]
    imageUrls: string[]
    visibility: PostVisibility
  } | null>(null)

  const shouldBlockLeave = useCallback(() => isDirty, [isDirty])

  const blocker = useBlocker(shouldBlockLeave)

  useEffect(() => {
    if (blocker.state === 'blocked') {
      setLeaveDialogOpen(true)
    }
  }, [blocker.state])

  useEffect(() => {
    if (!isDirty) return

    function handleBeforeUnload(event: BeforeUnloadEvent) {
      event.preventDefault()
      event.returnValue = ''
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  useEffect(() => {
    if (!postId || !token) return
    setLoading(true)
    setError(null)
    fetchPost(postId, token)
      .then((post) => {
        if (user?.id !== post.author.id) {
          setNotAllowed(true)
          return
        }
        setInitial({
          title: post.title,
          comment: post.comment ?? '',
          rating: post.rating,
          restaurantName: post.restaurantName ?? '',
          restaurantLocation: post.restaurantLocation ?? '',
          place: post.place,
          tagIds: (post.tags ?? []).map((tag) => tag.id),
          imageUrls: [...new Set(post.imageUrls)],
          visibility: post.visibility ?? 'PUBLIC',
        })
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load post'))
      .finally(() => setLoading(false))
  }, [postId, token, user?.id])

  async function savePost(data: PostFormSubmitData) {
    if (!token || !postId) return
    await updatePost(token, postId, {
      title: data.title,
      comment: data.comment,
      rating: data.rating,
      restaurantName: data.restaurantName,
      restaurantLocation: data.restaurantLocation,
      placeId: data.placeId,
      visibility: data.visibility,
      keepImageUrls: data.keepImageUrls,
      newImages: data.newImages,
      tagIds: data.tagIds,
    })
  }

  function handleLeaveCancel() {
    setLeaveDialogOpen(false)
    if (blocker.state === 'blocked') {
      blocker.reset()
    }
  }

  function handleLeaveConfirm() {
    setLeaveDialogOpen(false)
    setIsDirty(false)
    if (blocker.state === 'blocked') {
      blocker.proceed()
    }
  }

  async function handleSaveAndLeave() {
    setSavingLeave(true)
    try {
      const saved = await formRef.current?.submit()
      if (!saved) return
      setLeaveDialogOpen(false)
      setIsDirty(false)
      if (blocker.state === 'blocked') {
        blocker.proceed()
      }
    } finally {
      setSavingLeave(false)
    }
  }

  if (!postId) {
    return <p className="form-error">Post not found.</p>
  }

  return (
    <section className="post-editor-page">
      <PageBackLink defaultTo={`/posts/${postId}`} defaultLabel="Back to post" />

      <header>
        <h1>Edit your post</h1>
        <p>Update your rating, tags, photos, and notes.</p>
      </header>

      {loading && <p className="muted">Loading post…</p>}
      {error && <p className="form-error">{error}</p>}
      {notAllowed && <p className="form-error">You can only edit your own posts.</p>}

      {initial && !notAllowed && (
        <PostForm
          ref={formRef}
          mode="edit"
          initialTitle={initial.title}
          initialComment={initial.comment}
          initialRating={initial.rating}
          initialRestaurantName={initial.restaurantName}
          initialRestaurantLocation={initial.restaurantLocation}
          initialPlace={initial.place}
          initialTagIds={initial.tagIds}
          initialImageUrls={initial.imageUrls}
          initialVisibility={initial.visibility}
          submitLabel="Save changes"
          pendingLabel="Saving…"
          onDirtyChange={setIsDirty}
          onSubmit={savePost}
          onComplete={() => navigate(`/posts/${postId}`)}
        />
      )}

      <ConfirmDialog
        open={leaveDialogOpen}
        title="Unsaved changes"
        message="You have edits that aren't saved yet. Save before leaving, or discard them?"
        confirmLabel="Discard & leave"
        cancelLabel="Keep editing"
        secondaryLabel="Save changes"
        secondaryLoading={savingLeave}
        variant="danger"
        onConfirm={handleLeaveConfirm}
        onCancel={handleLeaveCancel}
        onSecondary={() => {
          void handleSaveAndLeave()
        }}
      />
    </section>
  )
}
