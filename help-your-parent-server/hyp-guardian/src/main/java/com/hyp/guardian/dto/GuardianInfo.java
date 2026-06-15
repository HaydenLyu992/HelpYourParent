package com.hyp.guardian.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class GuardianInfo {
    private Long userId;
    private String nickname;
    private String phone;
    private String relationship;
    private String status;
}
