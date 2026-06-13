package com.highsteak.api.repository;

import com.highsteak.api.domain.Permission;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PermissionRepository extends JpaRepository<Permission, Long> {
    List<Permission> findByScopeIn(Iterable<String> scopes);
}
