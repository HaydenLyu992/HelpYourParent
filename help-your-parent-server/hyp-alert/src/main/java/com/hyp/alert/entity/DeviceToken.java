package com.hyp.alert.entity;

import com.hyp.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "device_token")
@Getter
@Setter
@NoArgsConstructor
public class DeviceToken extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "device_token", nullable = false, length = 256)
    private String token;

    @Column(name = "platform", length = 10)
    private String platform = "IOS";
}
