package com.hyp.alert.entity;

import com.hyp.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "alert_record")
@Getter
@Setter
@NoArgsConstructor
public class AlertRecord extends BaseEntity {

    @Column(name = "elder_user_id", nullable = false)
    private Long elderUserId;

    @Column(name = "alert_level", nullable = false, length = 10)
    private String alertLevel; // YELLOW / ORANGE / RED

    @Column(name = "risk_type", nullable = false, length = 50)
    private String riskType; // HEART_RATE / SPO2 / FALL / INACTIVITY / SLEEP

    @Column(length = 500)
    private String summary;

    @Column(name = "ai_advice", columnDefinition = "TEXT")
    private String aiAdvice;

    @Column(name = "is_merged")
    private boolean isMerged;

    @Column(name = "dispatched_at")
    private LocalDateTime dispatchedAt;
}
