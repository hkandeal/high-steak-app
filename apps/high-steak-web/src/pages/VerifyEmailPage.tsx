import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { resendVerificationEmail, verifyEmail } from '../api/client'
import { useAuth } from '../context/AuthContext'
import './AuthPages.css'

export function VerifyEmailPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const { login: saveAuth } = useAuth()
  const token = searchParams.get('token') ?? ''
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>(token ? 'loading' : 'error')
  const [message, setMessage] = useState(
    token ? 'Verifying your email…' : 'Verification link is missing or invalid.',
  )
  const [resendEmail, setResendEmail] = useState('')
  const [resendStatus, setResendStatus] = useState<string | null>(null)
  const [resending, setResending] = useState(false)

  useEffect(() => {
    if (!token) return

    const verifyKey = `verify-email:${token}`
    const verifyState = sessionStorage.getItem(verifyKey)
    if (verifyState === 'done' || verifyState === 'pending') return
    sessionStorage.setItem(verifyKey, 'pending')

    verifyEmail(token)
      .then((session) => {
        sessionStorage.setItem(verifyKey, 'done')
        saveAuth(session)
        setStatus('success')
        setMessage('Email verified — welcome to High Steaks!')
        setTimeout(() => navigate('/feed'), 1500)
      })
      .catch((err) => {
        sessionStorage.removeItem(verifyKey)
        setStatus('error')
        setMessage(err instanceof Error ? err.message : 'Verification failed')
      })
  }, [token, saveAuth, navigate])

  async function handleResend(e: React.FormEvent) {
    e.preventDefault()
    if (!resendEmail.trim()) return
    setResending(true)
    setResendStatus(null)
    try {
      await resendVerificationEmail(resendEmail.trim())
      setResendStatus('If an unverified account exists for that email, we sent a new link.')
    } catch {
      setResendStatus('Could not resend verification email. Try again later.')
    } finally {
      setResending(false)
    }
  }

  return (
    <section className="auth-page">
      <div className="auth-card">
        <h1>{status === 'success' ? 'You\'re in' : 'Verify your email'}</h1>
        <p className={status === 'error' ? 'form-error' : 'muted'}>{message}</p>

        {status === 'success' && (
          <p className="muted">Redirecting to your feed…</p>
        )}

        {status === 'error' && (
          <>
            <p className="muted">
              Need a new link? Enter your email and we&apos;ll send another verification message.
            </p>
            <form onSubmit={handleResend} className="auth-form">
              <label>
                Email
                <input
                  type="email"
                  value={resendEmail}
                  onChange={(e) => setResendEmail(e.target.value)}
                  autoComplete="email"
                  required
                />
              </label>
              {resendStatus && <p className="muted">{resendStatus}</p>}
              <button type="submit" className="btn primary" disabled={resending}>
                {resending ? 'Sending…' : 'Resend verification email'}
              </button>
            </form>
            <p>
              <Link to="/login">Back to login</Link>
            </p>
          </>
        )}
      </div>
    </section>
  )
}
