import { useCallback, useEffect, useRef } from 'react'
import './PhotoGallery.css'

type PhotoGalleryProps = {
  images: string[]
  activeIndex: number
  onActiveIndexChange: (index: number) => void
  alt?: string
  onZoom?: (index: number) => void
  showCounter?: boolean
  coverIndex?: number
  onSetCover?: (index: number) => void
  onRemove?: (index: number) => void
}

export function PhotoGallery({
  images,
  activeIndex,
  onActiveIndexChange,
  alt = 'Photo',
  onZoom,
  showCounter = true,
  coverIndex = 0,
  onSetCover,
  onRemove,
}: PhotoGalleryProps) {
  const rootRef = useRef<HTMLDivElement>(null)
  const hasMultiple = images.length > 1
  const safeIndex = Math.min(Math.max(activeIndex, 0), Math.max(images.length - 1, 0))
  const currentSrc = images[safeIndex] ?? ''

  const goPrev = useCallback(() => {
    if (!hasMultiple) return
    onActiveIndexChange((safeIndex - 1 + images.length) % images.length)
  }, [hasMultiple, images.length, onActiveIndexChange, safeIndex])

  const goNext = useCallback(() => {
    if (!hasMultiple) return
    onActiveIndexChange((safeIndex + 1) % images.length)
  }, [hasMultiple, images.length, onActiveIndexChange, safeIndex])

  useEffect(() => {
    if (!hasMultiple) return

    function handleKeyDown(event: KeyboardEvent) {
      const target = event.target
      if (!(target instanceof Node) || !rootRef.current?.contains(target)) return
      if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) return
      if (event.key === 'ArrowLeft') {
        event.preventDefault()
        goPrev()
      } else if (event.key === 'ArrowRight') {
        event.preventDefault()
        goNext()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [goNext, goPrev, hasMultiple])

  if (images.length === 0) return null

  return (
    <div className="photo-gallery" ref={rootRef}>
      <div className="photo-gallery-stage">
        {hasMultiple && (
          <button
            type="button"
            className="photo-gallery-nav photo-gallery-nav-prev"
            onClick={goPrev}
            aria-label="Previous photo"
          >
            ‹
          </button>
        )}

        <button
          type="button"
          className={`photo-gallery-main${onZoom ? ' photo-gallery-main-zoomable' : ''}`}
          onClick={() => onZoom?.(safeIndex)}
          disabled={!onZoom}
          aria-label={onZoom ? 'View photo full size' : undefined}
        >
          <img src={currentSrc} alt={alt} />
          {onZoom && <span className="photo-gallery-expand" aria-hidden="true">⤢</span>}
        </button>

        {hasMultiple && (
          <button
            type="button"
            className="photo-gallery-nav photo-gallery-nav-next"
            onClick={goNext}
            aria-label="Next photo"
          >
            ›
          </button>
        )}

        {showCounter && hasMultiple && (
          <span className="photo-gallery-counter" aria-live="polite">
            {safeIndex + 1} / {images.length}
          </span>
        )}
      </div>

      {hasMultiple && (
        <div className="photo-gallery-thumbs" role="tablist" aria-label="Photo thumbnails">
          {images.map((src, index) => (
            <button
              key={`${src}-${index}`}
              type="button"
              role="tab"
              className={`photo-gallery-thumb${index === safeIndex ? ' active' : ''}${
                index === coverIndex ? ' cover' : ''
              }`}
              onClick={() => onActiveIndexChange(index)}
              onDoubleClick={() => onZoom?.(index)}
              aria-label={`Show photo ${index + 1}${index === coverIndex ? ' (cover)' : ''}`}
              aria-selected={index === safeIndex}
            >
              <img src={src} alt="" />
              {index === coverIndex && <span className="photo-gallery-cover-badge">Cover</span>}
            </button>
          ))}
        </div>
      )}

      {(onSetCover || onRemove) && (
        <div className="photo-gallery-editor-actions">
          {onSetCover && safeIndex !== coverIndex && (
            <button type="button" className="btn ghost small" onClick={() => onSetCover(safeIndex)}>
              Set as cover
            </button>
          )}
          {onRemove && (
            <button type="button" className="btn ghost small danger-text" onClick={() => onRemove(safeIndex)}>
              Remove photo
            </button>
          )}
        </div>
      )}
    </div>
  )
}
