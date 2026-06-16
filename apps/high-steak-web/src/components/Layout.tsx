import { Link, NavLink, Outlet } from 'react-router-dom'
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
              <NavLink to="/feed">Feed</NavLink>
              <NavLink to="/post/new">Rate a steak</NavLink>
              <NavLink to="/notifications" className="nav-notifications">
                Notifications
                {unreadCount > 0 && (
                  <span className="nav-notifications-badge">{unreadCount}</span>
                )}
              </NavLink>
              <RoleGate scope="users:discover">
                <NavLink to="/discover">Steak lovers</NavLink>
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
      <ModerationLoginNotice />
      <footer className="site-footer">
        <p>Rate the sear. Share the story. Built for steak lovers.</p>
      </footer>
    </div>
  )
}
