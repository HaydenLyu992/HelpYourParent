package com.hyp.alert.dto;

import lombok.Data;
import java.util.Map;

@Data
public class AlertTriggerRequest {
    private Long elderUserId;
    private String riskType;
    private String alertLevel;
    private Map<String, Double> metrics;
    private String aiAdvice;
    private String deviceToken;
}
