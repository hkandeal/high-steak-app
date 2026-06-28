import { useCallback, useEffect, useRef, useState, type RefObject } from 'react'
import { useBlocker } from 'react-router-dom'
import type { PostFormHandle } from '../components/PostForm'

export function usePostEditorLeaveGuard(
  isDirty: boolean,
  formRef: RefObject<PostFormHandle | null>,
) {
  const allowLeaveRef = useRef(false)

  useEffect(() => {
    if (isDirty) {
      allowLeaveRef.current = false
    }
  }, [isDirty])

  const shouldBlockLeave = useCallback(() => isDirty && !allowLeaveRef.current, [isDirty])
  const blocker = useBlocker(shouldBlockLeave)
  const [leaveDialogOpen, setLeaveDialogOpen] = useState(false)
  const [savingLeave, setSavingLeave] = useState(false)

  useEffect(() => {
    if (blocker.state === 'blocked') {
      setLeaveDialogOpen(true)
    }
  }, [blocker.state])

  useEffect(() => {
    if (!isDirty) return

    function handleBeforeUnload(event: BeforeUnloadEvent) {
      event.preventDefault()
      event.returnValue = ''
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [isDirty])

  function handleLeaveCancel() {
    setLeaveDialogOpen(false)
    if (blocker.state === 'blocked') {
      blocker.reset()
    }
  }

  function handleLeaveConfirm() {
    setLeaveDialogOpen(false)
    if (blocker.state === 'blocked') {
      blocker.proceed()
    }
  }

  function permitLeave() {
    allowLeaveRef.current = true
  }

  async function handleSaveAndLeave(onSaved?: () => void) {
    setSavingLeave(true)
    try {
      const saved = await formRef.current?.submit()
      if (!saved) return
      permitLeave()
      setLeaveDialogOpen(false)
      onSaved?.()
      if (blocker.state === 'blocked') {
        blocker.proceed()
      }
    } finally {
      setSavingLeave(false)
    }
  }

  return {
    leaveDialogOpen,
    savingLeave,
    permitLeave,
    handleLeaveCancel,
    handleLeaveConfirm,
    handleSaveAndLeave,
  }
}
