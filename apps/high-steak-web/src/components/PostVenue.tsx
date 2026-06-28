import type { SteakPost } from '../api/client'
import { googleMapsUrlForPlace } from '../utils/googleMaps'
import './PostVenue.css'

type PostVenueProps = {
  post: SteakPost
  className?: string
  showLocation?: boolean
}

export function PostVenue({ post, className = 'post-restaurant', showLocation = true }: PostVenueProps) {
  if (!post.restaurantName) return null

  const locationText = showLocation ? post.restaurantLocation : null
  const mapsUrl = post.place ? googleMapsUrlForPlace(post.place) : null

  if (mapsUrl) {
    return (
      <p className={className}>
        <a
          href={mapsUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="post-venue-link"
          aria-label={`Open ${post.restaurantName} in Google Maps`}
          onClick={(event) => event.stopPropagation()}
        >
          <span className="post-venue-name">{post.restaurantName}</span>
          {locationText && <span className="post-venue-location"> · {locationText}</span>}
          <span className="post-venue-external" aria-hidden="true">
            ↗
          </span>
        </a>
      </p>
    )
  }

  return (
    <p className={className}>
      <span className="post-venue-name">{post.restaurantName}</span>
      {locationText && <span className="post-venue-location"> · {locationText}</span>}
    </p>
  )
}
