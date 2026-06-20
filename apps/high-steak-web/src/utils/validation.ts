import { API_CONSTRAINTS, MAX_IMAGE_MB } from '../api/constraints'

const USERNAME_PATTERN = /^[a-zA-Z][a-zA-Z0-9_-]*$/
const EMAIL_PATTERN = /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/

export function sanitizeUsernameInput(value: string): string {
  let next = value.replace(/[^a-zA-Z0-9_-]/g, '')
  if (next.length > 0 && /^[0-9]/.test(next)) {
    next = next.replace(/^[0-9]+/, '')
  }
  return next.slice(0, API_CONSTRAINTS.username.max)
}

export function validateUsernameFormat(username: string): string | null {
  const trimmed = username.trim()
  if (!trimmed) return 'Username is required.'
  if (trimmed.length < API_CONSTRAINTS.username.min) {
    return `Username must be at least ${API_CONSTRAINTS.username.min} characters.`
  }
  if (trimmed.length > API_CONSTRAINTS.username.max) {
    return `Username must be at most ${API_CONSTRAINTS.username.max} characters.`
  }
  if (/^[0-9]/.test(trimmed)) {
    return 'Username must not start with a number.'
  }
  if (!USERNAME_PATTERN.test(trimmed)) {
    return 'Username can only contain letters, numbers, underscores, and hyphens.'
  }
  return null
}

export function validateEmailFormat(email: string): string | null {
  const trimmed = email.trim()
  if (!trimmed) return 'Email is required.'
  if (trimmed.length > API_CONSTRAINTS.email.max) {
    return `Email must be at most ${API_CONSTRAINTS.email.max} characters.`
  }
  if (!EMAIL_PATTERN.test(trimmed)) {
    return 'Enter a valid email address.'
  }
  return null
}

export function validateImageFile(file: File): string | null {
  if (!file.type.startsWith('image/')) {
    return `"${file.name}" must be an image file.`
  }
  if (file.size > API_CONSTRAINTS.maxImageBytes) {
    return `"${file.name}" is too large. Each image must be ${MAX_IMAGE_MB} MB or smaller.`
  }
  return null
}

export function validateImageFiles(files: File[]): string | null {
  for (const file of files) {
    const error = validateImageFile(file)
    if (error) return error
  }
  return null
}

export function validateTextLength(
  value: string,
  label: string,
  options: { min?: number; max: number; required?: boolean },
): string | null {
  const trimmed = value.trim()
  if (options.required && trimmed.length === 0) {
    return `${label} is required.`
  }
  if (options.min != null && trimmed.length > 0 && trimmed.length < options.min) {
    return `${label} must be at least ${options.min} characters.`
  }
  if (trimmed.length > options.max) {
    return `${label} must be at most ${options.max} characters.`
  }
  return null
}

export function validatePostForm(input: {
  title: string
  comment: string
  restaurantName: string
  restaurantLocation: string
  newImages: File[]
  totalImages: number
}): string | null {
  const titleError = validateTextLength(input.title, 'Title', {
    required: true,
    min: API_CONSTRAINTS.postTitle.min,
    max: API_CONSTRAINTS.postTitle.max,
  })
  if (titleError) return titleError

  const commentError = validateTextLength(input.comment, 'Comment', {
    max: API_CONSTRAINTS.postComment.max,
  })
  if (commentError) return commentError

  const restaurantError = validateTextLength(input.restaurantName, 'Restaurant', {
    max: API_CONSTRAINTS.restaurantName.max,
  })
  if (restaurantError) return restaurantError

  const locationError = validateTextLength(input.restaurantLocation, 'Location', {
    max: API_CONSTRAINTS.restaurantLocation.max,
  })
  if (locationError) return locationError

  if (input.totalImages === 0) {
    return 'At least one photo is required.'
  }

  return validateImageFiles(input.newImages)
}

export function isUploadRelatedError(message: string): boolean {
  const lower = message.toLowerCase()
  return (
    lower.includes('photo') ||
    lower.includes('image') ||
    lower.includes('upload') ||
    lower.includes('store image') ||
    lower.includes('jpeg') ||
    lower.includes('png') ||
    lower.includes('webp') ||
    lower.includes(' mb')
  )
}

export function validateRegisterForm(input: {
  username: string
  email: string
  password: string
  passwordConfirm: string
  displayName: string
}): string | null {
  return (
    validateTextLength(input.displayName, 'Display name', {
      required: true,
      min: API_CONSTRAINTS.displayName.min,
      max: API_CONSTRAINTS.displayName.max,
    }) ??
    validateUsernameFormat(input.username) ??
    validateEmailFormat(input.email) ??
    validateTextLength(input.password, 'Password', {
      required: true,
      min: API_CONSTRAINTS.password.min,
      max: API_CONSTRAINTS.password.max,
    }) ??
    (input.password !== input.passwordConfirm ? 'Passwords do not match.' : null)
  )
}

export function validateProfileForm(input: {
  displayName: string
  avatar: File | null
}): string | null {
  const displayNameError = validateTextLength(input.displayName, 'Display name', {
    required: true,
    min: API_CONSTRAINTS.displayName.min,
    max: API_CONSTRAINTS.displayName.max,
  })
  if (displayNameError) return displayNameError

  if (input.avatar) {
    return validateImageFile(input.avatar)
  }

  return null
}

export function validateCommentBody(body: string): string | null {
  if (/<[^>]+>/.test(body)) {
    return 'HTML is not allowed in comments.'
  }

  return validateTextLength(body, 'Comment', {
    required: true,
    min: API_CONSTRAINTS.commentBody.min,
    max: API_CONSTRAINTS.commentBody.max,
  })
}
