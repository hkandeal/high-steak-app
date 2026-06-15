import { useEffect, useRef } from 'react'

type UseInfiniteScrollOptions = {
  enabled?: boolean
  rootMargin?: string
}

export function useInfiniteScroll(
  onLoadMore: () => void,
  { enabled = true, rootMargin = '240px' }: UseInfiniteScrollOptions = {},
) {
  const sentinelRef = useRef<HTMLDivElement>(null)
  const onLoadMoreRef = useRef(onLoadMore)

  useEffect(() => {
    onLoadMoreRef.current = onLoadMore
  }, [onLoadMore])

  useEffect(() => {
    if (!enabled) return
    const node = sentinelRef.current
    if (!node) return

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) {
          onLoadMoreRef.current()
        }
      },
      { rootMargin },
    )

    observer.observe(node)
    return () => observer.disconnect()
  }, [enabled, rootMargin])

  return sentinelRef
}
