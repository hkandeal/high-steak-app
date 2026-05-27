const API_URL = import.meta.env.VITE_API_URL ?? ''

export type UserSummary = {
  id: number
  username: string
  email: string
  displayName: string
  avatarUrl: string | null
}

export type AuthResponse = {
  token: string
  user: UserSummary
}

export type SteakPost = {
  id: number
  title: string
  comment: string | null
  rating: number
  imageUrl: string
  createdAt: string
  author: UserSummary
}

function authHeaders(token?: string | null): HeadersInit {
  const headers: HeadersInit = {}
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  return headers
}

function resolveUrl(path: string) {
  if (path.startsWith('http')) return path
  return `${API_URL}${path}`
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.message ?? res.statusText)
  }
  return res.json() as Promise<T>
}

export async function register(payload: {
  username: string
  email: string
  password: string
  displayName: string
}): Promise<AuthResponse> {
  const res = await fetch(resolveUrl('/api/auth/register'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  return handleResponse(res)
}

export async function login(payload: {
  username: string
  password: string
}): Promise<AuthResponse> {
  const res = await fetch(resolveUrl('/api/auth/login'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  return handleResponse(res)
}

export async function fetchPosts(): Promise<SteakPost[]> {
  const res = await fetch(resolveUrl('/api/posts'))
  return handleResponse(res)
}

export async function createPost(
  token: string,
  data: { title: string; comment: string; rating: number; image: File },
): Promise<SteakPost> {
  const form = new FormData()
  form.append('title', data.title)
  form.append('comment', data.comment)
  form.append('rating', String(data.rating))
  form.append('image', data.image)

  const res = await fetch(resolveUrl('/api/posts'), {
    method: 'POST',
    headers: authHeaders(token),
    body: form,
  })
  return handleResponse(res)
}

export function postImageUrl(imageUrl: string) {
  return resolveUrl(imageUrl)
}
