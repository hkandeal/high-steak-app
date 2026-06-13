import { useNavigate } from 'react-router-dom'
import { createPost } from '../api/client'
import { PostForm } from '../components/PostForm'
import { useAuth } from '../context/AuthContext'
import '../components/PostForm.css'

export function NewPostPage() {
  const { token } = useAuth()
  const navigate = useNavigate()

  return (
    <section className="post-editor-page">
      <header>
        <h1>Rate your steak</h1>
        <p>Upload photos, score the experience, and share where you ate.</p>
      </header>

      <PostForm
        mode="create"
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
            images: data.newImages,
            tagIds: data.tagIds,
          })
          navigate(`/posts/${post.id}`)
        }}
      />
    </section>
  )
}
