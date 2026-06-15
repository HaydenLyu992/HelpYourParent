package com.hyp.alert.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class AlertResponse {
    private Long alertId;
    private String alertLevel;
    private String riskType;
    private String summary;
    private String aiAdvice;
    private boolean isMerged;
    private LocalDateTime createdAt;
}
