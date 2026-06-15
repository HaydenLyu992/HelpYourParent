package com.hyp.guardian.entity;

import com.hyp.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "binding_request")
@Getter
@Setter
@NoArgsConstructor
public class BindingRequest extends BaseEntity {

    @Column(name = "from_user_id", nullable = false)
    private Long fromUserId;

    @Column(name = "to_user_id", nullable = false)
    private Long toUserId;

    @Column(nullable = false, length = 30)
    private String relationship;

    @Column(nullable = false, length = 20)
    private String status = "PENDING";

    @Column(length = 200)
    private String message;
}
