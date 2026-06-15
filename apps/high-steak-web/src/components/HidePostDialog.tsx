import { useEffect, useId, useRef, useState } from 'react'
import './ConfirmDialog.css'
import './HidePostDialog.css'

type HidePostDialogProps = {
  open: boolean
  postTitle: string
  loading?: boolean
  onConfirm: (reason: string) => void
  onCancel: () => void
}

const REASON_MAX = 500

export function HidePostDialog({
  open,
  postTitle,
  loading = false,
  onConfirm,
  onCancel,
}: HidePostDialogProps) {
  const titleId = useId()
  const cancelRef = useRef<HTMLButtonElement>(null)
  const [reason, setReason] = useState('')

  useEffect(() => {
    if (!open) {
      setReason('')
      return
    }
    cancelRef.current?.focus()
  }, [open])

  useEffect(() => {
    if (!open) return
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !loading) onCancel()
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [open, loading, onCancel])

  if (!open) return null

  return (
    <div className="confirm-dialog-backdrop" onClick={loading ? undefined : onCancel}>
      <div
        className="confirm-dialog hide-post-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId}>Block this post from feeds?</h2>
        <p>
          “{postTitle}” will be hidden from public feeds. The author can still view it on their
          profile.
        </p>
        <label className="hide-post-reason">
          Reason for the author (optional)
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value.slice(0, REASON_MAX))}
            rows={3}
            placeholder="Explain why this post was removed from feeds…"
            disabled={loading}
          />
          <span className="field-hint">{reason.length}/{REASON_MAX}</span>
        </label>
        <div className="confirm-dialog-actions">
          <button
            ref={cancelRef}
            type="button"
            className="btn ghost"
            onClick={onCancel}
            disabled={loading}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn danger"
            onClick={() => onConfirm(reason.trim())}
            disabled={loading}
          >
            {loading ? 'Blocking…' : 'Block from feed'}
          </button>
        </div>
      </div>
    </div>
  )
}
