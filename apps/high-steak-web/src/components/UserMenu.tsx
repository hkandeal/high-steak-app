import { useEffect, useId, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { postImageUrl } from '../api/client'
import { CachedImage } from './CachedImage'
import { RoleGate } from './RoleGate'
import { ThemeToggle } from './ThemeToggle'
import { useAuth } from '../context/AuthContext'
import { displayInitials } from '../utils/displayInitials'
import './UserMenu.css'

type MenuItemProps = {
  to: string
  icon: string
  label: string
  onSelect: () => void
}

function MenuLink({ to, icon, label, onSelect }: MenuItemProps) {
  return (
    <Link to={to} className="user-menu-item" role="menuitem" onClick={onSelect}>
      <span className="user-menu-item-icon" aria-hidden="true">
        {icon}
      </span>
      <span className="user-menu-item-label">{label}</span>
    </Link>
  )
}

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
          {avatarSrc ? <CachedImage src={avatarSrc} alt="" /> : initials}
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
              {avatarSrc ? <CachedImage src={avatarSrc} alt="" /> : initials}
            </span>
            <div className="user-menu-header-text">
              <strong>{user.displayName}</strong>
              <span>@{user.username}</span>
            </div>
          </div>

          <div className="user-menu-section">
            <p className="user-menu-section-label">You</p>
            <MenuLink
              to={`/users/${user.id}`}
              icon="👤"
              label="My profile"
              onSelect={closeMenu}
            />
          </div>

          <div className="user-menu-section">
            <p className="user-menu-section-label">Settings</p>
            <div className="user-menu-theme-row" role="none">
              <span className="user-menu-theme-label">
                <span className="user-menu-item-icon" aria-hidden="true">
                  🌓
                </span>
                <span className="user-menu-item-label">Theme</span>
              </span>
              <ThemeToggle variant="menu" />
            </div>
          </div>

          <RoleGate anyScope={['posts:moderate', 'users:read']}>
            <div className="user-menu-section">
              <p className="user-menu-section-label">Moderation</p>
              <MenuLink to="/manage" icon="🛡" label="Manage" onSelect={closeMenu} />
            </div>
          </RoleGate>

          <hr className="user-menu-divider" />

          <button
            type="button"
            className="user-menu-item logout"
            role="menuitem"
            onClick={handleLogout}
          >
            <span className="user-menu-item-icon" aria-hidden="true">
              ↪
            </span>
            <span className="user-menu-item-label">Log out</span>
          </button>
        </div>
      )}
    </div>
  )
}
