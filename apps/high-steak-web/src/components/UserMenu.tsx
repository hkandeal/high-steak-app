import { useEffect, useId, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { postImageUrl } from '../api/client'
import { useAuth } from '../context/AuthContext'
import { displayInitials } from '../utils/displayInitials'
import './UserMenu.css'

export function UserMenu() {
  const { user, logout } = useAuth()
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

  if (!user) return null

  const avatarSrc = user.avatarUrl ? postImageUrl(user.avatarUrl) : null
  const initials = displayInitials(user.displayName)

  function closeMenu() {
    setOpen(false)
  }

  function handleLogout() {
    closeMenu()
    logout()
  }

  return (
    <div className="user-menu" ref={rootRef}>
      <button
        ref={triggerRef}
        type="button"
        className="user-menu-trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        aria-label={`Account menu for ${user.displayName}`}
        onClick={() => setOpen((current) => !current)}
      >
        <span className="user-menu-avatar" aria-hidden="true">
          {avatarSrc ? <img src={avatarSrc} alt="" /> : initials}
        </span>
        <span className="user-menu-name">{initials}</span>
        <span className="user-menu-chevron" aria-hidden="true">
          ▾
        </span>
      </button>

      {open && (
        <div id={menuId} className="user-menu-panel" role="menu">
          <div className="user-menu-header">
            <span className="user-menu-avatar" aria-hidden="true">
              {avatarSrc ? <img src={avatarSrc} alt="" /> : initials}
            </span>
            <div className="user-menu-header-text">
              <strong>{user.displayName}</strong>
              <span>@{user.username}</span>
            </div>
          </div>

          <hr className="user-menu-divider" />

          <Link
            to={`/users/${user.id}`}
            className="user-menu-item"
            role="menuitem"
            onClick={closeMenu}
          >
            My profile
          </Link>

          <Link
            to="/following"
            className="user-menu-item"
            role="menuitem"
            onClick={closeMenu}
          >
            Following
          </Link>

          <hr className="user-menu-divider" />

          <button
            type="button"
            className="user-menu-item logout"
            role="menuitem"
            onClick={handleLogout}
          >
            Log out
          </button>
        </div>
      )}
    </div>
  )
}
