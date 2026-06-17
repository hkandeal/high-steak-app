import { Link, NavLink, Outlet } from 'react-router-dom'
import { CreatePostFab } from './CreatePostFab'
import { ModerationLoginNotice } from './ModerationLoginNotice'
import { RoleGate } from './RoleGate'
import { ThemeToggle } from './ThemeToggle'
import { UserMenu } from './UserMenu'
import { useAuth } from '../context/AuthContext'
import { useModerationNoticesContext } from '../context/ModerationNoticesContext'
import '../pages/NotificationsPage.css'
import './Layout.css'

export function Layout() {
  const { isAuthenticated } = useAuth()
  const { unreadCount } = useModerationNoticesContext()

  return (
    <div className="app-shell">
      <header className="top-nav">
        <Link to={isAuthenticated ? '/feed' : '/'} className="brand">
          <img src="/favicon.svg" alt="" className="brand-icon" width={28} height={28} />
          <span>
            High <em>Steaks</em>
          </span>
        </Link>
        <nav className="nav-links">
          <ThemeToggle />
          {isAuthenticated ? (
            <>
              <NavLink to="/feed" className="nav-link">
                <span className="nav-link-icon" aria-hidden="true">
                  ⌂
                </span>
                <span className="nav-link-label">Feed</span>
              </NavLink>
              <NavLink to="/notifications" className="nav-link nav-notifications">
                <span className="nav-link-icon" aria-hidden="true">
                  🔔
                </span>
                <span className="nav-link-label">Notifications</span>
                {unreadCount > 0 && (
                  <span className="nav-notifications-badge">{unreadCount}</span>
                )}
              </NavLink>
              <RoleGate scope="users:discover">
                <NavLink to="/discover" className="nav-link nav-discover">
                  <span className="nav-link-icon" aria-hidden="true">
                    👥
                  </span>
                  <span className="nav-link-label">Steak lovers</span>
                </NavLink>
              </RoleGate>
              <UserMenu />
            </>
          ) : (
            <>
              <NavLink to="/login">Log in</NavLink>
              <NavLink to="/register" className="btn primary small">
                Join
              </NavLink>
            </>
          )}
        </nav>
      </header>
      <main className="page-content">
        <Outlet />
      </main>
      <CreatePostFab />
      <ModerationLoginNotice />
      <footer className="site-footer">
        <p>Rate the sear. Share the story. Built for steak lovers.</p>
      </footer>
    </div>
  )
}
