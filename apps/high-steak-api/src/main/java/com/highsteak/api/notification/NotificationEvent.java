package com.highsteak.api.notification;

import java.util.UUID;

public sealed interface NotificationEvent permits
        NotificationEvent.Welcome,
        NotificationEvent.NewComment,
        NotificationEvent.NewFollower,
        NotificationEvent.PostHidden,
        NotificationEvent.PostRestored {

    record Welcome(UUID userId) implements NotificationEvent {}

    record NewComment(UUID postId, UUID commentId, UUID recipientUserId, UUID commenterUserId)
            implements NotificationEvent {}

    record NewFollower(UUID recipientUserId, UUID followerUserId) implements NotificationEvent {}

    record PostHidden(UUID postId, UUID recipientUserId) implements NotificationEvent {}

    record PostRestored(UUID postId, UUID recipientUserId) implements NotificationEvent {}
}
