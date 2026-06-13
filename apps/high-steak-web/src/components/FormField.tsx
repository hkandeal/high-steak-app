import type { ReactNode } from 'react'
import './FormField.css'

export type FieldFeedback = {
  tone: 'idle' | 'checking' | 'success' | 'error'
  message?: string
}

type FormFieldProps = {
  label: string
  htmlFor?: string
  hint?: string
  feedback?: FieldFeedback
  children: ReactNode
}

export function FormField({ label, htmlFor, hint, feedback, children }: FormFieldProps) {
  const tone = feedback?.tone ?? 'idle'
  const message = feedback?.message

  return (
    <label className={`form-field tone-${tone}`} htmlFor={htmlFor}>
      <span className="form-field-label">{label}</span>
      {children}
      {hint && tone === 'idle' && !message && <span className="form-field-hint">{hint}</span>}
      {message && (
        <span
          className={`form-field-feedback ${
            tone === 'success' ? 'is-success' : tone === 'error' ? 'is-error' : tone === 'checking' ? 'is-checking' : ''
          }`}
          role={tone === 'error' ? 'alert' : 'status'}
          aria-live="polite"
        >
          {message}
        </span>
      )}
    </label>
  )
}
