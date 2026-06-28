import { useEffect, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { createPost, fetchPlace, type PlaceSummary } from '../api/client'
import { PageBackLink } from '../components/BackLink'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { PostForm, type PostFormHandle } from '../components/PostForm'
import { useAuth } from '../context/AuthContext'
import { usePostEditorLeaveGuard } from '../hooks/usePostEditorLeaveGuard'
import '../components/PostForm.css'

export function NewPostPage() {
  const { token } = useAuth()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const placeId = searchParams.get('placeId')
  const formRef = useRef<PostFormHandle>(null)
  const createdPostIdRef = useRef<string | null>(null)
  const [initialPlace, setInitialPlace] = useState<PlaceSummary | null>(null)
  const [isDirty, setIsDirty] = useState(false)
  const {
    leaveDialogOpen,
    savingLeave,
    permitLeave,
    handleLeaveCancel,
    handleLeaveConfirm,
    handleSaveAndLeave,
  } = usePostEditorLeaveGuard(isDirty, formRef)

  useEffect(() => {
    if (!placeId || !token) {
      setInitialPlace(null)
      return
    }
    let cancelled = false
    void fetchPlace(token, placeId)
      .then((place) => {
        if (!cancelled) setInitialPlace(place)
      })
      .catch(() => {
        if (!cancelled) setInitialPlace(null)
      })
    return () => {
      cancelled = true
    }
  }, [placeId, token])

  return (
    <section className="post-editor-page">
      <PageBackLink defaultTo="/feed" defaultLabel="Back to feed" />

      <header>
        <h1>Rate your steak</h1>
        <p>Upload photos, score the experience, and share where you ate.</p>
      </header>

      <PostForm
        ref={formRef}
        mode="create"
        initialPlace={initialPlace}
        submitLabel="Share to feed"
        pendingLabel="Posting…"
        onDirtyChange={setIsDirty}
        onSubmit={async (data) => {
          if (!token) return
          const post = await createPost(token, {
            title: data.title,
            comment: data.comment,
            rating: data.rating,
            restaurantName: data.restaurantName,
            restaurantLocation: data.restaurantLocation,
            placeId: data.placeId,
            visibility: data.visibility,
            images: data.newImages,
            tagIds: data.tagIds,
          })
          createdPostIdRef.current = post.id
        }}
        onComplete={() => {
          if (!createdPostIdRef.current) return
          permitLeave()
          navigate(`/posts/${createdPostIdRef.current}`)
        }}
      />

      <ConfirmDialog
        open={leaveDialogOpen}
        title="Unsaved changes"
        message="You have a draft that isn't saved yet. Share it before leaving, or discard it?"
        confirmLabel="Discard & leave"
        cancelLabel="Keep editing"
        secondaryLabel="Share to feed"
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
