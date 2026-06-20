package com.highsteak.api.notification;

import com.highsteak.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
@RequiredArgsConstructor
public class NotificationEventListener {

    private final NotificationService notificationService;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onWelcome(NotificationEvent.Welcome event) {
        notificationService.sendWelcome(event.userId());
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onNewComment(NotificationEvent.NewComment event) {
        notificationService.sendNewComment(event);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onNewFollower(NotificationEvent.NewFollower event) {
        notificationService.sendNewFollower(event);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPostHidden(NotificationEvent.PostHidden event) {
        notificationService.sendPostHidden(event);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPostRestored(NotificationEvent.PostRestored event) {
        notificationService.sendPostRestored(event);
    }
}
