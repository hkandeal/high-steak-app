import type { ReactNode } from 'react'
import { useAuth } from '../context/AuthContext'

type RoleGateProps = {
  children: ReactNode
  role?: string
  roles?: string[]
  scope?: string
  scopes?: string[]
  fallback?: ReactNode
}

export function RoleGate({
  children,
  role,
  roles,
  scope,
  scopes,
  fallback = null,
}: RoleGateProps) {
  const { hasRole, hasAnyRole, hasScope } = useAuth()

  const roleAllowed =
    (!role && !roles?.length) ||
    (role ? hasRole(role) : false) ||
    (roles?.length ? hasAnyRole(...roles) : false)

  const scopeAllowed =
    (!scope && !scopes?.length) ||
    (scope ? hasScope(scope) : false) ||
    (scopes?.length ? scopes.every((item) => hasScope(item)) : false)

  if (roleAllowed && scopeAllowed) {
    return children
  }

  return fallback
}
