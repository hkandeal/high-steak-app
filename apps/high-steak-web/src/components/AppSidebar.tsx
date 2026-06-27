import { Link, useLocation } from 'react-router-dom'
import { RoleGate } from './RoleGate'
import {
  BookmarksIcon,
  DiscoverIcon,
  ExploreIcon,
  FeedIcon,
  FollowingIcon,
  NotificationsIcon,
} from './sidebarIcons'
import './AppSidebar.css'

type AppSidebarProps = {
  unreadCount: number
}

type SidebarItem = {
  to: string
  label: string
  icon: typeof FeedIcon
  isActive: (pathname: string) => boolean
  scope?: string
  badge?: number
}

const items: SidebarItem[] = [
  {
    to: '/feed',
    label: 'Feed',
    icon: FeedIcon,
    isActive: (pathname) =>
      pathname === '/feed' ||
      pathname === '/post/new' ||
      pathname.startsWith('/posts/'),
  },
  {
    to: '/explore',
    label: 'Explore',
    icon: ExploreIcon,
    isActive: (pathname) => pathname === '/explore' || pathname.startsWith('/explore/'),
    scope: 'places:read',
  },
  {
    to: '/discover',
    label: 'The Herd',
    icon: DiscoverIcon,
    isActive: (pathname) => pathname === '/discover',
    scope: 'users:discover',
  },
  {
    to: '/bookmarks',
    label: 'Saved',
    icon: BookmarksIcon,
    isActive: (pathname) => pathname === '/bookmarks',
    scope: 'bookmarks:read',
  },
  {
    to: '/following',
    label: 'Following',
    icon: FollowingIcon,
    isActive: (pathname) => pathname === '/following',
    scope: 'subscriptions:read',
  },
  {
    to: '/notifications',
    label: 'Alerts',
    icon: NotificationsIcon,
    isActive: (pathname) => pathname === '/notifications',
  },
]

function SidebarLink({
  item,
  unreadCount,
}: {
  item: SidebarItem
  unreadCount: number
}) {
  const location = useLocation()
  const active = item.isActive(location.pathname)
  const badge = item.to === '/notifications' ? unreadCount : item.badge
  const Icon = item.icon

  const link = (
    <Link
      to={item.to}
      className={`app-sidebar-link ${active ? 'active' : ''}`}
      aria-current={active ? 'page' : undefined}
      title={item.label}
    >
      <span className="app-sidebar-link-icon-wrap">
        <Icon className="app-sidebar-link-icon" />
        {badge != null && badge > 0 && (
          <span className="app-sidebar-badge">{badge > 99 ? '99+' : badge}</span>
        )}
      </span>
      <span className="app-sidebar-link-label">{item.label}</span>
    </Link>
  )

  if (item.scope) {
    return <RoleGate scope={item.scope}>{link}</RoleGate>
  }

  return link
}

export function AppSidebar({ unreadCount }: AppSidebarProps) {
  return (
    <aside className="app-sidebar" aria-label="Main navigation">
      <Link to="/feed" className="app-sidebar-brand" title="High Steaks home">
        <img src="/favicon.svg" alt="" width={30} height={30} />
      </Link>

      <nav className="app-sidebar-nav">
        {items.map((item) => (
          <SidebarLink key={item.to} item={item} unreadCount={unreadCount} />
        ))}
      </nav>
    </aside>
  )
}
