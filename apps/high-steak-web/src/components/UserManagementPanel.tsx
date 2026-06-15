import { useCallback, useEffect, useState } from 'react'
import { listUsers, updateUserRole, type AdminUser } from '../api/client'
import { useAuth } from '../context/AuthContext'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import './ManagementPage.css'

const PAGE_SIZE = 20

export function UserManagementPanel() {
  const { token, hasScope } = useAuth()
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebouncedValue(search)
  const [page, setPage] = useState(0)
  const [users, setUsers] = useState<AdminUser[]>([])
  const [totalPages, setTotalPages] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [savingUserId, setSavingUserId] = useState<string | null>(null)
  const canManageModerators = hasScope('users:manage')

  const loadUsers = useCallback(async () => {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const response = await listUsers(token, {
        q: debouncedSearch,
        page,
        size: PAGE_SIZE,
      })
      setUsers(response.content)
      setTotalPages(response.totalPages)
      setTotalElements(response.totalElements)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users')
    } finally {
      setLoading(false)
    }
  }, [token, debouncedSearch, page])

  useEffect(() => {
    setPage(0)
  }, [debouncedSearch])

  useEffect(() => {
    void loadUsers()
  }, [loadUsers])

  async function handleModeratorToggle(user: AdminUser) {
    if (!token || !canManageModerators || user.role === 'ADMIN') return
    const nextRole = user.role === 'MODERATOR' ? 'USER' : 'MODERATOR'
    setSavingUserId(user.id)
    setError(null)
    try {
      const updated = await updateUserRole(token, user.id, nextRole)
      setUsers((current) => current.map((item) => (item.id === user.id ? updated : item)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update moderator status')
    } finally {
      setSavingUserId(null)
    }
  }

  return (
    <section className="management-section">
      <header className="management-section-header">
        <h2>Moderators</h2>
        <p>
          Browse all members and assign or remove the moderator role. Changes take effect on the
          user&apos;s next sign-in.
        </p>
      </header>

      <div className="management-toolbar">
        <label className="management-search">
          <span className="sr-only">Search users</span>
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by username, name, or email…"
          />
        </label>
        {!loading && (
          <span className="management-meta">
            {totalElements} user{totalElements === 1 ? '' : 's'}
          </span>
        )}
      </div>

      {loading && <p className="muted">Loading users…</p>}
      {error && <p className="form-error">{error}</p>}

      {!loading && !error && (
        <>
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Display name</th>
                  <th>Email</th>
                  <th>Role</th>
                  {canManageModerators && <th>Actions</th>}
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id}>
                    <td>@{user.username}</td>
                    <td>{user.displayName}</td>
                    <td>{user.email}</td>
                    <td>
                      <span className="role-readonly">{user.role}</span>
                    </td>
                    {canManageModerators && (
                      <td>
                        {user.role === 'ADMIN' ? (
                          <span className="muted">—</span>
                        ) : (
                          <button
                            type="button"
                            className={`btn ghost small ${user.role === 'MODERATOR' ? 'danger-text' : ''}`}
                            disabled={savingUserId === user.id}
                            onClick={() => {
                              void handleModeratorToggle(user)
                            }}
                          >
                            {user.role === 'MODERATOR' ? 'Remove moderator' : 'Make moderator'}
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {users.length === 0 && (
            <div className="empty-feed">
              <p>No users match your search.</p>
            </div>
          )}

          {totalPages > 1 && (
            <div className="management-pagination">
              <button
                type="button"
                className="btn ghost small"
                disabled={page === 0}
                onClick={() => setPage((current) => current - 1)}
              >
                Previous
              </button>
              <span>
                Page {page + 1} of {totalPages}
              </span>
              <button
                type="button"
                className="btn ghost small"
                disabled={page >= totalPages - 1}
                onClick={() => setPage((current) => current + 1)}
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </section>
  )
}
