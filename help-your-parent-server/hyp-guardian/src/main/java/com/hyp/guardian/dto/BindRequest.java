package com.hyp.guardian.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BindRequest {
    @NotBlank(message = "对方手机号不能为空")
    private String elderPhone;

    @NotBlank(message = "关系不能为空")
    private String relationship;

    private String message;
}
