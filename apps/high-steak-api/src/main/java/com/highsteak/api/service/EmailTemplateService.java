package com.highsteak.api.service;

import com.highsteak.api.config.MailProperties;
import org.springframework.stereotype.Service;

@Service
public class EmailTemplateService {

    private final MailProperties mailProperties;

    public EmailTemplateService(MailProperties mailProperties) {
        this.mailProperties = mailProperties;
    }

    public EmailMessage welcome(String displayName) {
        String settingsUrl = settingsUrl();
        String feedUrl = feedUrl();
        String subject = "Welcome to High Steaks";
        String text = """
                Hi %s,

                Welcome to High Steaks — glad you're here.

                Share your steak ratings, follow other grill masters, and join the conversation.

                Open your feed: %s
                Manage email notifications: %s

                — High Steaks
                """.formatted(displayName, feedUrl, settingsUrl);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">Welcome to <strong>High Steaks</strong> — glad you're here. Share your steak ratings, follow other grill masters, and join the conversation.</p>
                """
                .formatted(escape(displayName));
        String html = EmailHtmlLayout.render(
                "Welcome to High Steaks",
                "Welcome to the herd",
                bodyHtml,
                "Open your feed",
                feedUrl,
                "Notification settings",
                settingsUrl,
                settingsUrl);
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage verifyEmail(String displayName, String verifyUrl) {
        String subject = "Verify your High Steaks account";
        String text = """
                Hi %s,

                Thanks for signing up for High Steaks. Confirm your email address to activate your account:

                %s

                This link expires in 24 hours. If you did not create an account, you can ignore this email.

                — High Steaks
                """.formatted(displayName, verifyUrl);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">Thanks for joining <strong>High Steaks</strong>. Confirm your email address to activate your account and start sharing your best cuts.</p>
                <p style="margin:0;color:#a89878;">This link expires in 24 hours.</p>
                """
                .formatted(escape(displayName));
        String html = EmailHtmlLayout.render(
                "Verify your email",
                "Confirm your High Steaks account",
                bodyHtml,
                "Verify email",
                verifyUrl,
                "Open High Steaks",
                mailProperties.getBaseUrl(),
                mailProperties.getBaseUrl() + "/login");
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage passwordReset(
            String displayName,
            String resetUrl,
            String appResetUrl,
            int expirationHours) {
        String subject = "Reset your High Steaks password";
        String text = """
                Hi %s,

                We received a request to reset your High Steaks password.

                Reset your password in the browser:

                %s

                Or open in the High Steaks app (if installed):

                %s

                This link expires in %d hours. If you did not request a password reset, ignore this email — your password will stay the same.

                — High Steaks
                """.formatted(displayName, resetUrl, appResetUrl, expirationHours);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">We received a request to reset your <strong>High Steaks</strong> password. Choose a new password using the link below.</p>
                <p style="margin:0;color:#a89878;">This link expires in %d hours. If this wasn't you, ignore this email.</p>
                """
                .formatted(escape(displayName), expirationHours);
        String html = EmailHtmlLayout.render(
                "Reset your password",
                "High Steaks password reset",
                bodyHtml,
                "Reset password",
                resetUrl,
                "Open in app",
                appResetUrl,
                mailProperties.getBaseUrl() + "/login");
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage confirmAccountDeletion(String displayName, String confirmUrl, int expirationHours) {
        String subject = "Confirm deletion of your High Steaks account";
        String text = """
                Hi %s,

                We received a request to permanently delete your High Steaks account and all associated data.

                If you made this request, confirm deletion here:

                %s

                This link expires in %d hours. If you did not request account deletion, ignore this email — your account will stay active.

                — High Steaks
                """.formatted(displayName, confirmUrl, expirationHours);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">We received a request to <strong>permanently delete</strong> your High Steaks account — including your posts, comments, and profile.</p>
                <p style="margin:0;color:#a89878;">This link expires in %d hours. If this wasn't you, ignore this email and your account will stay active.</p>
                """
                .formatted(escape(displayName), expirationHours);
        String html = EmailHtmlLayout.render(
                "Confirm account deletion",
                "Delete your High Steaks account",
                bodyHtml,
                "Confirm deletion",
                confirmUrl,
                "Keep my account",
                mailProperties.getBaseUrl() + "/feed",
                mailProperties.getBaseUrl() + "/login");
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage accountDeletedGoodbye(String displayName) {
        String subject = "Your High Steaks account has been deleted";
        String text = """
                Hi %s,

                Your High Steaks account and all associated data have been permanently removed.

                We're sorry to see you go. If you ever want to share another sear, you're welcome to join again.

                — High Steaks
                """.formatted(displayName);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">Your High Steaks account and all associated data have been <strong>permanently removed</strong>.</p>
                <p style="margin:0;">We're sorry to see you go. If you ever want to share another sear, you're welcome to join again.</p>
                """
                .formatted(escape(displayName));
        String html = EmailHtmlLayout.render(
                "Account deleted",
                "Goodbye from High Steaks",
                bodyHtml,
                "Visit High Steaks",
                mailProperties.getBaseUrl(),
                "Create a new account",
                mailProperties.getBaseUrl() + "/register",
                mailProperties.getBaseUrl());
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage newComment(
            String recipientName,
            String commenterName,
            String postTitle,
            String commentBody,
            String postUrl) {
        String settingsUrl = settingsUrl();
        String feedUrl = feedUrl();
        String excerpt = EmailHtmlLayout.excerpt(commentBody, 280);
        String subject = commenterName + " commented on \"" + postTitle + "\"";

        String text = """
                Hi %s,

                %s left a comment on your post "%s":

                "%s"

                View post: %s
                Open feed: %s
                Manage notifications: %s

                — High Steaks
                """
                .formatted(recipientName, commenterName, postTitle, excerpt, postUrl, feedUrl, settingsUrl);

        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;"><strong>%s</strong> commented on your post <strong>%s</strong>.</p>
                """
                .formatted(escape(recipientName), escape(commenterName), escape(postTitle))
                + EmailHtmlLayout.quoteBlock(commenterName, excerpt);

        String html = EmailHtmlLayout.render(
                commenterName + " commented on your post",
                "New comment on " + postTitle,
                bodyHtml,
                "View post",
                postUrl,
                "Open feed",
                feedUrl,
                settingsUrl);

        return new EmailMessage(subject, html, text);
    }

    public EmailMessage newFollower(String recipientName, String followerName, String profileUrl) {
        String settingsUrl = settingsUrl();
        String feedUrl = feedUrl();
        String subject = followerName + " started following you";
        String text = """
                Hi %s,

                %s started following you on High Steaks.

                View profile: %s
                Open feed: %s
                Manage notifications: %s

                — High Steaks
                """.formatted(recipientName, followerName, profileUrl, feedUrl, settingsUrl);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0;"><strong>%s</strong> started following you. Check your feed for their latest steak posts.</p>
                """
                .formatted(escape(recipientName), escape(followerName));
        String html = EmailHtmlLayout.render(
                followerName + " started following you",
                "You have a new follower",
                bodyHtml,
                "View profile",
                profileUrl,
                "Open feed",
                feedUrl,
                settingsUrl);
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage postHidden(String recipientName, String postTitle, String reason) {
        String settingsUrl = settingsUrl();
        String feedUrl = feedUrl();
        String subject = "Your post \"" + postTitle + "\" was hidden from the feed";
        String reasonLine = reason != null && !reason.isBlank() ? reason : "No reason was provided.";
        String text = """
                Hi %s,

                Your post "%s" was hidden from public feeds by a moderator.
                Reason: %s

                Open feed: %s
                Manage notifications: %s

                — High Steaks
                """.formatted(recipientName, postTitle, reasonLine, feedUrl, settingsUrl);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0 0 16px;">Your post <strong>%s</strong> was hidden from public feeds by a moderator.</p>
                <p style="margin:0;color:#a89878;"><strong>Reason:</strong> %s</p>
                """
                .formatted(escape(recipientName), escape(postTitle), escape(reasonLine));
        String html = EmailHtmlLayout.render(
                "Post hidden from feeds",
                "Moderation update for " + postTitle,
                bodyHtml,
                "Open feed",
                feedUrl,
                "Notification settings",
                settingsUrl,
                settingsUrl);
        return new EmailMessage(subject, html, text);
    }

    public EmailMessage postRestored(String recipientName, String postTitle, String postUrl) {
        String settingsUrl = settingsUrl();
        String feedUrl = feedUrl();
        String subject = "Your post \"" + postTitle + "\" is back on the feed";
        String text = """
                Hi %s,

                Good news — your post "%s" has been restored to the public feed.

                View post: %s
                Open feed: %s
                Manage notifications: %s

                — High Steaks
                """.formatted(recipientName, postTitle, postUrl, feedUrl, settingsUrl);
        String bodyHtml = """
                <p style="margin:0 0 16px;">Hi <strong>%s</strong>,</p>
                <p style="margin:0;">Good news — your post <strong>%s</strong> is visible in public feeds again.</p>
                """
                .formatted(escape(recipientName), escape(postTitle));
        String html = EmailHtmlLayout.render(
                "Post restored to feeds",
                postTitle + " is live again",
                bodyHtml,
                "View post",
                postUrl,
                "Open feed",
                feedUrl,
                settingsUrl);
        return new EmailMessage(subject, html, text);
    }

    private String feedUrl() {
        return mailProperties.getBaseUrl() + "/feed";
    }

    private String settingsUrl() {
        return mailProperties.getBaseUrl() + "/settings/notifications";
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

    public record EmailMessage(String subject, String html, String text) {}
}
