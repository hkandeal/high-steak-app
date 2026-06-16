import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

const DEFAULT_SITE_URL = 'https://steaks.apps.hossam.io'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const siteUrl = env.VITE_SITE_URL || DEFAULT_SITE_URL

  return {
    plugins: [
      react(),
      {
        name: 'html-social-meta',
        transformIndexHtml(html) {
          return html.replaceAll('__SITE_URL__', siteUrl.replace(/\/$/, ''))
        },
      },
    ],
    server: {
      port: 5173,
      proxy: {
        '/api': 'http://localhost:8080',
        '/uploads': 'http://localhost:8080',
      },
    },
  }
})
