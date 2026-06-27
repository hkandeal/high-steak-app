import { Link, NavLink, Outlet } from 'react-router-dom'
import { AppSidebar } from './AppSidebar'
import { CreatePostFab } from './CreatePostFab'
import { ModerationLoginNotice } from './ModerationLoginNotice'
import { ThemeToggle } from './ThemeToggle'
import { UserMenu } from './UserMenu'
import { useAuth } from '../context/AuthContext'
import { useModerationNoticesContext } from '../context/ModerationNoticesContext'
import '../pages/NotificationsPage.css'
import './Layout.css'

function GuestHeader() {
  return (
    <header className="top-nav">
      <Link to="/" className="brand">
        <img src="/favicon.svg" alt="" className="brand-icon" width={28} height={28} />
        <span>
          High <em>Steaks</em>
        </span>
      </Link>
      <nav className="nav-links" aria-label="Main">
        <ThemeToggle />
        <NavLink to="/login">Log in</NavLink>
        <NavLink to="/register" className="btn primary small">
          Join
        </NavLink>
      </nav>
    </header>
  )
}

function AuthHeader() {
  return (
    <header className="top-nav top-nav--compact">
      <Link to="/feed" className="brand brand--mobile-only">
        <img src="/favicon.svg" alt="" className="brand-icon" width={28} height={28} />
        <span>
          High <em>Steaks</em>
        </span>
      </Link>
      <div className="top-nav-spacer" aria-hidden="true" />
      <UserMenu />
    </header>
  )
}

export function Layout() {
  const { isAuthenticated } = useAuth()
  const { unreadCount } = useModerationNoticesContext()

  if (!isAuthenticated) {
    return (
      <div className="app-shell">
        <GuestHeader />
        <main className="page-content">
          <Outlet />
        </main>
        <footer className="site-footer">
          <p>Rate the sear. Share the story. Built for steak lovers.</p>
        </footer>
      </div>
    )
  }

  return (
    <div className="app-shell app-shell--with-sidebar">
      <AppSidebar unreadCount={unreadCount} />
      <div className="app-shell-main">
        <AuthHeader />
        <main className="page-content">
          <Outlet />
        </main>
        <footer className="site-footer">
          <p>Rate the sear. Share the story. Built for steak lovers.</p>
        </footer>
      </div>
      <CreatePostFab />
      <ModerationLoginNotice />
    </div>
  )
}
