package com.highsteak.api.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PostReviewTagId implements Serializable {

    private UUID postId;
    private UUID tagId;
}
