package com.hyp.guardian.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class PendingRequestInfo {
    private Long requestId;
    private Long fromUserId;
    private String fromNickname;
    private String fromPhone;
    private String relationship;
    private String message;
    private LocalDateTime createdAt;
}
