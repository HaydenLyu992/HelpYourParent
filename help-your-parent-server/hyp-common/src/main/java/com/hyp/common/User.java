package com.hyp.common;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "user_profile")
@Getter
@Setter
@NoArgsConstructor
public class User extends BaseEntity {

    @Column(nullable = false, unique = true, length = 20)
    private String phone;

    @Column(nullable = false, length = 20)
    private String role; // ELDER or GUARDIAN

    @Column(length = 50)
    private String nickname;

    @Column(name = "avatar_url", length = 255)
    private String avatarUrl;

    @Column(name = "password_hash", length = 255)
    private String passwordHash;

    public boolean isElder() {
        return Constants.ROLE_ELDER.equals(role);
    }

    public boolean isGuardian() {
        return Constants.ROLE_GUARDIAN.equals(role);
    }
}
