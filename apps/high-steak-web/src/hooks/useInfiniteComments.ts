import { useCallback, useEffect, useState } from 'react'
import { FEED_PAGE_SIZE, type PageResponse, type PostComment } from '../api/client'
import { useInfiniteScroll } from './useInfiniteScroll'

type LoadCommentsPage = (page: number) => Promise<PageResponse<PostComment>>

export function useInfiniteComments(loadPage: LoadCommentsPage, resetKey: string) {
  const [comments, setComments] = useState<PostComment[]>([])
  const [totalElements, setTotalElements] = useState(0)
  const [page, setPage] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPage = useCallback(
    async (pageNum: number, append: boolean) => {
      const response = await loadPage(pageNum)
      setComments((current) => (append ? [...current, ...response.content] : response.content))
      setTotalElements(response.totalElements)
      setPage(pageNum)
      setHasMore(pageNum + 1 < response.totalPages)
      return response
    },
    [loadPage],
  )

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setError(null)
    setComments([])
    setTotalElements(0)
    setPage(0)
    setHasMore(false)

    fetchPage(0, false)
      .catch((err) => {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Failed to load comments')
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [fetchPage, resetKey])

  const loadMore = useCallback(() => {
    if (loading || loadingMore || !hasMore) return
    setLoadingMore(true)
    fetchPage(page + 1, true)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load more comments'))
      .finally(() => setLoadingMore(false))
  }, [loading, loadingMore, hasMore, fetchPage, page])

  const sentinelRef = useInfiniteScroll(loadMore, {
    enabled: hasMore && !loading && !loadingMore,
  })

  return {
    comments,
    setComments,
    totalElements,
    setTotalElements,
    loading,
    loadingMore,
    error,
    hasMore,
    sentinelRef,
  }
}

export { FEED_PAGE_SIZE }
