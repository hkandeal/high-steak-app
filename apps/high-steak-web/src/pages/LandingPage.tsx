import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './LandingPage.css'

export function LandingPage() {
  const { isAuthenticated } = useAuth()

  return (
    <section className="hero-section">
      <div className="hero-glow" />
      <div className="hero-copy">
        <p className="eyebrow">The social network for steak</p>
        <h1>
          Snap. Rate. <span>Savor.</span>
        </h1>
        <p className="lead">
          Upload your steak meal photos, score the sear from 1–5, and tell the story behind
          every cut. Follow fellow carnivores and discover what&apos;s sizzling.
        </p>
        <div className="hero-actions">
          {isAuthenticated ? (
            <Link to="/feed" className="btn primary">
              Open your feed
            </Link>
          ) : (
            <>
              <Link to="/register" className="btn primary">
                Create free account
              </Link>
              <Link to="/feed" className="btn ghost">
                Browse the grill
              </Link>
            </>
          )}
        </div>
      </div>
      <div className="hero-cards">
        <article className="feature-card">
          <h3>📸 Photo-first</h3>
          <p>Show off crust, color, and plate presentation.</p>
        </article>
        <article className="feature-card">
          <h3>⭐ 1–5 rating</h3>
          <p>Score doneness, flavor, and overall experience.</p>
        </article>
        <article className="feature-card">
          <h3>💬 Stories</h3>
          <p>Share cuts, marinades, and grill secrets.</p>
        </article>
      </div>
    </section>
  )
}
