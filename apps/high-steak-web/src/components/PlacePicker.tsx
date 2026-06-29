import { useEffect, useId, useRef, useState } from 'react'
import {
  autocompletePlaces,
  postImageUrl,
  resolvePlace,
  type PlaceSuggestion,
  type PlaceSummary,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import { CachedImage } from './CachedImage'
import './PlacePicker.css'

type PlacePickerProps = {
  value: PlaceSummary | null
  onChange: (place: PlaceSummary | null) => void
  disabled?: boolean
  hideLabel?: boolean
  label?: string
  placeholder?: string
}

function PlacePhotoPreview({
  photoUrl,
  alt,
  className,
}: {
  photoUrl: string
  alt: string
  className?: string
}) {
  return (
    <div className={`place-picker-photo ${className ?? ''}`.trim()}>
      <CachedImage src={postImageUrl(photoUrl)} alt={alt} />
      <span className="place-picker-photo-attribution">© Google</span>
    </div>
  )
}

export function PlacePicker({ value, onChange, disabled, hideLabel, label = 'Restaurant', placeholder }: PlacePickerProps) {
  const { token } = useAuth()
  const listId = useId()
  const [query, setQuery] = useState(value?.name ?? '')
  const [suggestions, setSuggestions] = useState<PlaceSuggestion[]>([])
  const [loading, setLoading] = useState(false)
  const [resolving, setResolving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [coords, setCoords] = useState<{ lat: number; lng: number } | null>(null)
  const blurTimer = useRef<number | null>(null)

  useEffect(() => {
    if (!navigator.geolocation) return
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setCoords({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        })
      },
      () => {},
      { maximumAge: 300_000, timeout: 8_000 },
    )
  }, [])

  useEffect(() => {
    if (value) {
      setQuery(value.name)
    }
  }, [value])

  useEffect(() => {
    if (!token || !query.trim() || value?.name === query.trim()) {
      setSuggestions([])
      return
    }

    const timer = window.setTimeout(async () => {
      setLoading(true)
      setError(null)
      try {
        const results = await autocompletePlaces(token, query.trim(), coords ?? undefined)
        setSuggestions(results)
        setOpen(results.length > 0)
      } catch (err) {
        setSuggestions([])
        setError(err instanceof Error ? err.message : 'Search failed')
      } finally {
        setLoading(false)
      }
    }, 300)

    return () => window.clearTimeout(timer)
  }, [coords, query, token, value?.name])

  async function selectSuggestion(suggestion: PlaceSuggestion) {
    if (!token) return
    setResolving(true)
    setError(null)
    try {
      const place = await resolvePlace(token, {
        provider: suggestion.provider,
        providerPlaceId: suggestion.providerPlaceId,
        name: suggestion.name,
        formattedAddress: suggestion.formattedAddress ?? undefined,
        latitude: suggestion.latitude ? Number(suggestion.latitude) : undefined,
        longitude: suggestion.longitude ? Number(suggestion.longitude) : undefined,
      })
      onChange(place)
      setQuery(place.name)
      setSuggestions([])
      setOpen(false)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not resolve place')
    } finally {
      setResolving(false)
    }
  }

  function clearSelection() {
    onChange(null)
    setQuery('')
    setSuggestions([])
    setOpen(false)
  }

  return (
    <div className="place-picker">
      {!hideLabel && <label htmlFor={`${listId}-input`}>{label}</label>}
      {hideLabel && (
        <label htmlFor={`${listId}-input`} className="visually-hidden">
          {label}
        </label>
      )}
      <div className="place-picker-input-row">
        <input
          id={`${listId}-input`}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value)
            if (value) onChange(null)
          }}
          onFocus={() => {
            if (suggestions.length > 0) setOpen(true)
          }}
          onBlur={() => {
            blurTimer.current = window.setTimeout(() => setOpen(false), 150)
          }}
          placeholder={placeholder ?? 'Search restaurants near you'}
          disabled={disabled || resolving}
          autoComplete="off"
          role="combobox"
          aria-expanded={open}
          aria-controls={listId}
        />
        {value && (
          <button type="button" className="btn ghost small" onClick={clearSelection} disabled={disabled}>
            Clear
          </button>
        )}
      </div>
      {(loading || resolving) && <p className="place-picker-hint muted">Searching…</p>}
      {error && <p className="place-picker-error">{error}</p>}
      {value?.previewPhotoUrl && (
        <div className="place-picker-selected-card">
          <PlacePhotoPreview photoUrl={value.previewPhotoUrl} alt="" className="place-picker-selected-photo" />
          <div className="place-picker-selected-body">
            <strong>{value.name}</strong>
            {value.formattedAddress && <p className="muted">{value.formattedAddress}</p>}
          </div>
        </div>
      )}
      {!value?.previewPhotoUrl && value?.formattedAddress && (
        <p className="place-picker-selected muted">{value.formattedAddress}</p>
      )}
      {open && suggestions.length > 0 && (
        <ul id={listId} className="place-picker-suggestions" role="listbox">
          {suggestions.map((suggestion) => (
            <li key={`${suggestion.provider}:${suggestion.providerPlaceId}`}>
              <button
                type="button"
                role="option"
                className="place-picker-suggestion-btn"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  if (blurTimer.current) window.clearTimeout(blurTimer.current)
                  void selectSuggestion(suggestion)
                }}
              >
                {suggestion.previewPhotoUrl && (
                  <PlacePhotoPreview
                    photoUrl={suggestion.previewPhotoUrl}
                    alt=""
                    className="place-picker-suggestion-photo"
                  />
                )}
                <span className="place-picker-suggestion-text">
                  <span className="place-picker-name">{suggestion.name}</span>
                  {suggestion.formattedAddress && (
                    <span className="place-picker-address">{suggestion.formattedAddress}</span>
                  )}
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
      {!value && (
        <p className="place-picker-hint muted">
          {placeholder
            ? 'Pick a restaurant from map search, or leave blank and type the name below.'
            : 'Pick a place from search, or leave blank and type the name below.'}
        </p>
      )}
    </div>
  )
}
