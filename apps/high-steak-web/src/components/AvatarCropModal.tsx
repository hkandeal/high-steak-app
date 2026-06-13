import { useCallback, useEffect, useState } from 'react'
import Cropper, { type Area } from 'react-easy-crop'
import { cropImageToBlob } from '../utils/cropImage'
import './AvatarCropModal.css'

type AvatarCropModalProps = {
  imageSrc: string
  onCancel: () => void
  onComplete: (file: File) => void
}

export function AvatarCropModal({ imageSrc, onCancel, onComplete }: AvatarCropModalProps) {
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const onCropComplete = useCallback((_area: Area, pixels: Area) => {
    setCroppedAreaPixels(pixels)
  }, [])

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') onCancel()
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [onCancel])

  async function handleApply() {
    if (!croppedAreaPixels) return
    setSaving(true)
    setError(null)
    try {
      const blob = await cropImageToBlob(imageSrc, croppedAreaPixels)
      const file = new File([blob], 'avatar.jpg', { type: 'image/jpeg' })
      onComplete(file)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to crop image')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="avatar-crop-overlay" role="presentation" onClick={onCancel}>
      <div
        className="avatar-crop-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="avatar-crop-title"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="avatar-crop-header">
          <h2 id="avatar-crop-title">Crop profile photo</h2>
          <p>Drag to reposition. Use the slider to zoom.</p>
        </header>

        <div className="avatar-crop-stage">
          <Cropper
            image={imageSrc}
            crop={crop}
            zoom={zoom}
            aspect={1}
            cropShape="round"
            showGrid={false}
            onCropChange={setCrop}
            onZoomChange={setZoom}
            onCropComplete={onCropComplete}
          />
        </div>

        <label className="avatar-crop-zoom">
          Zoom
          <input
            type="range"
            min={1}
            max={3}
            step={0.05}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
          />
        </label>

        {error && <p className="form-error avatar-crop-error">{error}</p>}

        <div className="avatar-crop-actions">
          <button type="button" className="btn ghost" onClick={onCancel} disabled={saving}>
            Cancel
          </button>
          <button type="button" className="btn primary" onClick={handleApply} disabled={saving}>
            {saving ? 'Applying…' : 'Apply'}
          </button>
        </div>
      </div>
    </div>
  )
}
