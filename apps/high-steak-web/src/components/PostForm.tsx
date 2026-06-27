import { forwardRef, useEffect, useImperativeHandle, useMemo, useState, type FormEvent } from 'react'
import { postImageUrl, type PostVisibility } from '../api/client'
import { API_CONSTRAINTS, MAX_IMAGE_MB } from '../api/constraints'
import { validateImageFiles, validatePostForm, isUploadRelatedError } from '../utils/validation'
import { ImageLightbox } from './ImageLightbox'
import { ReviewTagPicker } from './ReviewTagPicker'
import { PlacePicker } from './PlacePicker'
import { StarRating } from './StarRating'
import type { PlaceSummary } from '../api/client'
import { VisibilityPicker } from './VisibilityPicker'
import './PostForm.css'

export type PostFormSubmitData = {
  title: string
  comment: string
  rating: number
  restaurantName?: string
  restaurantLocation?: string
  placeId?: string
  visibility: PostVisibility
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
  initialPlace?: PlaceSummary | null
  initialVisibility?: PostVisibility
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
    initialPlace = null,
    initialVisibility = 'PUBLIC',
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
  const [selectedPlace, setSelectedPlace] = useState<PlaceSummary | null>(initialPlace)
  const [visibility, setVisibility] = useState<PostVisibility>(initialVisibility)
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>(initialTagIds)
  const [keepImageUrls, setKeepImageUrls] = useState<string[]>(initialImageUrls)
  const [newImages, setNewImages] = useState<File[]>([])
  const [newPreviews, setNewPreviews] = useState<string[]>([])
  const [uploadError, setUploadError] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null)

  const totalImages = keepImageUrls.length + newImages.length
  const previewImages = useMemo(
    () => [...keepImageUrls.map((url) => postImageUrl(url)), ...newPreviews],
    [keepImageUrls, newPreviews],
  )

  function setFormErrors(message: string | null) {
    if (!message) {
      setUploadError(null)
      setFormError(null)
      return
    }
    if (isUploadRelatedError(message)) {
      setUploadError(message)
      setFormError(null)
    } else {
      setFormError(message)
      setUploadError(null)
    }
  }

  const isDirty =
    mode === 'edit' &&
    (title !== initialTitle ||
      comment !== initialComment ||
      rating !== initialRating ||
      restaurantName !== initialRestaurantName ||
      restaurantLocation !== initialRestaurantLocation ||
      selectedPlace?.id !== initialPlace?.id ||
      visibility !== initialVisibility ||
      !tagIdsEqual(selectedTagIds, initialTagIds) ||
      !urlsEqual(keepImageUrls, initialImageUrls) ||
      newImages.length > 0)

  useEffect(() => {
    onDirtyChange?.(isDirty)
  }, [isDirty, onDirtyChange])

  useEffect(() => {
    if (!initialPlace) return
    setSelectedPlace(initialPlace)
    setRestaurantName(initialPlace.name)
    setRestaurantLocation(initialPlace.formattedAddress ?? '')
  }, [initialPlace])

  function buildSubmitData(): PostFormSubmitData | null {
    if (totalImages === 0) return null
    return {
      title,
      comment,
      rating,
      restaurantName: selectedPlace ? selectedPlace.name : restaurantName || undefined,
      restaurantLocation: selectedPlace
        ? selectedPlace.formattedAddress ?? undefined
        : restaurantLocation || undefined,
      placeId: selectedPlace?.id,
      visibility,
      tagIds: selectedTagIds,
      newImages,
      keepImageUrls,
    }
  }

  async function save(runComplete: boolean): Promise<boolean> {
    const data = buildSubmitData()
    if (!data) return false

    const validationError = validatePostForm({
      title,
      comment,
      restaurantName,
      restaurantLocation,
      newImages,
      totalImages,
    })
    if (validationError) {
      setFormErrors(validationError)
      return false
    }

    setLoading(true)
    setFormErrors(null)
    try {
      await onSubmit(data)
      onDirtyChange?.(false)
      if (runComplete) onComplete?.()
      return true
    } catch (err) {
      setFormErrors(err instanceof Error ? err.message : 'Failed to save post')
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
    const imageError = validateImageFiles(picked)
    if (imageError) {
      setFormErrors(imageError)
      return
    }
    setFormErrors(null)
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
      <div className={`upload-zone${uploadError ? ' upload-zone-error' : ''}`}>
        {totalImages > 0 ? (
          <div className="preview-grid">
            {keepImageUrls.map((url, index) => (
              <div key={url} className="preview-item">
                <button
                  type="button"
                  className="preview-image-button"
                  onClick={() => setLightboxIndex(index)}
                  aria-label={`View photo ${index + 1} full size`}
                >
                  <img src={postImageUrl(url)} alt="" className="preview-image" />
                </button>
                <button type="button" className="preview-remove" onClick={() => removeExistingImage(url)}>
                  Remove
                </button>
              </div>
            ))}
            {newPreviews.map((preview, index) => (
              <div key={preview} className="preview-item">
                <button
                  type="button"
                  className="preview-image-button"
                  onClick={() => setLightboxIndex(keepImageUrls.length + index)}
                  aria-label={`View photo ${keepImageUrls.length + index + 1} full size`}
                >
                  <img src={preview} alt="" className="preview-image" />
                </button>
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
        <div className="upload-footer">
          <p className="upload-hint">JPEG, PNG, or WebP · max {MAX_IMAGE_MB} MB each</p>
          <label className="upload-btn">
            {totalImages > 0 ? 'Add more' : 'Choose photos'}
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
        {uploadError && <p className="upload-error">{uploadError}</p>}
      </div>

      <div className="form-fields">
        <label>
          Title
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Ribeye night"
            minLength={API_CONSTRAINTS.postTitle.min}
            maxLength={API_CONSTRAINTS.postTitle.max}
            required
          />
        </label>

        <section className="post-form-map-search" aria-labelledby="post-map-search-heading">
          <div className="post-form-map-search-header">
            <span className="post-form-map-search-icon" aria-hidden="true">
              🗺
            </span>
            <div>
              <h2 id="post-map-search-heading">Restaurant on the map</h2>
              <p>Search Google Maps to tag where you ate.</p>
            </div>
          </div>
          <PlacePicker
            value={selectedPlace}
            onChange={(place) => {
              setSelectedPlace(place)
              if (place) {
                setRestaurantName(place.name)
                setRestaurantLocation(place.formattedAddress ?? '')
              }
            }}
            disabled={loading}
            hideLabel
            label="Restaurant on the map"
            placeholder="Search restaurants on the map…"
          />
        </section>

        <div>
          <span className="field-label">Your rating</span>
          <StarRating value={rating} onChange={setRating} />
        </div>

        <ReviewTagPicker selectedIds={selectedTagIds} onChange={setSelectedTagIds} />

        {!selectedPlace && (
          <>
            <label>
              Restaurant name
              <input
                value={restaurantName}
                onChange={(e) => setRestaurantName(e.target.value)}
                placeholder="e.g. The Prime Cut"
                maxLength={API_CONSTRAINTS.restaurantName.max}
              />
            </label>

            <label>
              Location
              <input
                value={restaurantLocation}
                onChange={(e) => setRestaurantLocation(e.target.value)}
                placeholder="e.g. Austin, TX"
                maxLength={API_CONSTRAINTS.restaurantLocation.max}
              />
            </label>
          </>
        )}

        <label>
          Comment
          <textarea
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            rows={4}
            placeholder="Cut, seasoning, grill temp, doneness…"
            maxLength={API_CONSTRAINTS.postComment.max}
          />
        </label>

        <VisibilityPicker value={visibility} onChange={setVisibility} />
      </div>

      {formError && <p className="form-error">{formError}</p>}

      <button type="submit" className="btn primary full" disabled={loading || totalImages === 0}>
        {loading ? pendingLabel : submitLabel}
      </button>

      <ImageLightbox
        open={lightboxIndex !== null}
        images={previewImages}
        initialIndex={lightboxIndex ?? 0}
        alt="Post photo preview"
        onClose={() => setLightboxIndex(null)}
      />
    </form>
  )
})
