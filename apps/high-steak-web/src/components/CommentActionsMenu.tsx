import { useEffect, useId, useRef, useState } from 'react'
import './CommentActionsMenu.css'

export type CommentActionItem = {
  label: string
  onSelect: () => void
  tone?: 'default' | 'danger'
  disabled?: boolean
}

type CommentActionsMenuProps = {
  label: string
  items: CommentActionItem[]
}

export function CommentActionsMenu({ label, items }: CommentActionsMenuProps) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)
  const menuId = useId()

  useEffect(() => {
    if (!open) return

    function handlePointerDown(event: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(event.target as Node)) {
        setOpen(false)
      }
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setOpen(false)
        triggerRef.current?.focus()
      }
    }

    document.addEventListener('mousedown', handlePointerDown)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('mousedown', handlePointerDown)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [open])

  if (items.length === 0) return null

  function closeMenu() {
    setOpen(false)
  }

  return (
    <div className="comment-actions-menu" ref={rootRef}>
      <button
        ref={triggerRef}
        type="button"
        className="comment-actions-menu-trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        aria-label={label}
        onClick={() => setOpen((current) => !current)}
      >
        <span className="comment-actions-menu-dots" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
      </button>

      {open && (
        <div id={menuId} className="comment-actions-menu-panel" role="menu">
          {items.map((item) => (
            <button
              key={item.label}
              type="button"
              className={`comment-actions-menu-item${item.tone === 'danger' ? ' danger' : ''}`}
              role="menuitem"
              disabled={item.disabled}
              onClick={() => {
                closeMenu()
                item.onSelect()
              }}
            >
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
