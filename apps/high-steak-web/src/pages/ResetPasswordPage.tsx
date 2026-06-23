import { useMemo, useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { resetPassword } from '../api/client'
import { API_CONSTRAINTS } from '../api/constraints'
import { FormField, type FieldFeedback } from '../components/FormField'
import { PasswordInput } from '../components/PasswordInput'
import { validateResetPasswordForm, validateTextLength } from '../utils/validation'
import './AuthPages.css'

export function ResetPasswordPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token') ?? ''
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [error, setError] = useState<string | null>(
    token ? null : 'Reset link is missing or invalid.',
  )
  const [success, setSuccess] = useState(false)
  const [loading, setLoading] = useState(false)

  const passwordFeedback = useMemo<FieldFeedback>(() => {
    if (!password) return { tone: 'idle' }
    const message = validateTextLength(password, 'Password', {
      required: true,
      min: API_CONSTRAINTS.password.min,
      max: API_CONSTRAINTS.password.max,
    })
    return message ? { tone: 'error', message } : { tone: 'success', message: 'Strong enough' }
  }, [password])

  const passwordConfirmFeedback = useMemo<FieldFeedback>(() => {
    if (!passwordConfirm) return { tone: 'idle' }
    if (password !== passwordConfirm) {
      return { tone: 'error', message: 'Passwords do not match.' }
    }
    return { tone: 'success', message: 'Passwords match' }
  }, [password, passwordConfirm])

  const canSubmit =
    !!token &&
    passwordFeedback.tone === 'success' &&
    passwordConfirmFeedback.tone === 'success' &&
    !loading

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!token) return

    setLoading(true)
    setError(null)
    try {
      const validationError = validateResetPasswordForm({ password, passwordConfirm })
      if (validationError) {
        setError(validationError)
        setLoading(false)
        return
      }
      await resetPassword({ token, password, passwordConfirm })
      setSuccess(true)
      setTimeout(() => navigate('/login'), 2000)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Password reset failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="auth-page">
      <form className="auth-card" onSubmit={handleSubmit} noValidate>
        <h1>{success ? 'Password updated' : 'Choose a new password'}</h1>
        <p className="auth-subtitle">
          {success
            ? 'Your password has been reset. Redirecting to login…'
            : 'Enter and confirm your new password.'}
        </p>
        {error && <p className="form-error">{error}</p>}
        {!success && token && (
          <>
            <div className="auth-fields">
              <FormField label="New password" htmlFor="reset-password" feedback={passwordFeedback}>
                <PasswordInput
                  id="reset-password"
                  value={password}
                  onChange={setPassword}
                  minLength={API_CONSTRAINTS.password.min}
                  maxLength={API_CONSTRAINTS.password.max}
                  autoComplete="new-password"
                  required
                />
              </FormField>
              <FormField
                label="Confirm password"
                htmlFor="reset-password-confirm"
                feedback={passwordConfirmFeedback}
              >
                <PasswordInput
                  id="reset-password-confirm"
                  value={passwordConfirm}
                  onChange={setPasswordConfirm}
                  minLength={API_CONSTRAINTS.password.min}
                  maxLength={API_CONSTRAINTS.password.max}
                  autoComplete="new-password"
                  required
                />
              </FormField>
            </div>
            <button type="submit" className="btn primary full" disabled={!canSubmit}>
              {loading ? 'Please wait…' : 'Reset password'}
            </button>
          </>
        )}
        <div className="auth-footer">
          <p>
            <Link to="/login">Back to login</Link>
          </p>
        </div>
      </form>
    </section>
  )
}
