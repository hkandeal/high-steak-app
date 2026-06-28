import { forwardRef, useEffect, useImperativeHandle, useMemo, useState, type FormEvent } from 'react'
import { postImageUrl, type PostVisibility } from '../api/client'
import { API_CONSTRAINTS, MAX_IMAGE_MB } from '../api/constraints'
import { validateImageFiles, validatePostForm, isUploadRelatedError } from '../utils/validation'
import { ImageLightbox } from './ImageLightbox'
import { PhotoGallery } from './PhotoGallery'
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
  imageOrder?: string[]
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

type FormImage =
  | { id: string; kind: 'existing'; url: string }
  | { id: string; kind: 'new'; file: File; preview: string }

let formImageIdCounter = 0

function nextFormImageId() {
  formImageIdCounter += 1
  return `form-image-${formImageIdCounter}`
}

function imagesFromUrls(urls: string[]): FormImage[] {
  return urls.map((url) => ({ id: nextFormImageId(), kind: 'existing', url }))
}

function tagIdsEqual(a: string[], b: string[]) {
  if (a.length !== b.length) return false
  const left = [...a].sort()
  const right = [...b].sort()
  return left.every((value, index) => value === right[index])
}

function partitionFormImages(images: FormImage[]) {
  const keepImageUrls: string[] = []
  const newImages: File[] = []
  const imageOrder: string[] = []
  for (const image of images) {
    if (image.kind === 'existing') {
      keepImageUrls.push(image.url)
      imageOrder.push(image.url)
    } else {
      const index = newImages.length
      newImages.push(image.file)
      imageOrder.push(`__new__:${index}`)
    }
  }
  return { keepImageUrls, newImages, imageOrder }
}

function formImagesDirty(images: FormImage[], initialUrls: string[]) {
  if (images.some((image) => image.kind === 'new')) return true
  if (images.length !== initialUrls.length) return true
  return images.some(
    (image, index) => image.kind !== 'existing' || image.url !== initialUrls[index],
  )
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
  const [formImages, setFormImages] = useState<FormImage[]>(() => imagesFromUrls(initialImageUrls))
  const [activeGalleryIndex, setActiveGalleryIndex] = useState(0)
  const [uploadError, setUploadError] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null)

  const totalImages = formImages.length
  const previewImages = useMemo(
    () =>
      formImages.map((image) =>
        image.kind === 'existing' ? postImageUrl(image.url) : image.preview,
      ),
    [formImages],
  )

  const { keepImageUrls, newImages, imageOrder } = useMemo(
    () => partitionFormImages(formImages),
    [formImages],
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
    mode === 'edit'
      ? title !== initialTitle ||
        comment !== initialComment ||
        rating !== initialRating ||
        restaurantName !== initialRestaurantName ||
        restaurantLocation !== initialRestaurantLocation ||
        selectedPlace?.id !== initialPlace?.id ||
        visibility !== initialVisibility ||
        !tagIdsEqual(selectedTagIds, initialTagIds) ||
        formImagesDirty(formImages, initialImageUrls)
      : title.trim() !== '' ||
        comment.trim() !== '' ||
        rating !== initialRating ||
        selectedPlace?.id !== (initialPlace?.id ?? null) ||
        (!selectedPlace &&
          (restaurantName.trim() !== '' || restaurantLocation.trim() !== '')) ||
        visibility !== initialVisibility ||
        selectedTagIds.length > 0 ||
        formImages.length > 0

  useEffect(() => {
    onDirtyChange?.(isDirty)
  }, [isDirty, onDirtyChange])

  useEffect(() => {
    if (!initialPlace) return
    setSelectedPlace(initialPlace)
    setRestaurantName(initialPlace.name)
    setRestaurantLocation(initialPlace.formattedAddress ?? '')
  }, [initialPlace])

  useEffect(() => {
    if (activeGalleryIndex < formImages.length) return
    setActiveGalleryIndex(Math.max(0, formImages.length - 1))
  }, [activeGalleryIndex, formImages.length])

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
      imageOrder: mode === 'edit' ? imageOrder : undefined,
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
    const added: FormImage[] = picked.map((file) => ({
      id: nextFormImageId(),
      kind: 'new',
      file,
      preview: URL.createObjectURL(file),
    }))
    setFormImages((current) => {
      setActiveGalleryIndex(current.length)
      return [...current, ...added]
    })
  }

  function removeImage(index: number) {
    setFormImages((current) => {
      const target = current[index]
      if (target?.kind === 'new') {
        URL.revokeObjectURL(target.preview)
      }
      return current.filter((_, itemIndex) => itemIndex !== index)
    })
    setActiveGalleryIndex((current) => Math.max(0, current - (index <= current ? 1 : 0)))
  }

  function setAsCover(index: number) {
    if (index === 0) return
    setFormImages((current) => {
      const next = [...current]
      const [item] = next.splice(index, 1)
      next.unshift(item)
      return next
    })
    setActiveGalleryIndex(0)
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    await save(true)
  }

  return (
    <form className="post-form" onSubmit={handleSubmit}>
      <div className={`upload-zone${uploadError ? ' upload-zone-error' : ''}`}>
        {totalImages > 0 ? (
          <div className="upload-gallery">
            <PhotoGallery
              images={previewImages}
              activeIndex={activeGalleryIndex}
              onActiveIndexChange={setActiveGalleryIndex}
              alt="Post photo preview"
              onZoom={(index) => setLightboxIndex(index)}
              coverIndex={0}
              onSetCover={setAsCover}
              onRemove={removeImage}
            />
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
