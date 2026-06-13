package com.highsteak.api.config;

import com.highsteak.api.security.UserPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

@Slf4j
@Component
@RequiredArgsConstructor
public class ApiRequestLoggingFilter extends OncePerRequestFilter {

    private static final int MAX_BODY_LOG_CHARS = 4_096;

    private final ApiLoggingProperties loggingProperties;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {
        if (!loggingProperties.isHttpAccessEnabled() || shouldSkip(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        ContentCachingRequestWrapper wrappedRequest = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);

        long startNanos = System.nanoTime();
        try {
            filterChain.doFilter(wrappedRequest, wrappedResponse);
        } finally {
            logRequest(wrappedRequest, wrappedResponse, (System.nanoTime() - startNanos) / 1_000_000);
            wrappedResponse.copyBodyToResponse();
        }
    }

    private boolean shouldSkip(HttpServletRequest request) {
        String servletPath = request.getServletPath();
        return loggingProperties.getSkipPaths().stream()
                .anyMatch(skip -> servletPath.equals(skip) || servletPath.startsWith(skip + "/"));
    }

    private void logRequest(
            ContentCachingRequestWrapper request,
            ContentCachingResponseWrapper response,
            long durationMs) {
        String method = request.getMethod();
        String servletPath = request.getServletPath();
        int status = response.getStatus();

        if (log.isDebugEnabled()) {
            String query = request.getQueryString();
            String pathWithQuery = query == null ? servletPath : servletPath + "?" + query;
            log.debug("{} {} -> {} ({}ms) user={}", method, pathWithQuery, status, durationMs, resolveUserId());
            if (shouldLogBodies(servletPath)) {
                logBody("request", method, servletPath, formatRequestBody(request));
                logBody("response", method, servletPath, formatResponseBody(response));
            }
        } else {
            log.info("{} {} -> {} ({}ms)", method, servletPath, status, durationMs);
        }
    }

    private void logBody(String direction, String method, String path, String body) {
        if (body == null) {
            return;
        }
        log.debug("{} body {} {}: {}", direction, method, path, body);
    }

    private boolean shouldLogBodies(String servletPath) {
        return !servletPath.startsWith("/auth");
    }

    private String formatRequestBody(ContentCachingRequestWrapper request) {
        String contentType = request.getContentType();
        if (contentType != null && contentType.toLowerCase().startsWith("multipart/")) {
            return "[multipart omitted]";
        }
        return truncateBody(request.getContentAsByteArray(), resolveCharset(request.getCharacterEncoding()));
    }

    private String formatResponseBody(ContentCachingResponseWrapper response) {
        String contentType = response.getContentType();
        if (contentType != null && !isTextLoggableContentType(contentType)) {
            return "[binary or non-text omitted]";
        }
        return truncateBody(response.getContentAsByteArray(), resolveCharset(response.getCharacterEncoding()));
    }

    private boolean isTextLoggableContentType(String contentType) {
        String normalized = contentType.toLowerCase();
        return normalized.contains("json")
                || normalized.startsWith("text/")
                || normalized.contains("xml")
                || normalized.contains("problem+json");
    }

    private String truncateBody(byte[] content, Charset charset) {
        if (content == null || content.length == 0) {
            return null;
        }
        String body = new String(content, charset).replaceAll("\\s+", " ").trim();
        if (body.isEmpty()) {
            return null;
        }
        if (body.length() <= MAX_BODY_LOG_CHARS) {
            return body;
        }
        return body.substring(0, MAX_BODY_LOG_CHARS) + "... [truncated]";
    }

    private Charset resolveCharset(String encoding) {
        if (encoding == null || encoding.isBlank()) {
            return StandardCharsets.UTF_8;
        }
        try {
            return Charset.forName(encoding);
        } catch (Exception ex) {
            return StandardCharsets.UTF_8;
        }
    }

    private String resolveUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal) {
            return principal.getId().toString();
        }
        return "anonymous";
    }
}
