import { type ReactNode } from 'react'
import { useFeedLayout } from '../context/FeedLayoutContext'

type PostFeedLayoutProps = {
  children: ReactNode
  className?: string
  variant?: 'post' | 'explore'
}

export function PostFeedLayout({
  children,
  className = '',
  variant = 'post',
}: PostFeedLayoutProps) {
  const { layout } = useFeedLayout()
  const baseClass = variant === 'explore' ? 'explore-post-feed' : 'post-feed'

  return (
    <div className={`${baseClass} ${baseClass}--${layout} ${className}`.trim()}>
      {children}
    </div>
  )
}
