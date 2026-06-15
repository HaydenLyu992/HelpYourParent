package com.hyp.gateway;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator customRoutes(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("user-service", r -> r
                        .path("/api/user/**")
                        .uri("lb://hyp-service"))
                .route("health-service", r -> r
                        .path("/api/health/**")
                        .uri("lb://hyp-service"))
                .route("guardian-service", r -> r
                        .path("/api/guardian/**")
                        .uri("lb://hyp-service"))
                .route("alert-service", r -> r
                        .path("/api/alert/**")
                        .uri("lb://hyp-service"))
                .route("ai-service", r -> r
                        .path("/api/ai/**")
                        .uri("lb://hyp-service"))
                .build();
    }
}
