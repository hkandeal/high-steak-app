package com.highsteak.api.service;

import com.highsteak.api.config.MailProperties;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final JavaMailSender mailSender;
    private final MailProperties mailProperties;

    @Async("mailTaskExecutor")
    public void sendHtml(String to, String subject, String htmlBody, String textBody) {
        if (!mailProperties.isEnabled()) {
            log.debug("Mail disabled; skipping send to {} subject {}", to, subject);
            return;
        }
        if (to == null || to.isBlank()) {
            return;
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(mailProperties.getFrom());
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(textBody, htmlBody);
            mailSender.send(message);
            log.info("Sent email to {} subject {}", to, subject);
        } catch (MessagingException ex) {
            log.error("Failed to send email to {} subject {}: {}", to, subject, ex.getMessage());
        } catch (Exception ex) {
            log.error("Failed to send email to {} subject {}", to, subject, ex);
        }
    }
}
