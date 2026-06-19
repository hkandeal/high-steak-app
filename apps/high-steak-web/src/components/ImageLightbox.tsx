import { useCallback, useEffect, useId, useRef, useState } from 'react'
import './ImageLightbox.css'

export type ImageLightboxState = {
  images: string[]
  index: number
  alt?: string
}

type ImageLightboxProps = {
  open: boolean
  images: string[]
  initialIndex?: number
  alt?: string
  onClose: () => void
}

export function ImageLightbox({
  open,
  images,
  initialIndex = 0,
  alt = 'Post photo',
  onClose,
}: ImageLightboxProps) {
  const titleId = useId()
  const closeRef = useRef<HTMLButtonElement>(null)
  const [index, setIndex] = useState(initialIndex)
  const touchStartX = useRef<number | null>(null)

  const hasMultiple = images.length > 1
  const currentSrc = images[index] ?? ''

  const goPrev = useCallback(() => {
    if (!hasMultiple) return
    setIndex((current) => (current - 1 + images.length) % images.length)
  }, [hasMultiple, images.length])

  const goNext = useCallback(() => {
    if (!hasMultiple) return
    setIndex((current) => (current + 1) % images.length)
  }, [hasMultiple, images.length])

  useEffect(() => {
    if (!open) return
    setIndex(Math.min(Math.max(initialIndex, 0), Math.max(images.length - 1, 0)))
  }, [open, initialIndex, images.length])

  useEffect(() => {
    if (!open) return

    closeRef.current?.focus()
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose()
      } else if (event.key === 'ArrowLeft') {
        goPrev()
      } else if (event.key === 'ArrowRight') {
        goNext()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      document.body.style.overflow = previousOverflow
    }
  }, [open, onClose, goPrev, goNext])

  if (!open || images.length === 0) return null

  return (
    <div className="image-lightbox-backdrop" onClick={onClose}>
      <div
        className="image-lightbox"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
        onTouchStart={(event) => {
          touchStartX.current = event.changedTouches[0]?.clientX ?? null
        }}
        onTouchEnd={(event) => {
          if (touchStartX.current === null || !hasMultiple) return
          const delta = (event.changedTouches[0]?.clientX ?? 0) - touchStartX.current
          if (delta > 50) goPrev()
          else if (delta < -50) goNext()
          touchStartX.current = null
        }}
      >
        <div className="image-lightbox-toolbar">
          {hasMultiple && (
            <span id={titleId} className="image-lightbox-counter">
              {index + 1} / {images.length}
            </span>
          )}
          {!hasMultiple && <span id={titleId} className="sr-only">{alt}</span>}
          <button
            ref={closeRef}
            type="button"
            className="image-lightbox-close"
            onClick={onClose}
            aria-label="Close photo viewer"
          >
            ×
          </button>
        </div>

        <div className="image-lightbox-stage">
          {hasMultiple && (
            <button
              type="button"
              className="image-lightbox-nav image-lightbox-nav-prev"
              onClick={goPrev}
              aria-label="Previous photo"
            >
              ‹
            </button>
          )}

          <img
            key={currentSrc}
            src={currentSrc}
            alt={hasMultiple ? `${alt} (${index + 1} of ${images.length})` : alt}
            className="image-lightbox-image"
          />

          {hasMultiple && (
            <button
              type="button"
              className="image-lightbox-nav image-lightbox-nav-next"
              onClick={goNext}
              aria-label="Next photo"
            >
              ›
            </button>
          )}
        </div>

        {hasMultiple && (
          <div className="image-lightbox-dots" role="tablist" aria-label="Photo thumbnails">
            {images.map((url, dotIndex) => (
              <button
                key={`${url}-${dotIndex}`}
                type="button"
                role="tab"
                className={`image-lightbox-dot${dotIndex === index ? ' active' : ''}`}
                aria-label={`View photo ${dotIndex + 1}`}
                aria-selected={dotIndex === index}
                onClick={() => setIndex(dotIndex)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
