import { useEffect, useId, useRef } from 'react'
import './ConfirmDialog.css'

type ConfirmDialogProps = {
  open: boolean
  title: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  secondaryLabel?: string
  variant?: 'default' | 'danger'
  loading?: boolean
  secondaryLoading?: boolean
  onConfirm: () => void
  onCancel: () => void
  onSecondary?: () => void
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  secondaryLabel,
  variant = 'default',
  loading = false,
  secondaryLoading = false,
  onConfirm,
  onCancel,
  onSecondary,
}: ConfirmDialogProps) {
  const titleId = useId()
  const cancelRef = useRef<HTMLButtonElement>(null)
  const busy = loading || secondaryLoading

  useEffect(() => {
    if (!open) return

    cancelRef.current?.focus()

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !busy) {
        onCancel()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [open, busy, onCancel])

  if (!open) return null

  return (
    <div className="confirm-dialog-backdrop" onClick={busy ? undefined : onCancel}>
      <div
        className="confirm-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId}>{title}</h2>
        <p>{message}</p>
        <div className={`confirm-dialog-actions ${secondaryLabel ? 'confirm-dialog-actions--triple' : ''}`}>
          <button
            ref={cancelRef}
            type="button"
            className="btn ghost"
            onClick={onCancel}
            disabled={busy}
          >
            {cancelLabel}
          </button>
          {secondaryLabel && onSecondary && (
            <button
              type="button"
              className="btn primary"
              onClick={onSecondary}
              disabled={busy}
            >
              {secondaryLoading ? 'Saving…' : secondaryLabel}
            </button>
          )}
          <button
            type="button"
            className={`btn ${variant === 'danger' ? 'danger' : 'primary'}`}
            onClick={onConfirm}
            disabled={busy}
          >
            {loading ? 'Working…' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
