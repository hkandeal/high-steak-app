import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { requestPasswordReset } from '../api/client'
import { API_CONSTRAINTS } from '../api/constraints'
import { FormField } from '../components/FormField'
import { validateEmailFormat, validateTextLength } from '../utils/validation'
import './AuthPages.css'

export function ForgotPasswordPage() {
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setMessage(null)

    const usernameError = validateTextLength(username, 'Username', {
      required: true,
      max: API_CONSTRAINTS.username.max,
    })
    const emailError = validateEmailFormat(email)
    if (usernameError || emailError) {
      setError(usernameError ?? emailError)
      setLoading(false)
      return
    }

    try {
      const res = await requestPasswordReset({
        username: username.trim(),
        email: email.trim(),
      })
      setMessage(res.message)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not request password reset')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="auth-page">
      <form className="auth-card" onSubmit={handleSubmit} noValidate>
        <h1>Reset your password</h1>
        <p className="auth-subtitle">
          Enter your username and email. We&apos;ll send a reset link if they match your account.
        </p>
        {error && <p className="form-error">{error}</p>}
        {message && <p className="muted">{message}</p>}
        {!message && (
          <div className="auth-fields">
            <FormField label="Username" htmlFor="forgot-username">
              <input
                id="forgot-username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                maxLength={API_CONSTRAINTS.username.max}
                autoComplete="username"
                required
              />
            </FormField>
            <FormField label="Email" htmlFor="forgot-email">
              <input
                id="forgot-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                maxLength={API_CONSTRAINTS.email.max}
                autoComplete="email"
                required
              />
            </FormField>
          </div>
        )}
        {!message && (
          <button type="submit" className="btn primary full" disabled={loading || !username.trim() || !email.trim()}>
            {loading ? 'Please wait…' : 'Send reset link'}
          </button>
        )}
        <div className="auth-footer">
          <p>
            Remembered it? <Link to="/login">Back to login</Link>
          </p>
        </div>
      </form>
    </section>
  )
}
