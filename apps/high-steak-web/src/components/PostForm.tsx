import { forwardRef, useEffect, useImperativeHandle, useState, type FormEvent } from 'react'
import { postImageUrl } from '../api/client'
import { ReviewTagPicker } from './ReviewTagPicker'
import { StarRating } from './StarRating'
import './PostForm.css'

export type PostFormSubmitData = {
  title: string
  comment: string
  rating: number
  restaurantName?: string
  restaurantLocation?: string
  tagIds: string[]
  newImages: File[]
  keepImageUrls: string[]
}

export type PostFormHandle = {
  submit: () => Promise<boolean>
}

type PostFormProps = {
  mode: 'create' | 'edit'
  initialTitle?: string
  initialComment?: string
  initialRating?: number
  initialRestaurantName?: string
  initialRestaurantLocation?: string
  initialTagIds?: string[]
  initialImageUrls?: string[]
  submitLabel: string
  pendingLabel: string
  onSubmit: (data: PostFormSubmitData) => Promise<void>
  onComplete?: () => void
  onDirtyChange?: (dirty: boolean) => void
}

function tagIdsEqual(a: string[], b: string[]) {
  if (a.length !== b.length) return false
  const left = [...a].sort()
  const right = [...b].sort()
  return left.every((value, index) => value === right[index])
}

function urlsEqual(a: string[], b: string[]) {
  return a.length === b.length && a.every((value, index) => value === b[index])
}

export const PostForm = forwardRef<PostFormHandle, PostFormProps>(function PostForm(
  {
    mode,
    initialTitle = '',
    initialComment = '',
    initialRating = 5,
    initialRestaurantName = '',
    initialRestaurantLocation = '',
    initialTagIds = [],
    initialImageUrls = [],
    submitLabel,
    pendingLabel,
    onSubmit,
    onComplete,
    onDirtyChange,
  },
  ref,
) {
  const [title, setTitle] = useState(initialTitle)
  const [comment, setComment] = useState(initialComment)
  const [rating, setRating] = useState(initialRating)
  const [restaurantName, setRestaurantName] = useState(initialRestaurantName)
  const [restaurantLocation, setRestaurantLocation] = useState(initialRestaurantLocation)
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>(initialTagIds)
  const [keepImageUrls, setKeepImageUrls] = useState<string[]>(initialImageUrls)
  const [newImages, setNewImages] = useState<File[]>([])
  const [newPreviews, setNewPreviews] = useState<string[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const totalImages = keepImageUrls.length + newImages.length

  const isDirty =
    mode === 'edit' &&
    (title !== initialTitle ||
      comment !== initialComment ||
      rating !== initialRating ||
      restaurantName !== initialRestaurantName ||
      restaurantLocation !== initialRestaurantLocation ||
      !tagIdsEqual(selectedTagIds, initialTagIds) ||
      !urlsEqual(keepImageUrls, initialImageUrls) ||
      newImages.length > 0)

  useEffect(() => {
    onDirtyChange?.(isDirty)
  }, [isDirty, onDirtyChange])

  function buildSubmitData(): PostFormSubmitData | null {
    if (totalImages === 0) return null
    return {
      title,
      comment,
      rating,
      restaurantName: restaurantName || undefined,
      restaurantLocation: restaurantLocation || undefined,
      tagIds: selectedTagIds,
      newImages,
      keepImageUrls,
    }
  }

  async function save(runComplete: boolean): Promise<boolean> {
    const data = buildSubmitData()
    if (!data) return false
    setLoading(true)
    setError(null)
    try {
      await onSubmit(data)
      onDirtyChange?.(false)
      if (runComplete) onComplete?.()
      return true
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save post')
      return false
    } finally {
      setLoading(false)
    }
  }

  useImperativeHandle(ref, () => ({
    submit: () => save(false),
  }))

  function handleNewImagesChange(files: FileList | null) {
    if (!files?.length) return
    const picked = Array.from(files)
    setNewImages((current) => [...current, ...picked])
    setNewPreviews((current) => [...current, ...picked.map((file) => URL.createObjectURL(file))])
  }

  function removeExistingImage(url: string) {
    setKeepImageUrls((current) => current.filter((item) => item !== url))
  }

  function removeNewImage(index: number) {
    URL.revokeObjectURL(newPreviews[index])
    setNewImages((current) => current.filter((_, i) => i !== index))
    setNewPreviews((current) => current.filter((_, i) => i !== index))
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    await save(true)
  }

  return (
    <form className="post-form" onSubmit={handleSubmit}>
      <div className="upload-zone">
        {totalImages > 0 ? (
          <div className="preview-grid">
            {keepImageUrls.map((url) => (
              <div key={url} className="preview-item">
                <img src={postImageUrl(url)} alt="" className="preview-image" />
                <button type="button" className="preview-remove" onClick={() => removeExistingImage(url)}>
                  Remove
                </button>
              </div>
            ))}
            {newPreviews.map((preview, index) => (
              <div key={preview} className="preview-item">
                <img src={preview} alt="" className="preview-image" />
                <button type="button" className="preview-remove" onClick={() => removeNewImage(index)}>
                  Remove
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="upload-placeholder">
            <span>📷</span>
            <p>{mode === 'create' ? 'Add one or more steak photos' : 'Keep at least one photo on your post'}</p>
          </div>
        )}
        <label className="upload-btn">
          {totalImages > 0 ? 'Add more photos' : 'Choose photos'}
          <input
            type="file"
            accept="image/*"
            multiple
            hidden
            onChange={(e) => {
              handleNewImagesChange(e.target.files)
              e.target.value = ''
            }}
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

        <ReviewTagPicker selectedIds={selectedTagIds} onChange={setSelectedTagIds} />

        <label>
          Restaurant
          <input
            value={restaurantName}
            onChange={(e) => setRestaurantName(e.target.value)}
            placeholder="e.g. The Prime Cut"
          />
        </label>

        <label>
          Location
          <input
            value={restaurantLocation}
            onChange={(e) => setRestaurantLocation(e.target.value)}
            placeholder="e.g. Austin, TX"
          />
        </label>

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

      <button type="submit" className="btn primary full" disabled={loading || totalImages === 0}>
        {loading ? pendingLabel : submitLabel}
      </button>
    </form>
  )
})
