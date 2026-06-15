package com.hyp.alert.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Jwts;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;

@Slf4j
@Service
public class APNsService {

    @Value("${apns.key-id:}")
    private String keyId;
    @Value("${apns.team-id:}")
    private String teamId;
    @Value("${apns.private-key-path:}")
    private String privateKeyPath;
    @Value("${apns.topic:com.hyp.helpyourparent}")
    private String topic;
    @Value("${apns.use-sandbox:true}")
    private boolean useSandbox;

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private String cachedJwt;
    private long jwtExpiry;

    public void sendPush(String deviceToken, String title, String body, Map<String, Object> customData) {
        try {
            String jwt = getProviderJwt();
            String url = useSandbox
                    ? "https://api.sandbox.push.apple.com/3/device/" + deviceToken
                    : "https://api.push.apple.com/3/device/" + deviceToken;

            Map<String, Object> aps = new java.util.HashMap<>();
            aps.put("alert", Map.of("title", title, "body", body));
            aps.put("sound", "default");
            aps.put("badge", 1);

            Map<String, Object> payload = new java.util.HashMap<>();
            payload.put("aps", aps);
            if (customData != null) payload.putAll(customData);

            String json = objectMapper.writeValueAsString(payload);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("authorization", "bearer " + jwt)
                    .header("apns-topic", topic)
                    .header("apns-push-type", "alert")
                    .header("apns-expiration", "0")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            log.info("APNs push sent to {}: status={}, body={}", deviceToken, response.statusCode(), response.body());
        } catch (Exception e) {
            log.error("APNs push failed for {}: {}", deviceToken, e.getMessage());
        }
    }

    private String getProviderJwt() throws Exception {
        if (cachedJwt != null && System.currentTimeMillis() < jwtExpiry) {
            return cachedJwt;
        }
        String keyContent = Files.readString(Path.of(privateKeyPath));
        keyContent = keyContent.replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] keyBytes = Base64.getDecoder().decode(keyContent);
        PrivateKey key = KeyFactory.getInstance("EC").generatePrivate(new PKCS8EncodedKeySpec(keyBytes));

        Instant now = Instant.now();
        cachedJwt = Jwts.builder()
                .issuer(teamId)
                .issuedAt(java.util.Date.from(now))
                .header().add("kid", keyId).and()
                .signWith(key)
                .compact();
        jwtExpiry = now.toEpochMilli() + 3500_000; // 58 minutes
        return cachedJwt;
    }
}
