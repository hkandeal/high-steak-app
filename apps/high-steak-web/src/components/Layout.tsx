import { Link, NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Layout.css'

export function Layout() {
  const { isAuthenticated, user, logout } = useAuth()

  return (
    <div className="app-shell">
      <header className="top-nav">
        <Link to="/" className="brand">
          <span className="brand-mark">🥩</span>
          <span>
            High <em>Steak</em>
          </span>
        </Link>
        <nav className="nav-links">
          <NavLink to="/feed">Feed</NavLink>
          {isAuthenticated ? (
            <>
              <NavLink to="/post/new">Rate a steak</NavLink>
              <span className="nav-user">@{user?.username}</span>
              <button type="button" className="btn ghost" onClick={logout}>
                Log out
              </button>
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
