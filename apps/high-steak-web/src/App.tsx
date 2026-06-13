import { createBrowserRouter, Navigate, RouterProvider } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AuthProvider } from './context/AuthContext'
import { ThemeProvider } from './context/ThemeContext'
import { AdminUsersPage, ModerationPage } from './pages/AdminPages'
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
        path: 'moderation',
        element: (
          <ProtectedRoute requiredScope="posts:moderate">
            <ModerationPage />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/users',
        element: (
          <ProtectedRoute requiredScope="users:read">
            <AdminUsersPage />
          </ProtectedRoute>
        ),
      },
      { path: '*', element: <Navigate to="/" replace /> },
    ],
  },
])

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App
