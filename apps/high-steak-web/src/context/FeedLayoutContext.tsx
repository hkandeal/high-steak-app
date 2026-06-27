import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'

export type FeedLayout = 'grid' | 'list'

const STORAGE_KEY = 'hs-feed-layout'

type FeedLayoutContextValue = {
  layout: FeedLayout
  setLayout: (layout: FeedLayout) => void
  useGrid: boolean
}

const FeedLayoutContext = createContext<FeedLayoutContextValue | null>(null)

function readStoredLayout(): FeedLayout {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'list' ? 'list' : 'grid'
  } catch {
    return 'grid'
  }
}

export function FeedLayoutProvider({ children }: { children: ReactNode }) {
  const [layout, setLayoutState] = useState<FeedLayout>(readStoredLayout)

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, layout)
    } catch {
      // ignore storage errors
    }
  }, [layout])

  function setLayout(next: FeedLayout) {
    setLayoutState(next)
  }

  return (
    <FeedLayoutContext.Provider
      value={{ layout, setLayout, useGrid: layout === 'grid' }}
    >
      {children}
    </FeedLayoutContext.Provider>
  )
}

export function useFeedLayout() {
  const context = useContext(FeedLayoutContext)
  if (!context) {
    throw new Error('useFeedLayout must be used within FeedLayoutProvider')
  }
  return context
}
