import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  getMe,
  mergeUserWithToken,
  parseUserFromToken,
  setUnauthorizedHandler,
  type AuthResponse,
  type UserSummary,
} from '../api/client'

const STORAGE_KEY = 'high-steak-auth'

type AuthState = {
  token: string
  user: UserSummary
}

type AuthContextValue = {
  user: UserSummary | null
  token: string | null
  isAuthenticated: boolean
  login: (response: AuthResponse) => void
  applyToken: (token: string) => void
  logout: () => void
  refreshUser: () => Promise<void>
  hasRole: (role: string) => boolean
  hasAnyRole: (...roles: string[]) => boolean
  hasScope: (scope: string) => boolean
  hasAnyScope: (...scopes: string[]) => boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

function loadStored(): AuthState | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const stored = JSON.parse(raw) as AuthState
    if (!stored.token) return null
    return {
      token: stored.token,
      user: parseUserFromToken(stored.token),
    }
  } catch {
    return null
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(() => loadStored())

  const logout = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY)
    setAuth(null)
  }, [])

  const login = useCallback((response: AuthResponse) => {
    const user = parseUserFromToken(response.token)
    const next = { token: response.token, user }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    setAuth(next)
  }, [])

  const applyToken = useCallback((token: string) => {
    const user = parseUserFromToken(token)
    const next = { token, user }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    setAuth(next)
  }, [])

  const refreshUser = useCallback(async () => {
    if (!auth?.token) return
    try {
      const profile = await getMe(auth.token)
      const user = mergeUserWithToken(auth.token, profile)
      const next = { token: auth.token, user }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
      setAuth(next)
    } catch {
      logout()
    }
  }, [auth?.token, logout])

  useEffect(() => {
    setUnauthorizedHandler(logout)
    return () => setUnauthorizedHandler(() => {})
  }, [logout])

  useEffect(() => {
    if (auth?.token) {
      refreshUser()
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const hasRole = useCallback(
    (role: string) => auth?.user?.role === role,
    [auth?.user?.role],
  )

  const hasAnyRole = useCallback(
    (...roles: string[]) => (auth?.user?.role ? roles.includes(auth.user.role) : false),
    [auth?.user?.role],
  )

  const hasScope = useCallback(
    (scope: string) => auth?.user?.scopes?.includes(scope) ?? false,
    [auth?.user?.scopes],
  )

  const hasAnyScope = useCallback(
    (...scopes: string[]) => scopes.some((scope) => auth?.user?.scopes?.includes(scope) ?? false),
    [auth?.user?.scopes],
  )

  const value = useMemo<AuthContextValue>(
    () => ({
      user: auth?.user ?? null,
      token: auth?.token ?? null,
      isAuthenticated: Boolean(auth?.token),
      login,
      applyToken,
      logout,
      refreshUser,
      hasRole,
      hasAnyRole,
      hasScope,
      hasAnyScope,
    }),
    [auth, login, applyToken, logout, refreshUser, hasRole, hasAnyRole, hasScope, hasAnyScope],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
