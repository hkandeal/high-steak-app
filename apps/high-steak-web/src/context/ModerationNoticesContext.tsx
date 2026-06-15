import { createContext, useContext, type ReactNode } from 'react'
import { useAuth } from './AuthContext'
import { useModerationNotices, type ModerationNotice } from '../hooks/useModerationNotices'

export type { ModerationNotice }

type ModerationNoticesContextValue = ReturnType<typeof useModerationNotices>

const ModerationNoticesContext = createContext<ModerationNoticesContextValue | null>(null)

export function ModerationNoticesProvider({ children }: { children: ReactNode }) {
  const { token, user } = useAuth()
  const value = useModerationNotices(token, user?.id)
  return (
    <ModerationNoticesContext.Provider value={value}>{children}</ModerationNoticesContext.Provider>
  )
}

export function useModerationNoticesContext() {
  const ctx = useContext(ModerationNoticesContext)
  if (!ctx) {
    throw new Error('useModerationNoticesContext must be used within ModerationNoticesProvider')
  }
  return ctx
}
