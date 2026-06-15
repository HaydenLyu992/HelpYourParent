package com.hyp.common;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "guardian_binding",
       uniqueConstraints = @UniqueConstraint(columnNames = {"guardian_user_id", "elder_user_id"}))
@Getter
@Setter
@NoArgsConstructor
public class GuardianBinding extends BaseEntity {

    @Column(name = "guardian_user_id", nullable = false)
    private Long guardianUserId;

    @Column(name = "elder_user_id", nullable = false)
    private Long elderUserId;

    @Column(nullable = false, length = 30)
    private String relationship;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @Column(name = "invite_code", length = 8)
    private String inviteCode;
}
