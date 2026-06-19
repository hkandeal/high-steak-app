import { createBrowserRouter, Navigate, RouterProvider } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AuthProvider } from './context/AuthContext'
import { ThemeProvider } from './context/ThemeContext'
import { ModerationNoticesProvider } from './context/ModerationNoticesContext'
import { BookmarksPage } from './pages/BookmarksPage'
import { ManagementPage } from './pages/ManagementPage'
import { NotificationsPage } from './pages/NotificationsPage'
import { DiscoverPage } from './pages/DiscoverPage'
import { FollowingPage } from './pages/FollowingPage'
import { FeedPage } from './pages/FeedPage'
import { LandingPage } from './pages/LandingPage'
import { LoginPage, RegisterPage } from './pages/AuthPages'
import { PostDetailPage } from './pages/PostDetailPage'
import { ProfilePage } from './pages/ProfilePage'
import { EditPostPage } from './pages/EditPostPage'
import { NewPostPage } from './pages/NewPostPage'

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
      <AuthProvider>
        <ModerationNoticesProvider>
          <RouterProvider router={router} />
        </ModerationNoticesProvider>
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App
