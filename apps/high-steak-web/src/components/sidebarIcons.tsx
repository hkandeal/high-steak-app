import type { SVGProps } from 'react'

type IconProps = SVGProps<SVGSVGElement>

const base = {
  width: 22,
  height: 22,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.75,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
  'aria-hidden': true,
}

export function FeedIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <path d="M12 22c3.5-2.5 5.5-5.5 5.5-9.5A5.5 5.5 0 0 0 7 8.5c0 1.2.4 2.3 1 3.2-.8.7-1.3 1.7-1.3 2.8 0 2.2 1.8 4 4 4h2c2.2 0 4-1.8 4-4 0-1.1-.5-2.1-1.3-2.8.6-.9 1-2 1-3.2A5.5 5.5 0 0 0 12 22Z" />
    </svg>
  )
}

export function ExploreIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <path d="M12 21s7-4.5 7-11a7 7 0 1 0-14 0c0 6.5 7 11 7 11Z" />
      <circle cx="12" cy="10" r="2.5" />
    </svg>
  )
}

export function DiscoverIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <circle cx="10" cy="8" r="3.5" />
      <path d="M14.5 14.5 20 20" />
      <path d="M4 20c1.2-3 3.4-4.5 6-4.5s4.8 1.5 6 4.5" />
    </svg>
  )
}

export function BookmarksIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <path d="M7 4h10a1 1 0 0 1 1 1v15l-6-3.5L6 20V5a1 1 0 0 1 1-1Z" />
    </svg>
  )
}

export function FollowingIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <circle cx="9" cy="8" r="3.5" />
      <path d="M3.5 19c.6-2.8 2.7-4.5 5.5-4.5s4.9 1.7 5.5 4.5" />
      <path d="M16 11v6" />
      <path d="M13 14h6" />
    </svg>
  )
}

export function NotificationsIcon(props: IconProps) {
  return (
    <svg {...base} {...props}>
      <path d="M9 18h6" />
      <path d="M5 9a7 7 0 1 1 14 0c0 5 2 6 2 6H3s2-1 2-6Z" />
    </svg>
  )
}
