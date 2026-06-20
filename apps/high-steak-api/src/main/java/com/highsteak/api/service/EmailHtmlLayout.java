package com.highsteak.api.service;

final class EmailHtmlLayout {

    static final String BRAND_NAME = "High Steaks";

    private EmailHtmlLayout() {}

    static String render(
            String preheader,
            String headline,
            String bodyHtml,
            String primaryLabel,
            String primaryUrl,
            String secondaryLabel,
            String secondaryUrl,
            String settingsUrl) {
        return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="utf-8"/>
                  <meta name="viewport" content="width=device-width, initial-scale=1"/>
                  <title>%s</title>
                </head>
                <body style="margin:0;padding:0;background:#1a1208;font-family:Georgia,'Times New Roman',serif;color:#f5e6c8;">
                  <span style="display:none;max-height:0;overflow:hidden;opacity:0;">%s</span>
                  <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background:#1a1208;padding:32px 16px;">
                    <tr>
                      <td align="center">
                        <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#2a1f12;border:1px solid #5c4a32;border-radius:12px;overflow:hidden;">
                          <tr>
                            <td style="padding:28px 32px 20px;background:linear-gradient(135deg,#3d2a18 0%%,#2a1f12 100%%);border-bottom:1px solid #5c4a32;">
                              <p style="margin:0 0 6px;font-size:11px;letter-spacing:0.14em;text-transform:uppercase;color:#c9a227;">%s</p>
                              <h1 style="margin:0;font-size:24px;line-height:1.3;font-weight:700;color:#f5e6c8;">%s</h1>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding:28px 32px;font-size:16px;line-height:1.6;color:#e8dcc4;">
                              %s
                            </td>
                          </tr>
                          <tr>
                            <td style="padding:0 32px 28px;">
                              <table role="presentation" cellspacing="0" cellpadding="0">
                                <tr>
                                  <td style="padding-right:12px;padding-bottom:12px;">
                                    <a href="%s" style="display:inline-block;padding:12px 22px;background:#c9a227;color:#1a1208;font-family:Helvetica,Arial,sans-serif;font-size:14px;font-weight:700;text-decoration:none;border-radius:8px;">%s</a>
                                  </td>
                                  <td style="padding-bottom:12px;">
                                    <a href="%s" style="display:inline-block;padding:12px 18px;border:1px solid #5c4a32;color:#f5e6c8;font-family:Helvetica,Arial,sans-serif;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;">%s</a>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding:18px 32px 24px;border-top:1px solid #5c4a32;font-family:Helvetica,Arial,sans-serif;font-size:12px;line-height:1.5;color:#a89878;">
                              You're receiving this because you have email notifications enabled on %s.
                              <a href="%s" style="color:#c9a227;">Manage preferences</a>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </body>
                </html>
                """
                .formatted(
                        escape(headline),
                        escape(preheader),
                        escape(BRAND_NAME),
                        escape(headline),
                        bodyHtml,
                        primaryUrl,
                        escape(primaryLabel),
                        secondaryUrl,
                        escape(secondaryLabel),
                        BRAND_NAME,
                        settingsUrl);
    }

    static String quoteBlock(String author, String excerpt) {
        return """
                <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="margin:0 0 20px;background:#1a1208;border-left:4px solid #c9a227;border-radius:0 8px 8px 0;">
                  <tr>
                    <td style="padding:16px 18px;">
                      <p style="margin:0 0 8px;font-family:Helvetica,Arial,sans-serif;font-size:12px;font-weight:700;letter-spacing:0.04em;text-transform:uppercase;color:#c9a227;">%s</p>
                      <p style="margin:0;font-size:15px;line-height:1.55;color:#f5e6c8;font-style:italic;">&ldquo;%s&rdquo;</p>
                    </td>
                  </tr>
                </table>
                """
                .formatted(escape(author), escape(excerpt));
    }

    static String excerpt(String body, int maxLength) {
        if (body == null || body.isBlank()) {
            return "";
        }
        String normalized = body.strip().replaceAll("\\s+", " ");
        if (normalized.length() <= maxLength) {
            return normalized;
        }
        return normalized.substring(0, maxLength - 1).stripTrailing() + "…";
    }

    private static String escape(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
