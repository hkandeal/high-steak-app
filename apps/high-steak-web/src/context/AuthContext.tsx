import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import {
  clearProactiveRefresh,
  getMe,
  logoutSession,
  mergeUserWithToken,
  parseUserFromToken,
  scheduleProactiveRefresh,
  setSessionHandlers,
  setUnauthorizedHandler,
  type AuthResponse,
  type UserSummary,
} from '../api/client'

const STORAGE_KEY = 'high-steak-auth'

type AuthState = {
  token: string
  refreshToken: string
  user: UserSummary
}

type AuthContextValue = {
  user: UserSummary | null
  token: string | null
  isAuthenticated: boolean
  login: (response: AuthResponse) => void
  applyToken: (token: string) => void
  logout: () => Promise<void>
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
    const stored = JSON.parse(raw) as Partial<AuthState>
    if (!stored.token || !stored.refreshToken) return null
    return {
      token: stored.token,
      refreshToken: stored.refreshToken,
      user: parseUserFromToken(stored.token),
    }
  } catch {
    return null
  }
}

function persistSession(next: AuthState) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
  scheduleProactiveRefresh(next.token, next.refreshToken)
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(() => loadStored())
  const authRef = useRef(auth)
  authRef.current = auth

  const logout = useCallback(async () => {
    clearProactiveRefresh()
    const refreshToken = authRef.current?.refreshToken
    await logoutSession(refreshToken)
    localStorage.removeItem(STORAGE_KEY)
    setAuth(null)
  }, [])

  const login = useCallback((response: AuthResponse) => {
    const next = {
      token: response.token,
      refreshToken: response.refreshToken,
      user: parseUserFromToken(response.token),
    }
    persistSession(next)
    setAuth(next)
  }, [])

  const applyToken = useCallback((token: string) => {
    setAuth((current) => {
      if (!current?.refreshToken) return current
      const next = {
        ...current,
        token,
        user: parseUserFromToken(token),
      }
      persistSession(next)
      return next
    })
  }, [])

  const handleSessionRefreshed = useCallback((response: AuthResponse) => {
    const next = {
      token: response.token,
      refreshToken: response.refreshToken,
      user: parseUserFromToken(response.token),
    }
    persistSession(next)
    setAuth(next)
  }, [])

  const refreshUser = useCallback(async () => {
    if (!authRef.current?.token) return
    try {
      const profile = await getMe(authRef.current.token)
      const user = mergeUserWithToken(authRef.current.token, profile)
      const next = { ...authRef.current, user }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
      setAuth(next)
    } catch {
      await logout()
    }
  }, [logout])

  useEffect(() => {
    setUnauthorizedHandler(() => {
      void logout()
    })
    return () => setUnauthorizedHandler(() => {})
  }, [logout])

  useEffect(() => {
    setSessionHandlers({
      getRefreshToken: () => authRef.current?.refreshToken ?? null,
      onSessionRefreshed: handleSessionRefreshed,
      onLogout: () => {
        void logout()
      },
    })
    return () => setSessionHandlers(null)
  }, [handleSessionRefreshed, logout])

  useEffect(() => {
    if (auth?.token && auth.refreshToken) {
      scheduleProactiveRefresh(auth.token, auth.refreshToken)
    }
    return () => clearProactiveRefresh()
  }, [auth?.token, auth?.refreshToken])

  useEffect(() => {
    if (auth?.token) {
      void refreshUser()
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
      isAuthenticated: Boolean(auth?.token && auth?.refreshToken),
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
