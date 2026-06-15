import { ModerationPanel } from '../components/ModerationPanel'
import { UserManagementPanel } from '../components/UserManagementPanel'
import { useAuth } from '../context/AuthContext'
import '../components/ManagementPage.css'
import './FeedPage.css'

export function ManagementPage() {
  const { hasScope } = useAuth()
  const isAdmin = hasScope('users:manage')
  const isModerator = hasScope('posts:moderate')

  return (
    <section className="feed-page">
      <header className="management-page-header">
        <h1>Manage</h1>
        <p>
          {isAdmin
            ? 'Assign and remove moderator access for members.'
            : 'Browse members, review feeds on their profiles, and block accounts or posts.'}
        </p>
      </header>

      <div className="management-sections">
        {isAdmin && <UserManagementPanel />}

        {!isAdmin && isModerator && <ModerationPanel />}
      </div>
    </section>
  )
}
