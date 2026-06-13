/**
 * Field limits aligned with apps/high-steak-api/openapi/openapi.yaml and database columns.
 */
export const API_CONSTRAINTS = {
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
  maxImageBytes: 1_048_576,
  postVisibility: ['PUBLIC', 'FOLLOWERS_ONLY'] as const,
} as const

export const MAX_IMAGE_MB = API_CONSTRAINTS.maxImageBytes / 1_048_576
