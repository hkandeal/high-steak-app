import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import type { ReactNode } from 'react'

type ProtectedRouteProps = {
  children: ReactNode
  requiredScope?: string
  requiredRole?: string
}

export function ProtectedRoute({
  children,
  requiredScope,
  requiredRole,
}: ProtectedRouteProps) {
  const { isAuthenticated, hasScope, hasRole } = useAuth()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (requiredScope && !hasScope(requiredScope)) {
    return <Navigate to="/feed" replace />
  }

  if (requiredRole && !hasRole(requiredRole)) {
    return <Navigate to="/feed" replace />
  }

  return children
}
