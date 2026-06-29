import { useEffect, useRef } from 'react'
import L from 'leaflet'
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet'
import { Link } from 'react-router-dom'
import type { PlaceNearbySummary } from '../api/client'
import { postImageUrl } from '../api/client'
import { CachedImage } from './CachedImage'
import { StarRating } from './StarRating'
import type { LatLng } from '../hooks/useUserLocation'
import 'leaflet/dist/leaflet.css'
import './ExploreMap.css'

const DEFAULT_CENTER: LatLng = { lat: 25.2048, lng: 55.2708 }

const userIcon = L.divIcon({
  className: 'explore-user-marker',
  html: '<span class="explore-user-marker-dot" aria-hidden="true"></span>',
  iconSize: [20, 20],
  iconAnchor: [10, 10],
})

function placeIcon(place: PlaceNearbySummary) {
  const hasReviews = place.postCount > 0
  const label = hasReviews
    ? (place.avgRating != null ? place.avgRating.toFixed(1) : '★')
    : '◆'
  return L.divIcon({
    className: hasReviews ? 'explore-place-marker' : 'explore-place-marker explore-place-marker--empty',
    html: `<span class="explore-place-marker-pin">${label}</span>`,
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -20],
  })
}

function MapFlyTo({
  center,
  zoom,
  active,
  forceKey,
}: {
  center: LatLng
  zoom?: number
  active: boolean
  forceKey?: number
}) {
  const map = useMap()
  const lastKey = useRef('')
  useEffect(() => {
    if (!active) return
    const key = `${forceKey ?? 0}:${center.lat},${center.lng}`
    if (lastKey.current === key) return
    lastKey.current = key
    map.flyTo([center.lat, center.lng], zoom ?? Math.max(map.getZoom(), 13), { duration: 0.8 })
  }, [active, center.lat, center.lng, zoom, map, forceKey])
  return null
}

type ExploreMapProps = {
  center: LatLng
  userCoords: LatLng | null
  places: PlaceNearbySummary[]
  selectedPlaceId?: string
  onLocateMe: () => void
  locating: boolean
  flyToCenter?: boolean
  flyKey?: number
}

export function ExploreMap({
  center,
  userCoords,
  places,
  selectedPlaceId,
  onLocateMe,
  locating,
  flyToCenter = true,
  flyKey,
}: ExploreMapProps) {
  const mapCenter = center ?? DEFAULT_CENTER

  return (
    <div className="explore-map-shell">
      <button
        type="button"
        className="explore-map-locate btn ghost"
        onClick={onLocateMe}
        disabled={locating}
        title="Center on my location"
        aria-label="Center on my location"
      >
        {locating ? '…' : '◎'}
      </button>
      <MapContainer
        center={[mapCenter.lat, mapCenter.lng]}
        zoom={13}
        className="explore-map"
        scrollWheelZoom
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <MapFlyTo center={mapCenter} active={flyToCenter} forceKey={flyKey} />
        {userCoords && (
          <Marker position={[userCoords.lat, userCoords.lng]} icon={userIcon}>
            <Popup>You are here</Popup>
          </Marker>
        )}
        {places.map((place) => {
          const lat = Number(place.latitude)
          const lng = Number(place.longitude)
          if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null
          return (
            <Marker
              key={place.id}
              position={[lat, lng]}
              icon={placeIcon(place)}
              zIndexOffset={place.id === selectedPlaceId ? 1000 : 0}
            >
              <Popup>
                <div className="explore-map-popup">
                  {place.coverImageUrl && (
                    <CachedImage
                      src={postImageUrl(place.coverImageUrl)}
                      alt=""
                      className="explore-map-popup-cover"
                    />
                  )}
                  {place.coverImageSource === 'GOOGLE' && (
                    <p className="explore-photo-attribution">Photos © Google</p>
                  )}
                  <strong>{place.name}</strong>
                  {place.formattedAddress && (
                    <p className="explore-map-popup-address">{place.formattedAddress}</p>
                  )}
                  <div className="explore-map-popup-meta">
                    {place.postCount > 0 ? (
                      <>
                        {place.avgRating != null && (
                          <StarRating value={Math.round(place.avgRating)} readOnly />
                        )}
                        <span>
                          {place.postCount} review{place.postCount === 1 ? '' : 's'}
                        </span>
                      </>
                    ) : (
                      <span className="explore-map-popup-empty">No community reviews yet</span>
                    )}
                  </div>
                  {place.postCount > 0 ? (
                    <Link to={`/explore/${place.id}`} className="explore-map-popup-link">
                      View posts
                    </Link>
                  ) : (
                    <Link to={`/post/new?placeId=${place.id}`} className="explore-map-popup-link">
                      Be the first to rate
                    </Link>
                  )}
                </div>
              </Popup>
            </Marker>
          )
        })}
      </MapContainer>
    </div>
  )
}

export { DEFAULT_CENTER }
