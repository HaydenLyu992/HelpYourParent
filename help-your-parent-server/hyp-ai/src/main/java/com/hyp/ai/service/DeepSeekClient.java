package com.hyp.ai.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class DeepSeekClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${deepseek.api-key:}")
    private String apiKey;

    @Value("${deepseek.model:deepseek-chat}")
    private String model;

    @Value("${deepseek.timeout-seconds:30}")
    private int timeoutSeconds;

    @Value("${deepseek.max-retries:2}")
    private int maxRetries;

    public DeepSeekClient(@Value("${deepseek.base-url}") String baseUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", "application/json")
                .build();
        this.objectMapper = new ObjectMapper();
    }

    public String chat(String systemPrompt, String userMessage) {
        try {
            ChatRequest req = new ChatRequest();
            req.setModel(model);
            req.setMessages(List.of(
                    new ChatMessage("system", systemPrompt),
                    new ChatMessage("user", userMessage)
            ));
            req.setTemperature(0.7);
            req.setMaxTokens(800);

            String requestBody = objectMapper.writeValueAsString(req);

            String response = webClient.post()
                    .uri("/chat/completions")
                    .header("Authorization", "Bearer " + apiKey)
                    .bodyValue(req)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .retryWhen(Retry.backoff(maxRetries, Duration.ofSeconds(1)))
                    .block();

            ChatResponse chatResp = objectMapper.readValue(response, ChatResponse.class);
            return chatResp.getChoices().get(0).getMessage().getContent();
        } catch (Exception e) {
            log.error("DeepSeek API call failed", e);
            return null; // caller degrades gracefully
        }
    }

    @Data
    static class ChatRequest {
        private String model;
        private List<ChatMessage> messages;
        private double temperature;
        @JsonProperty("max_tokens")
        private int maxTokens;
    }

    @Data
    static class ChatMessage {
        private String role;
        private String content;
        ChatMessage(String role, String content) { this.role = role; this.content = content; }
    }

    @Data
    static class ChatResponse {
        private List<Choice> choices;
        @Data
        static class Choice {
            private ChatMessage message;
        }
    }
}
