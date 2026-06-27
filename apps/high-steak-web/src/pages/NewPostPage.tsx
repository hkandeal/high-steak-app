import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { createPost, fetchPlace, type PlaceSummary } from '../api/client'
import { PostForm } from '../components/PostForm'
import { useAuth } from '../context/AuthContext'
import '../components/PostForm.css'

export function NewPostPage() {
  const { token } = useAuth()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const placeId = searchParams.get('placeId')
  const [initialPlace, setInitialPlace] = useState<PlaceSummary | null>(null)

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
      <header>
        <h1>Rate your steak</h1>
        <p>Upload photos, score the experience, and share where you ate.</p>
      </header>

      <PostForm
        mode="create"
        initialPlace={initialPlace}
        submitLabel="Share to feed"
        pendingLabel="Posting…"
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
          navigate(`/posts/${post.id}`)
        }}
      />
    </section>
  )
}
