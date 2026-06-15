import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchHiddenPosts,
  FEED_PAGE_SIZE,
  listUsers,
  setUserBlocked,
  unhidePost,
  type AdminUser,
} from '../api/client'
import { useAuth } from '../context/AuthContext'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import { useInfinitePostFeed } from '../hooks/useInfinitePostFeed'
import { listItemBackState } from '../navigation'
import '../pages/FeedPage.css'
import './ManagementPage.css'

const PAGE_SIZE = 20

function canBlockUser(user: AdminUser) {
  return user.role === 'USER'
}

export function ModerationPanel() {
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
  const [restoringPostId, setRestoringPostId] = useState<string | null>(null)
  const canBlockUsers = hasScope('users:block')

  const loadHiddenPage = useCallback(
    async (page: number) => {
      if (!token) {
        return { content: [], page: 0, size: FEED_PAGE_SIZE, totalElements: 0, totalPages: 0 }
      }
      return fetchHiddenPosts(token, { page, size: FEED_PAGE_SIZE })
    },
    [token],
  )

  const {
    posts: hiddenPosts,
    setPosts: setHiddenPosts,
    loading: hiddenLoading,
    loadingMore: hiddenLoadingMore,
    hasMore: hiddenHasMore,
    sentinelRef: hiddenSentinelRef,
  } = useInfinitePostFeed(loadHiddenPage, token ?? 'none')

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

  async function handleBlockToggle(user: AdminUser) {
    if (!token || !canBlockUsers || !canBlockUser(user)) return
    setSavingUserId(user.id)
    setError(null)
    try {
      const updated = await setUserBlocked(token, user.id, !user.blocked)
      setUsers((current) => current.map((item) => (item.id === user.id ? updated : item)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update account status')
    } finally {
      setSavingUserId(null)
    }
  }

  async function handleRestorePost(postId: string) {
    if (!token) return
    setRestoringPostId(postId)
    setError(null)
    try {
      await unhidePost(token, postId)
      setHiddenPosts((current) => current.filter((post) => post.id !== postId))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to restore post')
    } finally {
      setRestoringPostId(null)
    }
  }

  return (
    <>
    <section className="management-section">
      <header className="management-section-header">
        <h2>Members</h2>
        <p>
          Browse all members, open a profile to review their feed, or block accounts from signing
          in.
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
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id}>
                    <td>@{user.username}</td>
                    <td>{user.displayName}</td>
                    <td>{user.email}</td>
                    <td>
                      {user.blocked ? (
                        <span className="status-badge blocked">Blocked</span>
                      ) : (
                        <span className="status-badge active">Active</span>
                      )}
                    </td>
                    <td>
                      <div className="management-row-actions">
                        <Link
                          to={`/users/${user.id}`}
                          state={listItemBackState('/manage', 'Back to manage')}
                          className="btn ghost small"
                        >
                          View profile
                        </Link>
                        {canBlockUsers && canBlockUser(user) && (
                          <button
                            type="button"
                            className={`btn ghost small ${user.blocked ? '' : 'danger-text'}`}
                            disabled={savingUserId === user.id}
                            onClick={() => {
                              void handleBlockToggle(user)
                            }}
                          >
                            {user.blocked ? 'Unblock' : 'Block'}
                          </button>
                        )}
                      </div>
                    </td>
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

    <section className="management-section moderation-subsection">
      <header className="management-section-header">
        <h2>Hidden posts</h2>
        <p>Posts removed from public feeds. Restore a post to show it in feeds again.</p>
      </header>

      {hiddenLoading && <p className="muted">Loading hidden posts…</p>}

      {!hiddenLoading && hiddenPosts.length === 0 && (
        <div className="empty-feed">
          <p>No hidden posts right now.</p>
        </div>
      )}

      <div className="admin-table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>Post</th>
              <th>Author</th>
              <th>Reason</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {hiddenPosts.map((post) => (
              <tr key={post.id}>
                <td>{post.title}</td>
                <td>{post.author.displayName}</td>
                <td>{post.moderationReason ?? '—'}</td>
                <td>
                  <div className="management-row-actions">
                    <Link
                      to={`/posts/${post.id}`}
                      state={listItemBackState('/manage', 'Back to manage')}
                      className="btn ghost small"
                    >
                      View
                    </Link>
                    <button
                      type="button"
                      className="btn ghost small"
                      disabled={restoringPostId === post.id}
                      onClick={() => {
                        void handleRestorePost(post.id)
                      }}
                    >
                      Restore to feed
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {hiddenHasMore && !hiddenLoading && (
        <div ref={hiddenSentinelRef} className="infinite-scroll-sentinel">
          {hiddenLoadingMore && <p className="muted">Loading more hidden posts…</p>}
        </div>
      )}
    </section>
    </>
  )
}
