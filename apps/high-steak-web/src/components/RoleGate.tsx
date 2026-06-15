import type { ReactNode } from 'react'
import { useAuth } from '../context/AuthContext'

type RoleGateProps = {
  children: ReactNode
  role?: string
  roles?: string[]
  scope?: string
  scopes?: string[]
  anyScope?: string[]
  fallback?: ReactNode
}

export function RoleGate({
  children,
  role,
  roles,
  scope,
  scopes,
  anyScope,
  fallback = null,
}: RoleGateProps) {
  const { hasRole, hasAnyRole, hasScope, hasAnyScope } = useAuth()

  const roleAllowed =
    (!role && !roles?.length) ||
    (role ? hasRole(role) : false) ||
    (roles?.length ? hasAnyRole(...roles) : false)

  const scopeAllowed =
    (!scope && !scopes?.length && !anyScope?.length) ||
    (scope ? hasScope(scope) : false) ||
    (scopes?.length ? scopes.every((item) => hasScope(item)) : false) ||
    (anyScope?.length ? hasAnyScope(...anyScope) : false)

  if (roleAllowed && scopeAllowed) {
    return children
  }

  return fallback
}
