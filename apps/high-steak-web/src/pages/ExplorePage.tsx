import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  fetchNearbyPlaces,
  fetchPlace,
  fetchPlacePosts,
  postImageUrl,
  primaryPostImage,
  type PlaceNearbySummary,
  type PlaceSummary,
  type SteakPost,
} from '../api/client'
import { PageBackLink } from '../components/BackLink'
import { DEFAULT_CENTER, ExploreMap } from '../components/ExploreMap'
import { PlacePicker } from '../components/PlacePicker'
import { StarRating } from '../components/StarRating'
import { useAuth } from '../context/AuthContext'
import {
  persistBrowseCenter,
  readBrowseCenter,
  useUserLocation,
  type LatLng,
} from '../hooks/useUserLocation'
import './ExplorePage.css'

type ExploreMode = 'browse' | 'search'

function placeFromSummary(
  place: PlaceSummary,
  postCount = 0,
  avgRating: number | null = null,
): PlaceNearbySummary {
  return {
    id: place.id,
    name: place.name,
    formattedAddress: place.formattedAddress,
    latitude: place.latitude,
    longitude: place.longitude,
    distanceM: 0,
    postCount,
    avgRating,
    coverImageUrl: place.previewPhotoUrl,
    coverImageSource: place.previewPhotoSource,
  }
}

export function ExplorePage() {
  const { placeId } = useParams<{ placeId?: string }>()
  const { token } = useAuth()
  const { coords: userCoords, loading: geoLoading, error: geoError, locationRequested, requestLocation } =
    useUserLocation()

  const [mode, setMode] = useState<ExploreMode>('browse')
  const [mapFocus, setMapFocus] = useState<LatLng>(() => readBrowseCenter() ?? userCoords ?? DEFAULT_CENTER)
  const [flyMap, setFlyMap] = useState(false)
  const mapInitialized = useRef(false)
  const autoLocateOnce = useRef(false)
  const [savedCenter, setSavedCenter] = useState<LatLng | null>(readBrowseCenter)
  const [searchPlace, setSearchPlace] = useState<PlaceSummary | null>(null)
  const [searchedPin, setSearchedPin] = useState<PlaceNearbySummary | null>(null)
  const [nearbyPlaces, setNearbyPlaces] = useState<PlaceNearbySummary[]>([])
  const [selectedPlace, setSelectedPlace] = useState<PlaceNearbySummary | null>(null)
  const [posts, setPosts] = useState<SteakPost[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const browseCenter = useMemo<LatLng | null>(
    () => savedCenter ?? userCoords,
    [savedCenter, userCoords],
  )

  useEffect(() => {
    if (userCoords) {
      persistBrowseCenter(userCoords)
      setSavedCenter(userCoords)
    }
  }, [userCoords])

  useEffect(() => {
    if (placeId || autoLocateOnce.current) return
    autoLocateOnce.current = true
    requestLocation()
  }, [placeId, requestLocation])

  useEffect(() => {
    if (placeId || mode === 'search' || !browseCenter || mapInitialized.current) return
    mapInitialized.current = true
    setMapFocus(browseCenter)
    setFlyMap(true)
  }, [browseCenter, mode, placeId])

  const loadNearbyPins = useCallback(async () => {
    if (!token || !browseCenter || mode !== 'browse') return
    setLoading(true)
    setError(null)
    try {
      const page = await fetchNearbyPlaces(token, browseCenter, { radiusM: 50_000, size: 50 })
      setNearbyPlaces(page.content)
    } catch (err) {
      setNearbyPlaces([])
      setError(err instanceof Error ? err.message : 'Failed to load nearby places')
    } finally {
      setLoading(false)
    }
  }, [browseCenter, mode, token])

  useEffect(() => {
    if (placeId || mode !== 'browse') return
    if (!browseCenter) {
      setNearbyPlaces([])
      return
    }
    void loadNearbyPins()
  }, [browseCenter, loadNearbyPins, mode, placeId])

  const mapPlaces = useMemo(
    () => (mode === 'search' && searchedPin ? [searchedPin] : nearbyPlaces),
    [mode, nearbyPlaces, searchedPin],
  )

  useEffect(() => {
    if (!placeId || !token) {
      setSelectedPlace(null)
      setPosts([])
      return
    }
    setLoading(true)
    setError(null)
    Promise.all([fetchPlace(token, placeId), fetchPlacePosts(token, placeId)])
      .then(([place, page]) => {
        setSelectedPlace(placeFromSummary(place, page.totalElements))
        setPosts(page.content)
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load place'))
      .finally(() => setLoading(false))
  }, [placeId, token])

  async function handleSearchPlace(place: PlaceSummary | null) {
    setSearchPlace(place)
    if (!place || !token) {
      setSearchedPin(null)
      setMode('browse')
      return
    }

    setMode('search')
    const center = {
      lat: Number(place.latitude),
      lng: Number(place.longitude),
    }
    persistBrowseCenter(center)
    setSavedCenter(center)
    setMapFocus(center)
    setFlyMap(true)
    setLoading(true)
    setError(null)

    try {
      const [nearbyPage, postsPage] = await Promise.all([
        fetchNearbyPlaces(token, center, { radiusM: 2_000, size: 50 }),
        fetchPlacePosts(token, place.id, { size: 1 }),
      ])
      const communityMatch = nearbyPage.content.find((item) => item.id === place.id)
      if (communityMatch) {
        setSearchedPin(communityMatch)
      } else {
        setSearchedPin(placeFromSummary(place, postsPage.totalElements))
      }
    } catch (err) {
      setSearchedPin(placeFromSummary(place, 0))
      setError(err instanceof Error ? err.message : 'Failed to load restaurant')
    } finally {
      setLoading(false)
    }
  }

  function handleLocateMe() {
    setSearchPlace(null)
    setSearchedPin(null)
    setMode('browse')
    mapInitialized.current = false
    setFlyMap(true)
    if (userCoords) {
      setMapFocus(userCoords)
    }
    requestLocation()
  }

  const usingFallbackArea = !userCoords && !!savedCenter

  if (placeId) {
    return (
      <section className="explore-page">
        <PageBackLink defaultTo="/explore" defaultLabel="Back to map" />

        {loading && <p className="muted">Loading place…</p>}
        {error && <p className="form-error">{error}</p>}

        {selectedPlace && (
          <>
            <header className="explore-place-detail">
              <h1>{selectedPlace.name}</h1>
              {selectedPlace.formattedAddress && <p>{selectedPlace.formattedAddress}</p>}
            </header>
            <ExploreMap
              center={{
                lat: Number(selectedPlace.latitude),
                lng: Number(selectedPlace.longitude),
              }}
              userCoords={userCoords}
              places={[selectedPlace]}
              selectedPlaceId={placeId}
              onLocateMe={handleLocateMe}
              locating={geoLoading}
            />
          </>
        )}

        <div className="explore-post-list">
          {posts.length === 0 && !loading && (
            <p className="muted">No public posts at this place yet.</p>
          )}
          {posts.map((post) => (
            <Link key={post.id} to={`/posts/${post.id}`} className="explore-post-card">
              {primaryPostImage(post) && (
                <img src={postImageUrl(primaryPostImage(post)!)} alt="" />
              )}
              <div>
                <h3>{post.title}</h3>
                <StarRating value={post.rating} readOnly />
                {post.author?.displayName && (
                  <p className="muted">by {post.author.displayName}</p>
                )}
              </div>
            </Link>
          ))}
        </div>
      </section>
    )
  }

  return (
    <section className="explore-page explore-page-map-only">
      <header className="explore-header">
        <h1>Explore</h1>
        <p>
          {mode === 'search'
            ? 'Showing your searched restaurant. Clear search to see all nearby reviews.'
            : 'Pins are steakhouses with community reviews near you.'}
        </p>
      </header>

      <div className="explore-toolbar">
        <PlacePicker
          value={searchPlace}
          onChange={(place) => {
            void handleSearchPlace(place)
          }}
          label="Search on map"
          placeholder="Search restaurants on the map…"
        />
      </div>

      <ExploreMap
        center={mapFocus}
        userCoords={userCoords}
        places={mapPlaces}
        selectedPlaceId={searchedPin?.id}
        onLocateMe={handleLocateMe}
        locating={geoLoading}
        flyToCenter={flyMap}
      />

      {loading && <p className="muted explore-map-status">Loading map…</p>}
      {!browseCenter && !locationRequested && (
        <p className="muted explore-map-status">Finding your location to show nearby steakhouses…</p>
      )}
      {usingFallbackArea && geoError && (
        <p className="explore-geo-hint muted">
          Live GPS unavailable — showing reviews near your last searched area. Tap ◎ to retry location.
        </p>
      )}
      {locationRequested && geoError && !browseCenter && (
        <p className="explore-geo-hint">{geoError}</p>
      )}
      {error && <p className="form-error">{error}</p>}
      {!loading && mode === 'browse' && browseCenter && nearbyPlaces.length === 0 && !error && (
        <p className="muted explore-map-status">
          No tagged steakhouses in this area yet. Search for a restaurant or rate a steak to add the first pin.
        </p>
      )}
    </section>
  )
}
