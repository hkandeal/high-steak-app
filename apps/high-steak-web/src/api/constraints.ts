/**
 * Field limits aligned with apps/high-steak-api/openapi/openapi.yaml and database columns.
 * Image size is loaded from GET /config at startup (Helm `uploads.maxImageSizeMb`), with
 * VITE_MAX_IMAGE_SIZE_MB as a build-time fallback when the API is unreachable.
 */
const API_URL = import.meta.env.VITE_API_URL ?? ''

function resolveMaxImageSizeMbFromBuild(): number {
  const parsed = Number(import.meta.env.VITE_MAX_IMAGE_SIZE_MB)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 5
}

function buildConstraints(maxImageSizeMb: number) {
  return {
    username: { min: 3, max: 50 },
    email: { max: 255 },
    password: { min: 8, max: 100 },
    displayName: { min: 2, max: 100 },
    postTitle: { min: 1, max: 120 },
    postComment: { max: 65_535 },
    restaurantName: { max: 120 },
    restaurantLocation: { max: 255 },
    commentBody: { min: 1, max: 2_000 },
    searchQuery: { min: 2, max: 100 },
    maxReviewTags: 12,
    maxImageBytes: maxImageSizeMb * 1_048_576,
    postVisibility: ['PUBLIC', 'FOLLOWERS_ONLY'] as const,
  } as const
}

export let MAX_IMAGE_MB = resolveMaxImageSizeMbFromBuild()
export let API_CONSTRAINTS = buildConstraints(MAX_IMAGE_MB)

type AppConfigResponse = {
  maxImageSizeMb?: number
  maxImagesPerPost?: number
  maxImageBytes?: number
}

export async function loadConstraintsFromApi(): Promise<void> {
  if (!API_URL) return

  try {
    const response = await fetch(`${API_URL}/config`)
    if (!response.ok) return

    const config = (await response.json()) as AppConfigResponse
    const maxImageSizeMb = Number(config.maxImageSizeMb)
    if (!Number.isFinite(maxImageSizeMb) || maxImageSizeMb <= 0) return

    MAX_IMAGE_MB = maxImageSizeMb
    API_CONSTRAINTS = buildConstraints(maxImageSizeMb)
  } catch {
    // Keep build-time fallback when offline or API unavailable.
  }
}
