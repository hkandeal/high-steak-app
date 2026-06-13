import { useState } from 'react'
import './PasswordInput.css'

type PasswordInputProps = {
  id?: string
  value: string
  onChange: (value: string) => void
  placeholder?: string
  minLength?: number
  maxLength?: number
  required?: boolean
  autoComplete?: string
}

export function PasswordInput({
  id,
  value,
  onChange,
  placeholder,
  minLength,
  maxLength,
  required,
  autoComplete,
}: PasswordInputProps) {
  const [visible, setVisible] = useState(false)

  return (
    <div className="password-input-wrap">
      <input
        id={id}
        type={visible ? 'text' : 'password'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        minLength={minLength}
        maxLength={maxLength}
        required={required}
        autoComplete={autoComplete}
      />
      <button
        type="button"
        className="password-toggle"
        onClick={() => setVisible((current) => !current)}
        aria-label={visible ? 'Hide password' : 'Show password'}
        aria-pressed={visible}
      >
        {visible ? 'Hide' : 'Show'}
      </button>
    </div>
  )
}
