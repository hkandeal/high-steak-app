import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { createPost } from '../api/client'
import { StarRating } from '../components/StarRating'
import { useAuth } from '../context/AuthContext'
import './NewPostPage.css'

export function NewPostPage() {
  const { token } = useAuth()
  const navigate = useNavigate()
  const [title, setTitle] = useState('')
  const [comment, setComment] = useState('')
  const [rating, setRating] = useState(5)
  const [image, setImage] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  function handleImageChange(file: File | null) {
    setImage(file)
    if (preview) URL.revokeObjectURL(preview)
    setPreview(file ? URL.createObjectURL(file) : null)
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!token || !image) return
    setLoading(true)
    setError(null)
    try {
      await createPost(token, { title, comment, rating, image })
      navigate('/feed')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create post')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="new-post-page">
      <header>
        <h1>Rate your steak</h1>
        <p>Upload a photo, score the experience, and share the details.</p>
      </header>

      <form className="new-post-form" onSubmit={handleSubmit}>
        <div className="upload-zone">
          {preview ? (
            <img src={preview} alt="Preview" className="preview-image" />
          ) : (
            <div className="upload-placeholder">
              <span>📷</span>
              <p>Drop your steak photo here</p>
            </div>
          )}
          <label className="upload-btn">
            Choose photo
            <input
              type="file"
              accept="image/*"
              hidden
              onChange={(e) => handleImageChange(e.target.files?.[0] ?? null)}
              required
            />
          </label>
        </div>

        <div className="form-fields">
          <label>
            Title
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Ribeye night"
              required
            />
          </label>

          <div>
            <span className="field-label">Your rating</span>
            <StarRating value={rating} onChange={setRating} />
          </div>

          <label>
            Comment
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              rows={4}
              placeholder="Cut, seasoning, grill temp, doneness…"
            />
          </label>
        </div>

        {error && <p className="form-error">{error}</p>}

        <button type="submit" className="btn primary full" disabled={loading || !image}>
          {loading ? 'Posting…' : 'Share to feed'}
        </button>
      </form>
    </section>
  )
}
