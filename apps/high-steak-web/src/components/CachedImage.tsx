import type { ImgHTMLAttributes } from 'react'

type CachedImageProps = Omit<ImgHTMLAttributes<HTMLImageElement>, 'loading' | 'decoding'> & {
  /** When true, load eagerly (e.g. hero / above the fold). */
  priority?: boolean
  loading?: ImgHTMLAttributes<HTMLImageElement>['loading']
  decoding?: ImgHTMLAttributes<HTMLImageElement>['decoding']
}

/**
 * Standard img for API-served uploads. Effective HTTP caching comes from
 * server Cache-Control on /uploads/** (ADR 013).
 */
export function CachedImage({
  priority = false,
  loading,
  decoding = 'async',
  fetchPriority,
  ...props
}: CachedImageProps) {
  return (
    <img
      {...props}
      loading={loading ?? (priority ? 'eager' : 'lazy')}
      decoding={decoding}
      fetchPriority={fetchPriority ?? (priority ? 'high' : undefined)}
    />
  )
}
