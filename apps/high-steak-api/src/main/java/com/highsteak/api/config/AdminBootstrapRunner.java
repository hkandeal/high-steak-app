package com.highsteak.api.config;

import com.highsteak.api.service.AdminBootstrapService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@EnableConfigurationProperties(AdminBootstrapProperties.class)
public class AdminBootstrapRunner {

    private final AdminBootstrapService adminBootstrapService;

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        adminBootstrapService.bootstrapAdminIfNeeded();
    }
}
