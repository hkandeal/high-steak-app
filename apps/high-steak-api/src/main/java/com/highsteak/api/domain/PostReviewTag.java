package com.highsteak.api.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "post_review_tags")
@IdClass(PostReviewTagId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostReviewTag {

    @Id
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "post_id", columnDefinition = "CHAR(36)", nullable = false, length = 36)
    private UUID postId;

    @Id
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "tag_id", columnDefinition = "CHAR(36)", nullable = false, length = 36)
    private UUID tagId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "post_id", insertable = false, updatable = false)
    private SteakPost post;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tag_id", insertable = false, updatable = false)
    private ReviewTag tag;

    public static PostReviewTag of(SteakPost post, ReviewTag tag) {
        return PostReviewTag.builder()
                .postId(post.getId())
                .tagId(tag.getId())
                .post(post)
                .tag(tag)
                .build();
    }
}
