package com.highsteak.api.validation;

/**
 * HTTP validation limits aligned with database column definitions in Flyway migrations.
 */
public final class ApiConstraints {

    private ApiConstraints() {}

    public static final int USERNAME_MIN = 3;
    public static final int USERNAME_MAX = 50;

    public static final int EMAIL_MAX = 255;

    public static final int PASSWORD_MIN = 8;
    public static final int PASSWORD_MAX = 100;

    public static final int DISPLAY_NAME_MIN = 2;
    public static final int DISPLAY_NAME_MAX = 100;

    public static final int POST_TITLE_MIN = 1;
    public static final int POST_TITLE_MAX = 120;

    /** MySQL {@code TEXT} column limit for {@code steak_posts.comment}. */
    public static final int POST_COMMENT_MAX = 65_535;

    public static final int RESTAURANT_NAME_MAX = 120;
    public static final int RESTAURANT_LOCATION_MAX = 255;

    /** MySQL {@code TEXT} column limit for {@code post_comments.body}. */
    public static final int COMMENT_BODY_MAX = 2_000;

    public static final int SEARCH_QUERY_MIN = 2;
    public static final int SEARCH_QUERY_MAX = 100;

    public static final int MAX_REVIEW_TAGS = 12;

    public static final long MAX_IMAGE_BYTES = 1_048_576L;
}
