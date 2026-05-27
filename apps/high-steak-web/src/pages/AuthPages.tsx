import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { login, register } from '../api/client'
import { useAuth } from '../context/AuthContext'
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
      const res = await login({ username, password })
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
      footer={
        <p>
          New here? <Link to="/register">Create an account</Link>
        </p>
      }
    >
      <label>
        Username
        <input value={username} onChange={(e) => setUsername(e.target.value)} required />
      </label>
      <label>
        Password
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
      </label>
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
    displayName: '',
  })
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await register(form)
      saveAuth(res)
      navigate('/feed')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthCard
      title="Join High Steak"
      subtitle="Start sharing your best cuts."
      error={error}
      onSubmit={handleSubmit}
      loading={loading}
      footer={
        <p>
          Already grilling? <Link to="/login">Log in</Link>
        </p>
      }
    >
      <label>
        Display name
        <input
          value={form.displayName}
          onChange={(e) => setForm({ ...form, displayName: e.target.value })}
          required
        />
      </label>
      <label>
        Username
        <input
          value={form.username}
          onChange={(e) => setForm({ ...form, username: e.target.value })}
          required
        />
      </label>
      <label>
        Email
        <input
          type="email"
          value={form.email}
          onChange={(e) => setForm({ ...form, email: e.target.value })}
          required
        />
      </label>
      <label>
        Password
        <input
          type="password"
          value={form.password}
          onChange={(e) => setForm({ ...form, password: e.target.value })}
          minLength={8}
          required
        />
      </label>
    </AuthCard>
  )
}

function AuthCard({
  title,
  subtitle,
  error,
  onSubmit,
  loading,
  children,
  footer,
}: {
  title: string
  subtitle: string
  error: string | null
  onSubmit: (e: FormEvent) => void
  loading: boolean
  children: React.ReactNode
  footer: React.ReactNode
}) {
  return (
    <section className="auth-page">
      <form className="auth-card" onSubmit={onSubmit}>
        <h1>{title}</h1>
        <p className="auth-subtitle">{subtitle}</p>
        {error && <p className="form-error">{error}</p>}
        <div className="auth-fields">{children}</div>
        <button type="submit" className="btn primary full" disabled={loading}>
          {loading ? 'Please wait…' : 'Continue'}
        </button>
        <div className="auth-footer">{footer}</div>
      </form>
    </section>
  )
}
