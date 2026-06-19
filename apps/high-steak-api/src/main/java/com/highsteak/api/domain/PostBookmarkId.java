package com.highsteak.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.io.Serializable;
import java.util.UUID;

@Embeddable
@Getter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class PostBookmarkId implements Serializable {

    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "user_id", columnDefinition = "CHAR(36)", nullable = false, length = 36)
    private UUID userId;

    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "post_id", columnDefinition = "CHAR(36)", nullable = false, length = 36)
    private UUID postId;
}
