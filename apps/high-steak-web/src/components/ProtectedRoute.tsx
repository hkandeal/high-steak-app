import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import type { ReactNode } from 'react'

type ProtectedRouteProps = {
  children: ReactNode
  requiredScope?: string
  requiredAnyScope?: string[]
  requiredRole?: string
}

export function ProtectedRoute({
  children,
  requiredScope,
  requiredAnyScope,
  requiredRole,
}: ProtectedRouteProps) {
  const { isAuthenticated, hasScope, hasAnyScope, hasRole } = useAuth()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (requiredScope && !hasScope(requiredScope)) {
    return <Navigate to="/feed" replace />
  }

  if (requiredAnyScope?.length && !hasAnyScope(...requiredAnyScope)) {
    return <Navigate to="/feed" replace />
  }

  if (requiredRole && !hasRole(requiredRole)) {
    return <Navigate to="/feed" replace />
  }

  return children
}
