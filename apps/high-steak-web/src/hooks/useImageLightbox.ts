import { useCallback, useState } from 'react'
import type { ImageLightboxState } from '../components/ImageLightbox'

export function useImageLightbox() {
  const [lightbox, setLightbox] = useState<ImageLightboxState | null>(null)

  const openLightbox = useCallback((images: string[], index = 0, alt?: string) => {
    if (images.length === 0) return
    setLightbox({
      images,
      index: Math.min(Math.max(index, 0), images.length - 1),
      alt,
    })
  }, [])

  const closeLightbox = useCallback(() => {
    setLightbox(null)
  }, [])

  return { lightbox, openLightbox, closeLightbox }
}
