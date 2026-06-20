package com.highsteak.api.service;

import com.highsteak.api.config.MailProperties;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.domain.UserNotificationPreference;
import com.highsteak.api.notification.NotificationEvent;
import com.highsteak.api.repository.PostCommentRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserNotificationPreferenceRepository;
import com.highsteak.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final MailService mailService;
    private final EmailTemplateService emailTemplateService;
    private final MailProperties mailProperties;
    private final UserRepository userRepository;
    private final UserNotificationPreferenceRepository preferenceRepository;
    private final SteakPostRepository steakPostRepository;
    private final PostCommentRepository commentRepository;

    public void sendWelcome(UUID userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null || !wantsEmail(userId, PreferenceFlag.WELCOME)) {
            return;
        }
        EmailTemplateService.EmailMessage message = emailTemplateService.welcome(user.getDisplayName());
        mailService.sendHtml(user.getEmail(), message.subject(), message.html(), message.text());
    }

    public void sendNewComment(NotificationEvent.NewComment event) {
        if (event.recipientUserId().equals(event.commenterUserId())) {
            return;
        }
        if (!wantsEmail(event.recipientUserId(), PreferenceFlag.COMMENT)) {
            return;
        }
        User recipient = userRepository.findById(event.recipientUserId()).orElse(null);
        User commenter = userRepository.findById(event.commenterUserId()).orElse(null);
        SteakPost post = steakPostRepository.findWithDetailsById(event.postId()).orElse(null);
        if (recipient == null || commenter == null || post == null) {
            return;
        }
        String commentBody = commentRepository.findById(event.commentId())
                .map(comment -> comment.getBody())
                .orElse("");
        String postUrl = mailProperties.getBaseUrl() + "/posts/" + post.getId();
        EmailTemplateService.EmailMessage message = emailTemplateService.newComment(
                recipient.getDisplayName(),
                commenter.getDisplayName(),
                post.getTitle(),
                commentBody,
                postUrl);
        mailService.sendHtml(recipient.getEmail(), message.subject(), message.html(), message.text());
    }

    public void sendNewFollower(NotificationEvent.NewFollower event) {
        if (!wantsEmail(event.recipientUserId(), PreferenceFlag.FOLLOWER)) {
            return;
        }
        User recipient = userRepository.findById(event.recipientUserId()).orElse(null);
        User follower = userRepository.findById(event.followerUserId()).orElse(null);
        if (recipient == null || follower == null) {
            return;
        }
        String profileUrl = mailProperties.getBaseUrl() + "/users/" + follower.getId();
        EmailTemplateService.EmailMessage message = emailTemplateService.newFollower(
                recipient.getDisplayName(),
                follower.getDisplayName(),
                profileUrl);
        mailService.sendHtml(recipient.getEmail(), message.subject(), message.html(), message.text());
    }

    public void sendPostHidden(NotificationEvent.PostHidden event) {
        if (!wantsEmail(event.recipientUserId(), PreferenceFlag.MODERATION)) {
            return;
        }
        User recipient = userRepository.findById(event.recipientUserId()).orElse(null);
        SteakPost post = steakPostRepository.findWithDetailsById(event.postId()).orElse(null);
        if (recipient == null || post == null) {
            return;
        }
        EmailTemplateService.EmailMessage message = emailTemplateService.postHidden(
                recipient.getDisplayName(),
                post.getTitle(),
                post.getModerationReason());
        mailService.sendHtml(recipient.getEmail(), message.subject(), message.html(), message.text());
    }

    public void sendPostRestored(NotificationEvent.PostRestored event) {
        if (!wantsEmail(event.recipientUserId(), PreferenceFlag.MODERATION)) {
            return;
        }
        User recipient = userRepository.findById(event.recipientUserId()).orElse(null);
        SteakPost post = steakPostRepository.findWithDetailsById(event.postId()).orElse(null);
        if (recipient == null || post == null) {
            return;
        }
        String postUrl = mailProperties.getBaseUrl() + "/posts/" + post.getId();
        EmailTemplateService.EmailMessage message = emailTemplateService.postRestored(
                recipient.getDisplayName(),
                post.getTitle(),
                postUrl);
        mailService.sendHtml(recipient.getEmail(), message.subject(), message.html(), message.text());
    }

    @Transactional
    public UserNotificationPreference createDefaultPreferences(User user) {
        UserNotificationPreference prefs = UserNotificationPreference.builder()
                .userId(user.getId())
                .build();
        return preferenceRepository.save(prefs);
    }

    private boolean wantsEmail(UUID userId, PreferenceFlag flag) {
        UserNotificationPreference prefs = preferenceRepository.findByUserId(userId).orElse(null);
        if (prefs == null || !prefs.isEmailEnabled()) {
            return false;
        }
        return switch (flag) {
            case WELCOME -> prefs.isWelcomeEmail();
            case COMMENT -> prefs.isCommentEmail();
            case FOLLOWER -> prefs.isFollowerEmail();
            case MODERATION -> prefs.isModerationEmail();
        };
    }

    private enum PreferenceFlag {
        WELCOME, COMMENT, FOLLOWER, MODERATION
    }
}
