package com.highsteak.api.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EmailTemplateServiceTest {

    private final EmailTemplateService templates = new EmailTemplateService(new MailPropertiesStub());

    @Test
    void newCommentIncludesFeedLinkAndCommentExcerpt() {
        EmailTemplateService.EmailMessage message = templates.newComment(
                "Hossam",
                "Chef Alex",
                "Perfect ribeye",
                "This marbling is incredible — best cut I've had all year.",
                "http://localhost:5173/posts/abc");

        assertThat(message.subject()).contains("Chef Alex");
        assertThat(message.html()).contains("http://localhost:5173/feed");
        assertThat(message.html()).contains("View post");
        assertThat(message.html()).contains("Open feed");
        assertThat(message.html()).contains("This marbling is incredible");
        assertThat(message.text()).contains("http://localhost:5173/feed");
    }

    @Test
    void verifyEmailTemplateIncludesVerifyLink() {
        String verifyUrl = "http://localhost:5173/verify-email?token=abc";
        EmailTemplateService.EmailMessage message = templates.verifyEmail("Hossam", verifyUrl);

        assertThat(message.subject()).contains("Verify");
        assertThat(message.html()).contains(verifyUrl);
        assertThat(message.text()).contains(verifyUrl);
    }

    @Test
    void confirmAccountDeletionTemplateIncludesConfirmLink() {
        String confirmUrl = "http://localhost:5173/confirm-account-deletion?token=abc";
        EmailTemplateService.EmailMessage message = templates.confirmAccountDeletion("Hossam", confirmUrl, 24);

        assertThat(message.subject()).contains("Confirm deletion");
        assertThat(message.html()).contains(confirmUrl);
        assertThat(message.text()).contains(confirmUrl);
    }

    @Test
    void passwordResetTemplateIncludesWebAndAppLinks() {
        String resetUrl = "http://localhost:5173/reset-password?token=abc";
        String appUrl = "highsteaks://reset-password?token=abc";
        EmailTemplateService.EmailMessage message = templates.passwordReset("Hossam", resetUrl, appUrl, 24);

        assertThat(message.subject()).contains("Reset");
        assertThat(message.html()).contains(resetUrl);
        assertThat(message.html()).contains(appUrl);
        assertThat(message.text()).contains(resetUrl);
        assertThat(message.text()).contains(appUrl);
    }

    @Test
    void accountDeletedGoodbyeTemplateMentionsRemoval() {
        EmailTemplateService.EmailMessage message = templates.accountDeletedGoodbye("Hossam");

        assertThat(message.subject()).contains("deleted");
        assertThat(message.html()).contains("permanently removed");
        assertThat(message.text()).contains("permanently removed");
    }

    private static final class MailPropertiesStub extends com.highsteak.api.config.MailProperties {
        MailPropertiesStub() {
            setBaseUrl("http://localhost:5173");
        }
    }
}
