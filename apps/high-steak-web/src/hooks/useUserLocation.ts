import { useCallback, useRef, useState } from 'react'

export type LatLng = { lat: number; lng: number }

const STORAGE_KEY = 'highsteak:explore:lastCoords'

function readStoredCoords(): LatLng | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY) ?? sessionStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as LatLng
    if (typeof parsed.lat === 'number' && typeof parsed.lng === 'number') {
      return parsed
    }
  } catch {
    // ignore corrupt cache
  }
  return null
}

function persistCoords(coords: LatLng) {
  const raw = JSON.stringify(coords)
  localStorage.setItem(STORAGE_KEY, raw)
  sessionStorage.setItem(STORAGE_KEY, raw)
}

function geoErrorMessage(code: number) {
  switch (code) {
    case 1:
      return 'Location is blocked in your browser. Enable it in site settings, then tap the locate button on the map.'
    case 2:
      return 'Could not detect your location. Search for a restaurant above, or tap ◎ on the map to try again.'
    case 3:
      return 'Finding your location timed out. Tap the locate button on the map to try again.'
    default:
      return 'Could not get your location. Search for a restaurant or tap the locate button on the map.'
  }
}

function getCurrentPosition(options: PositionOptions): Promise<GeolocationPosition> {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, options)
  })
}

export function useUserLocation() {
  const [coords, setCoords] = useState<LatLng | null>(readStoredCoords)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [locationRequested, setLocationRequested] = useState(false)
  const watchId = useRef<number | null>(null)
  const inFlight = useRef(false)

  const clearWatch = useCallback(() => {
    if (watchId.current != null) {
      navigator.geolocation.clearWatch(watchId.current)
      watchId.current = null
    }
  }, [])

  const applyPosition = useCallback((lat: number, lng: number) => {
    const next = { lat, lng }
    setCoords(next)
    persistCoords(next)
    setError(null)
    setLoading(false)
    inFlight.current = false
  }, [])

  const requestLocation = useCallback(() => {
    setLocationRequested(true)
    if (!window.isSecureContext) {
      setError(
        'Location only works on https:// or http://localhost. Open the app at http://localhost:5173 instead of an IP address.',
      )
      return
    }
    if (!navigator.geolocation) {
      setError('Location is not supported in this browser.')
      return
    }

    clearWatch()
    inFlight.current = true
    setLoading(true)
    setError(null)

    void (async () => {
      const attempts: PositionOptions[] = [
        { enableHighAccuracy: false, maximumAge: 300_000, timeout: 12_000 },
        { enableHighAccuracy: true, maximumAge: 60_000, timeout: 25_000 },
      ]

      let lastCode = 0
      for (const options of attempts) {
        try {
          const position = await getCurrentPosition(options)
          applyPosition(position.coords.latitude, position.coords.longitude)
          return
        } catch (err) {
          lastCode = (err as GeolocationPositionError).code ?? 0
        }
      }

      inFlight.current = false
      setLoading(false)
      const cached = readStoredCoords()
      if (cached) {
        setCoords(cached)
        setError(
          geoErrorMessage(lastCode) +
            ' Showing your last known area — tap ◎ to retry.',
        )
        return
      }
      setError(geoErrorMessage(lastCode))
    })()
  }, [applyPosition, clearWatch])

  return {
    coords,
    loading,
    error,
    locationRequested,
    requestLocation,
  }
}

export const BROWSE_CENTER_KEY = 'highsteak:explore:browseCenter'

export function readBrowseCenter(): LatLng | null {
  try {
    const raw = localStorage.getItem(BROWSE_CENTER_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as LatLng
    if (typeof parsed.lat === 'number' && typeof parsed.lng === 'number') {
      return parsed
    }
  } catch {
    // ignore corrupt cache
  }
  return null
}

export function persistBrowseCenter(center: LatLng) {
  localStorage.setItem(BROWSE_CENTER_KEY, JSON.stringify(center))
}
