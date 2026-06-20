const API_URL = import.meta.env.VITE_API_URL ?? ''

export type UserProfile = {
  id: string
  username: string
  email: string
  displayName: string
  avatarUrl: string | null
}

/** Client-side user: profile fields plus role/scopes from JWT only. */
export type UserSummary = UserProfile & {
  role: string
  scopes: string[]
}

/** Admin list entry from GET /users (includes role; not used for /auth/me). */
export type AdminUser = UserProfile & {
  role: string
  blocked: boolean
}

type JwtPayload = {
  sub?: string
  uid?: string
  email?: string
  displayName?: string
  avatarUrl?: string | null
  roles?: string[]
  scopes?: string[]
}

export function parseUserFromToken(token: string): UserSummary {
  const payloadSegment = token.split('.')[1]
  if (!payloadSegment) {
    throw new Error('Invalid token')
  }
  const normalized = payloadSegment.replace(/-/g, '+').replace(/_/g, '/')
  const payload = JSON.parse(atob(normalized)) as JwtPayload
  return {
    id: payload.uid ?? '',
    username: payload.sub ?? '',
    email: payload.email ?? '',
    displayName: payload.displayName ?? '',
    avatarUrl: payload.avatarUrl ?? null,
    role: payload.roles?.[0] ?? 'USER',
    scopes: payload.scopes ?? [],
  }
}

/** Merge API profile with authorization claims from the JWT. */
export function mergeUserWithToken(token: string, profile: UserProfile): UserSummary {
  const claims = parseUserFromToken(token)
  return {
    ...profile,
    role: claims.role,
    scopes: claims.scopes,
  }
}

export type AuthResponse = {
  token: string
  refreshToken: string
}

type SessionHandlers = {
  getRefreshToken: () => string | null
  onSessionRefreshed: (response: AuthResponse) => void
  onLogout: () => void
}

const REFRESH_BUFFER_MS = 5 * 60 * 1000
const AUTH_REFRESH_PATHS = [
  '/auth/refresh',
  '/auth/login',
  '/auth/register',
  '/auth/logout',
  '/auth/verify-email',
]

export type RegisterResponse = {
  verificationRequired: boolean
  message: string
  email: string
  token: string | null
  refreshToken: string | null
}

export async function register(payload: {
  username: string
  email: string
  password: string
  displayName: string
}): Promise<RegisterResponse> {
  return apiFetch('/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
}

export async function verifyEmail(token: string): Promise<AuthResponse> {
  return apiFetch('/auth/verify-email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token }),
  })
}

export async function resendVerificationEmail(email: string): Promise<void> {
  return apiFetch('/auth/resend-verification', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email }),
  })
}

let onUnauthorized: (() => void) | null = null
let sessionHandlers: SessionHandlers | null = null
let refreshInFlight: Promise<AuthResponse | null> | null = null
let proactiveRefreshTimer: ReturnType<typeof setTimeout> | null = null

export function setUnauthorizedHandler(handler: () => void) {
  onUnauthorized = handler
}

export function setSessionHandlers(handlers: SessionHandlers | null) {
  sessionHandlers = handlers
}

export function getAccessTokenExpiryMs(token: string): number | null {
  try {
    const payloadSegment = token.split('.')[1]
    if (!payloadSegment) return null
    const normalized = payloadSegment.replace(/-/g, '+').replace(/_/g, '/')
    const payload = JSON.parse(atob(normalized)) as { exp?: number }
    return payload.exp ? payload.exp * 1000 : null
  } catch {
    return null
  }
}

export function scheduleProactiveRefresh(token: string, refreshToken: string) {
  if (proactiveRefreshTimer) {
    clearTimeout(proactiveRefreshTimer)
    proactiveRefreshTimer = null
  }
  const expiresAt = getAccessTokenExpiryMs(token)
  if (!expiresAt) return
  const delay = Math.max(expiresAt - Date.now() - REFRESH_BUFFER_MS, 0)
  proactiveRefreshTimer = setTimeout(() => {
  void refreshAccessToken(refreshToken).then((refreshed) => {
      if (!refreshed) {
        sessionHandlers?.onLogout()
        onUnauthorized?.()
      }
    })
  }, delay)
}

export function clearProactiveRefresh() {
  if (proactiveRefreshTimer) {
    clearTimeout(proactiveRefreshTimer)
    proactiveRefreshTimer = null
  }
}

async function refreshAccessToken(refreshToken?: string | null): Promise<AuthResponse | null> {
  const tokenToUse = refreshToken ?? sessionHandlers?.getRefreshToken()
  if (!tokenToUse) return null
  if (refreshInFlight) return refreshInFlight

  refreshInFlight = (async () => {
    try {
      const res = await fetch(resolveUrl('/auth/refresh'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: tokenToUse }),
      })
      if (!res.ok) return null
      const data = (await res.json()) as AuthResponse
      sessionHandlers?.onSessionRefreshed(data)
      return data
    } catch {
      return null
    } finally {
      refreshInFlight = null
    }
  })()

  return refreshInFlight
}

function shouldAttemptRefresh(path: string) {
  return !AUTH_REFRESH_PATHS.some((segment) => path.startsWith(segment))
}

function resolveUrl(path: string) {
  if (path.startsWith('http')) return path
  return `${API_URL}${path}`
}

type ApiFetchOptions = RequestInit & {
  token?: string | null
}

export type PostAuthor = {
  id: string
  displayName: string
}

export type ReviewTag = {
  id: string
  label: string
  sentiment: 'POSITIVE' | 'NEGATIVE'
}

export type ReviewTagCatalog = {
  positive: ReviewTag[]
  negative: ReviewTag[]
}

export type PostVisibility = 'PUBLIC' | 'FOLLOWERS_ONLY'

export type SteakPost = {
  id: string
  title: string
  comment: string | null
  rating: number
  imageUrls: string[]
  restaurantName: string | null
  restaurantLocation: string | null
  createdAt: string
  hidden: boolean
  moderationReason?: string | null
  moderationRestoredAt?: string | null
  visibility: PostVisibility
  author: PostAuthor
  tags: ReviewTag[]
  bookmarked?: boolean
}

export type PostComment = {
  id: string
  body: string
  createdAt: string
  author: PostAuthor
}

export type UserPublicProfile = {
  id: string
  username: string
  displayName: string
  avatarUrl: string | null
  postCount: number
  subscribed: boolean
  blocked?: boolean | null
  role?: string | null
}

export type PageResponse<T> = {
  content: T[]
  page: number
  size: number
  totalElements: number
  totalPages: number
}

export type SubscriptionSummary = {
  user: UserPublicProfile
  subscribedAt: string
}

function authHeaders(token?: string | null): HeadersInit {
  const headers: HeadersInit = {}
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  return headers
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.message ?? res.statusText)
  }
  if (res.status === 204) {
    return undefined as T
  }
  return res.json() as Promise<T>
}

export async function apiFetch<T>(path: string, options: ApiFetchOptions = {}): Promise<T> {
  const { token, headers, ...rest } = options

  const performRequest = async (activeToken?: string | null) => {
    return fetch(resolveUrl(path), {
      ...rest,
      headers: {
        ...authHeaders(activeToken ?? token),
        ...headers,
      },
    })
  }

  let res = await performRequest(token)
  if (res.status === 401 && shouldAttemptRefresh(path)) {
    const refreshed = await refreshAccessToken()
    if (refreshed) {
      res = await performRequest(refreshed.token)
    } else {
      sessionHandlers?.onLogout()
      onUnauthorized?.()
    }
  }

  return handleResponse<T>(res)
}

export async function logoutSession(refreshToken: string | null | undefined) {
  if (!refreshToken) return
  try {
    await fetch(resolveUrl('/auth/logout'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    })
  } catch {
    // Best-effort server logout.
  }
}

export async function login(payload: {
  username: string
  password: string
}): Promise<AuthResponse> {
  return apiFetch('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
}

export type AvailabilityResponse = {
  available: boolean
  message: string
}

export async function checkUsernameAvailability(username: string): Promise<AvailabilityResponse> {
  const params = new URLSearchParams({ username })
  return apiFetch(`/auth/check-username?${params}`)
}

export async function checkEmailAvailability(email: string): Promise<AvailabilityResponse> {
  const params = new URLSearchParams({ email })
  return apiFetch(`/auth/check-email?${params}`)
}

export async function getMe(token: string): Promise<UserProfile> {
  return apiFetch('/auth/me', { token })
}

export type UpdateProfileResponse = {
  token: string
  user: UserProfile
}

export async function updateProfile(
  token: string,
  data: { displayName?: string; avatar?: File | null },
): Promise<UpdateProfileResponse> {
  if (data.avatar) {
    const form = new FormData()
    if (data.displayName) form.append('displayName', data.displayName)
    form.append('avatar', data.avatar)
    return apiFetch('/auth/me', {
      method: 'PATCH',
      token,
      body: form,
    })
  }
  return apiFetch('/auth/me', {
    method: 'PATCH',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      displayName: data.displayName,
    }),
  })
}

export const FEED_PAGE_SIZE = 20

function paginationQuery(options: { page?: number; size?: number } = {}) {
  const params = new URLSearchParams()
  if (options.page != null) params.set('page', String(options.page))
  if (options.size != null) params.set('size', String(options.size))
  const query = params.toString()
  return query ? `?${query}` : ''
}

export async function fetchPosts(
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/posts${paginationQuery(options)}`, { token })
}

export async function fetchReviewTags(token: string): Promise<ReviewTagCatalog> {
  return apiFetch('/posts/review-tags', { token })
}

export async function fetchFollowingPosts(
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/posts/following${paginationQuery(options)}`, { token })
}

export async function fetchUserPosts(
  userId: string,
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/users/${userId}/posts${paginationQuery(options)}`, { token })
}

export async function fetchUserProfile(
  userId: string,
  token?: string | null,
): Promise<UserPublicProfile> {
  return apiFetch(`/users/${userId}`, { token })
}

export async function fetchPost(postId: string, token: string): Promise<SteakPost> {
  return apiFetch(`/posts/${postId}`, { token })
}

export async function fetchPostComments(
  postId: string,
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<PostComment>> {
  return apiFetch(`/posts/${postId}/comments${paginationQuery(options)}`, { token })
}

export async function addPostComment(
  token: string,
  postId: string,
  body: string,
): Promise<PostComment> {
  return apiFetch(`/posts/${postId}/comments`, {
    method: 'POST',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ body }),
  })
}

export async function searchUsers(token: string, q: string): Promise<UserPublicProfile[]> {
  const params = new URLSearchParams({ q })
  return apiFetch(`/users/search?${params}`, { token })
}

export async function listSubscriptions(token: string): Promise<SubscriptionSummary[]> {
  return apiFetch('/subscriptions', { token })
}

export async function subscribeToUser(token: string, userId: string): Promise<SubscriptionSummary> {
  return apiFetch(`/subscriptions/${userId}`, {
    method: 'POST',
    token,
  })
}

export async function unsubscribeFromUser(token: string, userId: string): Promise<void> {
  return apiFetch(`/subscriptions/${userId}`, {
    method: 'DELETE',
    token,
  })
}

export async function fetchHiddenPosts(
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/posts/hidden${paginationQuery(options)}`, { token })
}

export async function fetchMyPosts(
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/posts/mine${paginationQuery(options)}`, { token })
}

export async function fetchBookmarkedPosts(
  token: string,
  options: { page?: number; size?: number } = {},
): Promise<PageResponse<SteakPost>> {
  return apiFetch(`/bookmarks${paginationQuery(options)}`, { token })
}

export async function bookmarkPost(token: string, postId: string): Promise<void> {
  return apiFetch(`/posts/${postId}/bookmark`, {
    method: 'POST',
    token,
  })
}

export async function unbookmarkPost(token: string, postId: string): Promise<void> {
  return apiFetch(`/posts/${postId}/bookmark`, {
    method: 'DELETE',
    token,
  })
}

export type NotificationPreferences = {
  emailEnabled: boolean
  welcomeEmail: boolean
  commentEmail: boolean
  followerEmail: boolean
  moderationEmail: boolean
}

export type UpdateNotificationPreferences = Partial<NotificationPreferences>

export async function fetchNotificationPreferences(
  token: string,
): Promise<NotificationPreferences> {
  return apiFetch('/users/me/notification-preferences', { token })
}

export async function updateNotificationPreferences(
  token: string,
  patch: UpdateNotificationPreferences,
): Promise<NotificationPreferences> {
  return apiFetch('/users/me/notification-preferences', {
    method: 'PATCH',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(patch),
  })
}

export async function fetchMyModerationNotices(token: string): Promise<SteakPost[]> {
  return apiFetch('/posts/mine/moderation-notices', { token })
}

export async function createPost(
  token: string,
  data: {
    title: string
    comment: string
    rating: number
    restaurantName?: string
    restaurantLocation?: string
    visibility?: PostVisibility
    images: File[]
    tagIds?: string[]
  },
): Promise<SteakPost> {
  const form = new FormData()
  form.append('title', data.title)
  form.append('comment', data.comment)
  form.append('rating', String(data.rating))
  if (data.restaurantName) form.append('restaurantName', data.restaurantName)
  if (data.restaurantLocation) form.append('restaurantLocation', data.restaurantLocation)
  if (data.visibility) form.append('visibility', data.visibility)
  data.images.forEach((image) => form.append('images', image))
  data.tagIds?.forEach((tagId) => form.append('tagIds', tagId))

  return apiFetch('/posts', {
    method: 'POST',
    token,
    body: form,
  })
}

export async function updatePost(
  token: string,
  postId: string,
  data: {
    title: string
    comment: string
    rating: number
    restaurantName?: string
    restaurantLocation?: string
    visibility?: PostVisibility
    keepImageUrls: string[]
    newImages: File[]
    tagIds?: string[]
  },
): Promise<SteakPost> {
  const form = new FormData()
  form.append('title', data.title)
  form.append('comment', data.comment)
  form.append('rating', String(data.rating))
  if (data.restaurantName) form.append('restaurantName', data.restaurantName)
  if (data.restaurantLocation) form.append('restaurantLocation', data.restaurantLocation)
  if (data.visibility) form.append('visibility', data.visibility)
  data.keepImageUrls.forEach((url) => form.append('keepImageUrls', url))
  data.newImages.forEach((image) => form.append('images', image))
  data.tagIds?.forEach((tagId) => form.append('tagIds', tagId))

  return apiFetch(`/posts/${postId}`, {
    method: 'PATCH',
    token,
    body: form,
  })
}

export async function deletePost(token: string, postId: string): Promise<void> {
  return apiFetch(`/posts/${postId}`, {
    method: 'DELETE',
    token,
  })
}

export async function hidePost(
  token: string,
  postId: string,
  reason?: string,
): Promise<SteakPost> {
  const trimmed = reason?.trim()
  return apiFetch(`/posts/${postId}/hide`, {
    method: 'PATCH',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reason: trimmed || null }),
  })
}

export async function unhidePost(token: string, postId: string): Promise<SteakPost> {
  return apiFetch(`/posts/${postId}/unhide`, {
    method: 'PATCH',
    token,
  })
}

export async function listUsers(
  token: string,
  options: { q?: string; page?: number; size?: number } = {},
): Promise<PageResponse<AdminUser>> {
  const params = new URLSearchParams()
  if (options.q?.trim()) params.set('q', options.q.trim())
  if (options.page != null) params.set('page', String(options.page))
  if (options.size != null) params.set('size', String(options.size))
  const query = params.toString()
  return apiFetch(`/users${query ? `?${query}` : ''}`, { token })
}

export async function setUserBlocked(
  token: string,
  userId: string,
  blocked: boolean,
): Promise<AdminUser> {
  return apiFetch(`/users/${userId}/blocked`, {
    method: 'PATCH',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ blocked }),
  })
}

export async function updateUserRole(
  token: string,
  userId: string,
  role: string,
): Promise<AdminUser> {
  return apiFetch(`/users/${userId}/role`, {
    method: 'PATCH',
    token,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ role }),
  })
}

export function postImageUrl(imageUrl: string) {
  return resolveUrl(imageUrl)
}

export function primaryPostImage(post: SteakPost) {
  return post.imageUrls[0] ?? ''
}
