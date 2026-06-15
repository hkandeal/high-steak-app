package com.highsteak.api.repository;

import com.highsteak.api.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByUsername(String username);

    @Query("""
            SELECT u FROM User u
            JOIN FETCH u.role r
            LEFT JOIN FETCH r.permissions
            WHERE u.username = :username
            """)
    Optional<User> findByUsernameWithRoleAndPermissions(@Param("username") String username);

    @Query("""
            SELECT u FROM User u
            JOIN FETCH u.role r
            LEFT JOIN FETCH r.permissions
            WHERE u.id = :id
            """)
    Optional<User> findByIdWithRoleAndPermissions(@Param("id") UUID id);

    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByRole_Name(String roleName);

    @Query("""
            SELECT u FROM User u
            WHERE (:query IS NULL OR :query = ''
                OR LOWER(u.username) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(u.displayName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%')))
            ORDER BY u.username
            """)
    Page<User> searchAdminUsers(@Param("query") String query, Pageable pageable);

    @Query("""
            SELECT u FROM User u
            WHERE u.id <> :excludeId
              AND (
                  LOWER(u.username) LIKE LOWER(CONCAT('%', :query, '%'))
                  OR LOWER(u.displayName) LIKE LOWER(CONCAT('%', :query, '%'))
              )
            ORDER BY u.username
            """)
    List<User> searchPublicUsers(@Param("query") String query, @Param("excludeId") UUID excludeId);
}
