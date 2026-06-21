import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { confirmAccountDeletion } from '../api/client'
import { useAuth } from '../context/AuthContext'
import './AuthPages.css'

export function ConfirmAccountDeletionPage() {
  const { logout } = useAuth()
  const token = new URLSearchParams(window.location.search).get('token') ?? ''
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>(token ? 'loading' : 'error')
  const [message, setMessage] = useState(
    token ? 'Confirming account deletion…' : 'Deletion link is missing or invalid.',
  )

  useEffect(() => {
    if (!token) return

    const confirmKey = `confirm-account-deletion:${token}`
    const confirmState = sessionStorage.getItem(confirmKey)
    if (confirmState === 'done' || confirmState === 'pending') return
    sessionStorage.setItem(confirmKey, 'pending')

    confirmAccountDeletion(token)
      .then(async () => {
        sessionStorage.setItem(confirmKey, 'done')
        await logout()
        setStatus('success')
        setMessage('Your account has been permanently deleted. We are sorry to see you go.')
      })
      .catch((err) => {
        sessionStorage.removeItem(confirmKey)
        setStatus('error')
        setMessage(err instanceof Error ? err.message : 'Account deletion failed')
      })
  }, [token, logout])

  return (
    <section className="auth-page">
      <div className="auth-card">
        <h1>{status === 'success' ? 'Account deleted' : 'Confirm deletion'}</h1>
        <p className={status === 'error' ? 'form-error' : 'muted'}>{message}</p>

        {status === 'success' && (
          <p>
            <Link to="/" className="btn primary">
              Back to High Steaks
            </Link>
          </p>
        )}

        {status === 'error' && (
          <p>
            <Link to="/login">Back to login</Link>
          </p>
        )}
      </div>
    </section>
  )
}
