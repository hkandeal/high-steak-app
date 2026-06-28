import type { PlaceSummary } from '../api/client'

function coordinateText(value: string | number | null | undefined): string {
  if (value == null) return ''
  return String(value).trim()
}

export function googleMapsUrlForPlace(place: PlaceSummary): string {
  const lat = coordinateText(place.latitude)
  const lng = coordinateText(place.longitude)
  if (lat && lng) {
    return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${lat},${lng}`)}`
  }
  const label = place.formattedAddress
    ? `${place.name}, ${place.formattedAddress}`
    : place.name
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(label)}`
}
