package com.hyp.alert.entity;

import com.hyp.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "alert_dispatch")
@Getter
@Setter
@NoArgsConstructor
public class AlertDispatch extends BaseEntity {

    @Column(name = "alert_id", nullable = false)
    private Long alertId;

    @Column(name = "guardian_user_id", nullable = false)
    private Long guardianUserId;

    @Column(nullable = false, length = 10)
    private String channel; // PUSH / SMS / EMAIL

    @Column(nullable = false, length = 20)
    private String status = "PENDING"; // PENDING / SENT / FAILED / DELAYED

    @Column(name = "retry_count")
    private int retryCount;

    @Column(name = "error_msg", length = 500)
    private String errorMsg;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;
}
