import { createBrowserRouter, Navigate, RouterProvider } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AuthProvider } from './context/AuthContext'
import { FeedLayoutProvider } from './context/FeedLayoutContext'
import { ThemeProvider } from './context/ThemeContext'
import { ModerationNoticesProvider } from './context/ModerationNoticesContext'
import { BookmarksPage } from './pages/BookmarksPage'
import { ManagementPage } from './pages/ManagementPage'
import { ConfirmAccountDeletionPage } from './pages/ConfirmAccountDeletionPage'
import { NotificationSettingsPage } from './pages/NotificationSettingsPage'
import { NotificationsPage } from './pages/NotificationsPage'
import { DiscoverPage } from './pages/DiscoverPage'
import { FollowingPage } from './pages/FollowingPage'
import { FeedPage } from './pages/FeedPage'
import { LandingPage } from './pages/LandingPage'
import { LoginPage, RegisterPage } from './pages/AuthPages'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import { VerifyEmailPage } from './pages/VerifyEmailPage'
import { PostDetailPage } from './pages/PostDetailPage'
import { ProfilePage } from './pages/ProfilePage'
import { EditPostPage } from './pages/EditPostPage'
import { NewPostPage } from './pages/NewPostPage'
import { ExplorePage } from './pages/ExplorePage'

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      { index: true, element: <LandingPage /> },
      {
        path: 'feed',
        element: (
          <ProtectedRoute>
            <FeedPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'posts/:postId/edit',
        element: (
          <ProtectedRoute requiredScope="posts:write">
            <EditPostPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'posts/:postId',
        element: (
          <ProtectedRoute>
            <PostDetailPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'users/:userId',
        element: (
          <ProtectedRoute>
            <ProfilePage />
          </ProtectedRoute>
        ),
      },
      { path: 'login', element: <LoginPage /> },
      { path: 'register', element: <RegisterPage /> },
      { path: 'verify-email', element: <VerifyEmailPage /> },
      { path: 'forgot-password', element: <ForgotPasswordPage /> },
      { path: 'reset-password', element: <ResetPasswordPage /> },
      { path: 'confirm-account-deletion', element: <ConfirmAccountDeletionPage /> },
      {
        path: 'explore/:placeId?',
        element: (
          <ProtectedRoute requiredScope="places:read">
            <ExplorePage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'post/new',
        element: (
          <ProtectedRoute requiredScope="posts:write">
            <NewPostPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'discover',
        element: (
          <ProtectedRoute requiredScope="users:discover">
            <DiscoverPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'following',
        element: (
          <ProtectedRoute requiredScope="subscriptions:read">
            <FollowingPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'bookmarks',
        element: (
          <ProtectedRoute requiredScope="bookmarks:read">
            <BookmarksPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'notifications',
        element: (
          <ProtectedRoute>
            <NotificationsPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'settings/notifications',
        element: (
          <ProtectedRoute>
            <NotificationSettingsPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'manage',
        element: (
          <ProtectedRoute requiredAnyScope={['posts:moderate', 'users:read']}>
            <ManagementPage />
          </ProtectedRoute>
        ),
      },
      { path: 'moderation', element: <Navigate to="/manage" replace /> },
      { path: 'admin/users', element: <Navigate to="/manage" replace /> },
      { path: '*', element: <Navigate to="/" replace /> },
    ],
  },
])

function App() {
  return (
    <ThemeProvider>
      <FeedLayoutProvider>
        <AuthProvider>
          <ModerationNoticesProvider>
            <RouterProvider router={router} />
          </ModerationNoticesProvider>
        </AuthProvider>
      </FeedLayoutProvider>
    </ThemeProvider>
  )
}

export default App
