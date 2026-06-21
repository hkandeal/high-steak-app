package com.highsteak.api.repository;

import com.highsteak.api.domain.AccountDeletionToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface AccountDeletionTokenRepository extends JpaRepository<AccountDeletionToken, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT t FROM AccountDeletionToken t
            WHERE t.tokenHash = :tokenHash AND t.usedAt IS NULL
            """)
    Optional<AccountDeletionToken> findActiveForUpdateByTokenHash(String tokenHash);

    @Modifying
    @Query("""
            UPDATE AccountDeletionToken t
            SET t.usedAt = :usedAt
            WHERE t.userId = :userId AND t.usedAt IS NULL
            """)
    void invalidateActiveTokensForUser(UUID userId, Instant usedAt);
}
