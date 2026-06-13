package com.highsteak.api.config;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

final class RootWelcomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setCharacterEncoding(StandardCharsets.UTF_8.name());

        if (acceptsJson(req)) {
            resp.setContentType("application/json");
            resp.getWriter().write("""
                    {
                      "service": "high-steak-api",
                      "message": "Welcome to the High Steak API.",
                      "links": {
                        "api": "/api",
                        "docs": "/api/swagger-ui.html",
                        "health": "/api/health"
                      }
                    }
                    """);
            return;
        }

        resp.setContentType("text/html; charset=UTF-8");
        resp.getWriter().write("""
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>High Steak API</title>
                  <style>
                    body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 4rem auto; padding: 0 1rem; color: #1a1a1a; line-height: 1.5; }
                    h1 { margin-bottom: 0.25rem; }
                    p { color: #444; }
                    ul { padding-left: 1.25rem; }
                    a { color: #b45309; }
                  </style>
                </head>
                <body>
                  <h1>High Steak API</h1>
                  <p>Welcome. The API is running on this server.</p>
                  <ul>
                    <li><a href="/api/swagger-ui.html">API documentation</a></li>
                    <li><a href="/api/health">Health check</a></li>
                    <li><a href="/api">API root</a></li>
                  </ul>
                </body>
                </html>
                """);
    }

    private static boolean acceptsJson(HttpServletRequest req) {
        String accept = req.getHeader("Accept");
        return accept != null && accept.contains("application/json");
    }
}
