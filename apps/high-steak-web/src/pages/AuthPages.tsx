import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  checkEmailAvailability,
  checkUsernameAvailability,
  login,
  register,
} from '../api/client'
import { API_CONSTRAINTS } from '../api/constraints'
import { FormField, type FieldFeedback } from '../components/FormField'
import { PasswordInput } from '../components/PasswordInput'
import { useAuth } from '../context/AuthContext'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import {
  sanitizeUsernameInput,
  validateEmailFormat,
  validateRegisterForm,
  validateTextLength,
  validateUsernameFormat,
} from '../utils/validation'
import './AuthPages.css'

export function LoginPage() {
  const navigate = useNavigate()
  const { login: saveAuth } = useAuth()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await login({ username: username.trim(), password })
      saveAuth(res)
      navigate('/feed')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthCard
      title="Welcome back"
      subtitle="Log in to rate your latest sear."
      error={error}
      onSubmit={handleSubmit}
      loading={loading}
      submitDisabled={!username.trim() || !password}
      footer={
        <p>
          New here? <Link to="/register">Create an account</Link>
        </p>
      }
    >
      <FormField label="Username" htmlFor="login-username">
        <input
          id="login-username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          maxLength={API_CONSTRAINTS.username.max}
          autoComplete="username"
          required
        />
      </FormField>
      <FormField label="Password" htmlFor="login-password">
        <PasswordInput
          id="login-password"
          value={password}
          onChange={setPassword}
          maxLength={API_CONSTRAINTS.password.max}
          autoComplete="current-password"
          required
        />
      </FormField>
    </AuthCard>
  )
}

export function RegisterPage() {
  const navigate = useNavigate()
  const { login: saveAuth } = useAuth()
  const [form, setForm] = useState({
    username: '',
    email: '',
    password: '',
    passwordConfirm: '',
    displayName: '',
  })
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [verificationEmail, setVerificationEmail] = useState<string | null>(null)
  const [usernameCheck, setUsernameCheck] = useState<FieldFeedback>({ tone: 'idle' })
  const [emailCheck, setEmailCheck] = useState<FieldFeedback>({ tone: 'idle' })

  const debouncedUsername = useDebouncedValue(form.username)
  const debouncedEmail = useDebouncedValue(form.email)

  const displayNameFeedback = useMemo<FieldFeedback>(() => {
    const message = validateTextLength(form.displayName, 'Display name', {
      required: true,
      min: API_CONSTRAINTS.displayName.min,
      max: API_CONSTRAINTS.displayName.max,
    })
    if (!form.displayName) return { tone: 'idle' }
    return message ? { tone: 'error', message } : { tone: 'success', message: 'Looks good' }
  }, [form.displayName])

  const usernameFormatError = useMemo(
    () => (form.username ? validateUsernameFormat(form.username) : null),
    [form.username],
  )

  const emailFormatError = useMemo(
    () => (form.email ? validateEmailFormat(form.email) : null),
    [form.email],
  )

  const passwordFeedback = useMemo<FieldFeedback>(() => {
    if (!form.password) return { tone: 'idle' }
    const message = validateTextLength(form.password, 'Password', {
      required: true,
      min: API_CONSTRAINTS.password.min,
      max: API_CONSTRAINTS.password.max,
    })
    return message ? { tone: 'error', message } : { tone: 'success', message: 'Strong enough' }
  }, [form.password])

  const passwordConfirmFeedback = useMemo<FieldFeedback>(() => {
    if (!form.passwordConfirm) return { tone: 'idle' }
    if (form.password !== form.passwordConfirm) {
      return { tone: 'error', message: 'Passwords do not match.' }
    }
    return { tone: 'success', message: 'Passwords match' }
  }, [form.password, form.passwordConfirm])

  useEffect(() => {
    if (!debouncedUsername) {
      setUsernameCheck({ tone: 'idle' })
      return
    }
    const formatError = validateUsernameFormat(debouncedUsername)
    if (formatError) {
      setUsernameCheck({ tone: 'error', message: formatError })
      return
    }

    let cancelled = false
    setUsernameCheck({ tone: 'checking', message: 'Checking availability…' })
    checkUsernameAvailability(debouncedUsername)
      .then((result) => {
        if (cancelled) return
        setUsernameCheck(
          result.available
            ? { tone: 'success', message: result.message }
            : { tone: 'error', message: result.message },
        )
      })
      .catch(() => {
        if (!cancelled) {
          setUsernameCheck({ tone: 'error', message: 'Could not check username.' })
        }
      })

    return () => {
      cancelled = true
    }
  }, [debouncedUsername])

  useEffect(() => {
    if (!debouncedEmail) {
      setEmailCheck({ tone: 'idle' })
      return
    }
    const formatError = validateEmailFormat(debouncedEmail)
    if (formatError) {
      setEmailCheck({ tone: 'error', message: formatError })
      return
    }

    let cancelled = false
    setEmailCheck({ tone: 'checking', message: 'Checking email…' })
    checkEmailAvailability(debouncedEmail)
      .then((result) => {
        if (cancelled) return
        setEmailCheck(
          result.available
            ? { tone: 'success', message: result.message }
            : { tone: 'error', message: result.message },
        )
      })
      .catch(() => {
        if (!cancelled) {
          setEmailCheck({ tone: 'error', message: 'Could not check email.' })
        }
      })

    return () => {
      cancelled = true
    }
  }, [debouncedEmail])

  const usernameFeedback: FieldFeedback =
    form.username && usernameFormatError
      ? { tone: 'error', message: usernameFormatError }
      : usernameCheck

  const emailFeedback: FieldFeedback =
    form.email && emailFormatError ? { tone: 'error', message: emailFormatError } : emailCheck

  const canSubmit =
    !loading &&
    displayNameFeedback.tone === 'success' &&
    usernameFeedback.tone === 'success' &&
    emailFeedback.tone === 'success' &&
    passwordFeedback.tone === 'success' &&
    passwordConfirmFeedback.tone === 'success'

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const validationError = validateRegisterForm(form)
      if (validationError) {
        setError(validationError)
        setLoading(false)
        return
      }
      const res = await register({
        username: form.username.trim(),
        email: form.email.trim(),
        password: form.password,
        displayName: form.displayName.trim(),
      })
      if (res.verificationRequired) {
        setVerificationEmail(res.email)
        return
      }
      if (res.token && res.refreshToken) {
        saveAuth({ token: res.token, refreshToken: res.refreshToken })
        navigate('/feed')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  if (verificationEmail) {
    return (
      <AuthCard
        title="Check your email"
        subtitle="One more step before you join the grill."
        error={null}
        onSubmit={(e) => e.preventDefault()}
        loading={false}
        submitDisabled
        footer={
          <p>
            Verified already? <Link to="/login">Log in</Link>
          </p>
        }
      >
        <p className="auth-verify-copy">
          We sent a verification link to <strong>{verificationEmail}</strong>. Open it to activate
          your account, then log in.
        </p>
        <p className="muted">
          Didn&apos;t get it? Check spam or use the resend option on the{' '}
          <Link to="/verify-email">verification page</Link>.
        </p>
      </AuthCard>
    )
  }

  return (
    <AuthCard
      title="Join High Steaks"
      subtitle="Start sharing your best cuts."
      error={error}
      onSubmit={handleSubmit}
      loading={loading}
      submitDisabled={!canSubmit}
      footer={
        <p>
          Already grilling? <Link to="/login">Log in</Link>
        </p>
      }
    >
      <FormField label="Display name" htmlFor="register-display-name" feedback={displayNameFeedback}>
        <input
          id="register-display-name"
          value={form.displayName}
          onChange={(e) => setForm({ ...form, displayName: e.target.value })}
          minLength={API_CONSTRAINTS.displayName.min}
          maxLength={API_CONSTRAINTS.displayName.max}
          autoComplete="name"
          required
        />
      </FormField>

      <FormField
        label="Username"
        htmlFor="register-username"
        hint="Letters, numbers, _ and -. Cannot start with a number."
        feedback={usernameFeedback}
      >
        <input
          id="register-username"
          value={form.username}
          onChange={(e) => setForm({ ...form, username: sanitizeUsernameInput(e.target.value) })}
          minLength={API_CONSTRAINTS.username.min}
          maxLength={API_CONSTRAINTS.username.max}
          autoComplete="username"
          required
        />
      </FormField>

      <FormField label="Email" htmlFor="register-email" feedback={emailFeedback}>
        <input
          id="register-email"
          type="email"
          value={form.email}
          onChange={(e) => setForm({ ...form, email: e.target.value })}
          maxLength={API_CONSTRAINTS.email.max}
          autoComplete="email"
          required
        />
      </FormField>

      <FormField label="Password" htmlFor="register-password" feedback={passwordFeedback}>
        <PasswordInput
          id="register-password"
          value={form.password}
          onChange={(value) => setForm({ ...form, password: value })}
          minLength={API_CONSTRAINTS.password.min}
          maxLength={API_CONSTRAINTS.password.max}
          autoComplete="new-password"
          required
        />
      </FormField>

      <FormField
        label="Confirm password"
        htmlFor="register-password-confirm"
        feedback={passwordConfirmFeedback}
      >
        <PasswordInput
          id="register-password-confirm"
          value={form.passwordConfirm}
          onChange={(value) => setForm({ ...form, passwordConfirm: value })}
          minLength={API_CONSTRAINTS.password.min}
          maxLength={API_CONSTRAINTS.password.max}
          autoComplete="new-password"
          required
        />
      </FormField>
    </AuthCard>
  )
}

function AuthCard({
  title,
  subtitle,
  error,
  onSubmit,
  loading,
  submitDisabled,
  children,
  footer,
}: {
  title: string
  subtitle: string
  error: string | null
  onSubmit: (e: FormEvent) => void
  loading: boolean
  submitDisabled?: boolean
  children: React.ReactNode
  footer: React.ReactNode
}) {
  return (
    <section className="auth-page">
      <form className="auth-card" onSubmit={onSubmit} noValidate>
        <h1>{title}</h1>
        <p className="auth-subtitle">{subtitle}</p>
        {error && <p className="form-error">{error}</p>}
        <div className="auth-fields">{children}</div>
        <button type="submit" className="btn primary full" disabled={loading || submitDisabled}>
          {loading ? 'Please wait…' : 'Continue'}
        </button>
        <div className="auth-footer">{footer}</div>
      </form>
    </section>
  )
}
