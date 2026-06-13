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
  visibility: PostVisibility
  author: PostAuthor
  tags: ReviewTag[]
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
}

export type SubscriptionSummary = {
  user: UserPublicProfile
  subscribedAt: string
}

type ApiFetchOptions = RequestInit & {
  token?: string | null
}

let onUnauthorized: (() => void) | null = null

export function setUnauthorizedHandler(handler: () => void) {
  onUnauthorized = handler
}

function resolveUrl(path: string) {
  if (path.startsWith('http')) return path
  return `${API_URL}${path}`
}

function authHeaders(token?: string | null): HeadersInit {
  const headers: HeadersInit = {}
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  return headers
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (res.status === 401) {
    onUnauthorized?.()
  }
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
  const res = await fetch(resolveUrl(path), {
    ...rest,
    headers: {
      ...authHeaders(token),
      ...headers,
    },
  })
  return handleResponse<T>(res)
}

export async function register(payload: {
  username: string
  email: string
  password: string
  displayName: string
}): Promise<AuthResponse> {
  return apiFetch('/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
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
  data: { displayName?: string; email?: string; avatar?: File | null },
): Promise<UpdateProfileResponse> {
  if (data.avatar) {
    const form = new FormData()
    if (data.displayName) form.append('displayName', data.displayName)
    if (data.email) form.append('email', data.email)
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
      email: data.email,
    }),
  })
}

export async function fetchPosts(token: string): Promise<SteakPost[]> {
  return apiFetch('/posts', { token })
}

export async function fetchReviewTags(token: string): Promise<ReviewTagCatalog> {
  return apiFetch('/posts/review-tags', { token })
}

export async function fetchFollowingPosts(token: string): Promise<SteakPost[]> {
  return apiFetch('/posts/following', { token })
}

export async function fetchUserPosts(userId: string, token: string): Promise<SteakPost[]> {
  return apiFetch(`/users/${userId}/posts`, { token })
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

export async function fetchPostComments(postId: string, token: string): Promise<PostComment[]> {
  return apiFetch(`/posts/${postId}/comments`, { token })
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

export async function fetchHiddenPosts(token: string): Promise<SteakPost[]> {
  return apiFetch('/posts/hidden', { token })
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

export async function hidePost(token: string, postId: string): Promise<SteakPost> {
  return apiFetch(`/posts/${postId}/hide`, {
    method: 'PATCH',
    token,
  })
}

export async function listUsers(token: string): Promise<UserProfile[]> {
  return apiFetch('/users', { token })
}

export async function updateUserRole(
  token: string,
  userId: string,
  role: string,
): Promise<UserProfile> {
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
