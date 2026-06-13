import { Link, useLocation } from 'react-router-dom'
import type { BackNavigationState } from '../navigation'
import './BackLink.css'

type BackLinkProps = {
  to: string
  label: string
}

export function BackLink({ to, label }: BackLinkProps) {
  return (
    <Link to={to} className="back-link">
      ← {label}
    </Link>
  )
}

type PageBackLinkProps = {
  defaultTo: string
  defaultLabel: string
}

export function PageBackLink({ defaultTo, defaultLabel }: PageBackLinkProps) {
  const location = useLocation()
  const state = location.state as BackNavigationState | null
  const to = state?.backTo ?? defaultTo
  const label = state?.backLabel ?? defaultLabel
  return <BackLink to={to} label={label} />
}
