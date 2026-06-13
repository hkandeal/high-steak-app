import { useEffect, useId, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import './PostCardMenu.css'

export type PostCardMenuItem =
  | { kind: 'link'; label: string; to: string }
  | { kind: 'action'; label: string; onSelect: () => void; tone?: 'default' | 'danger' }

type PostCardMenuProps = {
  label: string
  items: PostCardMenuItem[]
}

export function PostCardMenu({ label, items }: PostCardMenuProps) {
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
    <div className="post-card-menu" ref={rootRef} onClick={(event) => event.stopPropagation()}>
      <button
        ref={triggerRef}
        type="button"
        className="post-card-menu-trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        aria-label={label}
        onClick={() => setOpen((current) => !current)}
      >
        <span className="post-card-menu-dots" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
      </button>

      {open && (
        <div id={menuId} className="post-card-menu-panel" role="menu">
          {items.map((item) =>
            item.kind === 'link' ? (
              <Link
                key={item.label}
                to={item.to}
                className="post-card-menu-item"
                role="menuitem"
                onClick={closeMenu}
              >
                {item.label}
              </Link>
            ) : (
              <button
                key={item.label}
                type="button"
                className={`post-card-menu-item ${item.tone === 'danger' ? 'danger' : ''}`}
                role="menuitem"
                onClick={() => {
                  closeMenu()
                  item.onSelect()
                }}
              >
                {item.label}
              </button>
            ),
          )}
        </div>
      )}
    </div>
  )
}
