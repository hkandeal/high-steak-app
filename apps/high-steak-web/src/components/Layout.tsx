import { Link, NavLink, Outlet } from 'react-router-dom'
import { RoleGate } from './RoleGate'
import { ThemeToggle } from './ThemeToggle'
import { UserMenu } from './UserMenu'
import { useAuth } from '../context/AuthContext'
import './Layout.css'

export function Layout() {
  const { isAuthenticated } = useAuth()

  return (
    <div className="app-shell">
      <header className="top-nav">
        <Link to={isAuthenticated ? '/feed' : '/'} className="brand">
          <span className="brand-mark">🥩</span>
          <span>
            High <em>Steak</em>
          </span>
        </Link>
        <nav className="nav-links">
          <ThemeToggle />
          {isAuthenticated ? (
            <>
              <NavLink to="/feed">Feed</NavLink>
              <NavLink to="/post/new">Rate a steak</NavLink>
              <RoleGate scope="users:discover">
                <NavLink to="/discover">Steak lovers</NavLink>
              </RoleGate>
              <RoleGate roles={['MODERATOR', 'ADMIN']}>
                <NavLink to="/moderation">Moderation</NavLink>
              </RoleGate>
              <RoleGate role="ADMIN">
                <NavLink to="/admin/users">Admin</NavLink>
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
      <footer className="site-footer">
        <p>Rate the sear. Share the story. Built for steak lovers.</p>
      </footer>
    </div>
  )
}
