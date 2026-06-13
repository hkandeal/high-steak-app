package com.highsteak.api.service;

import com.highsteak.api.domain.Role;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.repository.RoleRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.JwtService;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.CONFLICT;
import static org.springframework.http.HttpStatus.NOT_FOUND;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String DEFAULT_ROLE = "USER";

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final PermissionService permissionService;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new ResponseStatusException(CONFLICT, "Username already taken");
        }
        if (userRepository.existsByEmail(request.email())) {
            throw new ResponseStatusException(CONFLICT, "Email already registered");
        }

        Role defaultRole = roleRepository.findByName(DEFAULT_ROLE)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Default role not configured"));

        User user = User.builder()
                .username(request.username())
                .email(request.email())
                .passwordHash(passwordEncoder.encode(request.password()))
                .displayName(request.displayName())
                .role(defaultRole)
                .build();
        user = userRepository.save(user);
        user = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);

        UserPrincipal principal = new UserPrincipal(user);
        String token = jwtService.generateToken(principal);
        return new AuthDtos.AuthResponse(token);
    }

    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        } catch (Exception ex) {
            throw new ResponseStatusException(UNAUTHORIZED, "Invalid username or password");
        }

        User user = userRepository.findByUsernameWithRoleAndPermissions(request.username())
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "Invalid username or password"));

        UserPrincipal principal = new UserPrincipal(user);
        String token = jwtService.generateToken(principal);
        return new AuthDtos.AuthResponse(token);
    }

    @Transactional(readOnly = true)
    public AuthDtos.UserSummary getCurrentUser(UserPrincipal principal) {
        User user = userRepository.findByIdWithRoleAndPermissions(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
        return toSummary(user);
    }

    @Transactional
    public AuthDtos.UpdateProfileResponse updateProfile(
            UserPrincipal principal,
            String displayName,
            String email,
            MultipartFile avatar) {
        User user = userRepository.findByIdWithRoleAndPermissions(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        if (displayName != null) {
            String normalized = displayName.trim();
            if (normalized.length() < 2 || normalized.length() > 100) {
                throw new ResponseStatusException(BAD_REQUEST, "Display name must be between 2 and 100 characters");
            }
            user.setDisplayName(normalized);
        }

        if (email != null) {
            String normalized = email.trim();
            if (normalized.isEmpty()) {
                throw new ResponseStatusException(BAD_REQUEST, "Email is required");
            }
            if (!normalized.equals(user.getEmail()) && userRepository.existsByEmail(normalized)) {
                throw new ResponseStatusException(CONFLICT, "Email already registered");
            }
            user.setEmail(normalized);
        }

        if (avatar != null && !avatar.isEmpty()) {
            user.setAvatarUrl(storeAvatar(avatar));
        }

        user = userRepository.save(user);
        user = userRepository.findByIdWithRoleAndPermissions(user.getId()).orElse(user);

        UserPrincipal updatedPrincipal = new UserPrincipal(user);
        String token = jwtService.generateToken(updatedPrincipal);
        return new AuthDtos.UpdateProfileResponse(token, toSummary(user));
    }

    public AuthDtos.UserSummary toSummary(User user) {
        return new AuthDtos.UserSummary(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getDisplayName(),
                user.getAvatarUrl(),
                user.getRole().getName(),
                permissionService.scopesForUser(user));
    }

    public PostDtos.AuthorSummary toAuthorSummary(User user) {
        return new PostDtos.AuthorSummary(user.getId(), user.getDisplayName());
    }

    private String storeAvatar(MultipartFile avatar) {
        String original = avatar.getOriginalFilename();
        String extension = original != null && original.contains(".")
                ? original.substring(original.lastIndexOf('.'))
                : ".jpg";
        String filename = "avatar-" + UUID.randomUUID() + extension;

        try {
            Path dir = Path.of(uploadsDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);
            Path target = dir.resolve(filename);
            avatar.transferTo(target);
            return "/uploads/" + filename;
        } catch (IOException ex) {
            throw new ResponseStatusException(BAD_REQUEST, "Failed to store avatar");
        }
    }
}
