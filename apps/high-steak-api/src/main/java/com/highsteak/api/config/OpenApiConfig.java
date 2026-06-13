package com.highsteak.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI highSteakOpenAPI(
            @Value("${server.servlet.context-path:/}") String contextPath,
            @Value("${server.port:8080}") int port) {
        String normalizedContext = contextPath.endsWith("/")
                ? contextPath.substring(0, contextPath.length() - 1)
                : contextPath;
        if (normalizedContext.isEmpty()) {
            normalizedContext = "";
        }

        return new OpenAPI()
                .info(new Info()
                        .title("High Steak API")
                        .description("REST API for the High Steak social steak-rating app.")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("High Steak")
                                .url("https://github.com/high-steak-app")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:" + port + normalizedContext)
                                .description("Local development")))
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT access token from POST /auth/login or /auth/register")));
    }
}
