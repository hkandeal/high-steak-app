import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './CreatePostFab.css'

export function CreatePostFab() {
  const { isAuthenticated } = useAuth()
  const { pathname } = useLocation()

  const onEditor =
    pathname === '/post/new' || (pathname.startsWith('/posts/') && pathname.endsWith('/edit'))

  if (!isAuthenticated || onEditor) return null

  return (
    <Link to="/post/new" className="create-post-fab" aria-label="Rate a steak">
      <span className="create-post-fab-icon" aria-hidden="true">
        +
      </span>
    </Link>
  )
}
