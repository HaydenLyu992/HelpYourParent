package com.hyp.service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication(scanBasePackages = "com.hyp")
@EntityScan(basePackages = "com.hyp.common")
@EnableJpaRepositories(basePackages = "com.hyp.common")
public class HypServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(HypServiceApplication.class, args);
    }
}
