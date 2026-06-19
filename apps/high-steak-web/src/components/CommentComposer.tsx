import { lazy, Suspense, useEffect, useId, useRef, useState, type FormEvent } from 'react'
import type { EmojiClickData, Theme } from 'emoji-picker-react'
import { API_CONSTRAINTS } from '../api/constraints'
import { useTheme } from '../context/ThemeContext'
import './CommentComposer.css'

const EmojiPicker = lazy(() => import('emoji-picker-react'))

type CommentComposerProps = {
  value: string
  onChange: (value: string) => void
  onSubmit: () => void
  submitting?: boolean
  placeholder?: string
}

function insertAtCursor(textarea: HTMLTextAreaElement, current: string, insert: string, maxLength: number) {
  const start = textarea.selectionStart ?? current.length
  const end = textarea.selectionEnd ?? current.length
  const next = `${current.slice(0, start)}${insert}${current.slice(end)}`
  if (next.length > maxLength) return current

  const cursor = start + insert.length
  requestAnimationFrame(() => {
    textarea.selectionStart = cursor
    textarea.selectionEnd = cursor
    textarea.focus()
  })

  return next
}

export function CommentComposer({
  value,
  onChange,
  onSubmit,
  submitting = false,
  placeholder = 'Share your thoughts…',
}: CommentComposerProps) {
  const pickerId = useId()
  const { theme } = useTheme()
  const pickerTheme = theme === 'steam' ? 'light' : 'dark'
  const [pickerOpen, setPickerOpen] = useState(false)
  const rootRef = useRef<HTMLFormElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)
  const maxLength = API_CONSTRAINTS.commentBody.max

  useEffect(() => {
    if (!pickerOpen) return

    function handlePointerDown(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) {
        setPickerOpen(false)
      }
    }

    document.addEventListener('mousedown', handlePointerDown)
    return () => document.removeEventListener('mousedown', handlePointerDown)
  }, [pickerOpen])

  function handleEmojiClick(emoji: EmojiClickData) {
    const textarea = textareaRef.current
    if (!textarea) {
      onChange(`${value}${emoji.emoji}`.slice(0, maxLength))
      return
    }

    const next = insertAtCursor(textarea, value, emoji.emoji, maxLength)
    if (next !== value) onChange(next)
    setPickerOpen(false)
  }

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    onSubmit()
  }

  return (
    <form className="comment-composer" onSubmit={handleSubmit} ref={rootRef}>
      <div className="comment-composer-input-wrap">
        <textarea
          ref={textareaRef}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          rows={3}
          placeholder={placeholder}
          maxLength={maxLength}
          required
          aria-label="Comment"
        />
        <div className="comment-composer-toolbar">
          <button
            type="button"
            className="comment-emoji-toggle"
            aria-expanded={pickerOpen}
            aria-controls={pickerId}
            onClick={() => setPickerOpen((open) => !open)}
            title="Add emoji"
          >
            😀
          </button>
          <button type="submit" className="btn primary" disabled={submitting || !value.trim()}>
            {submitting ? 'Posting…' : 'Post comment'}
          </button>
        </div>
      </div>

      {pickerOpen && (
        <div id={pickerId} className="comment-emoji-picker">
          <Suspense fallback={<p className="muted comment-emoji-loading">Loading emojis…</p>}>
            <EmojiPicker
              onEmojiClick={handleEmojiClick}
              theme={pickerTheme as Theme}
              width="100%"
              height={360}
              searchPlaceholder="Search emoji"
              previewConfig={{ showPreview: false }}
            />
          </Suspense>
        </div>
      )}
    </form>
  )
}
