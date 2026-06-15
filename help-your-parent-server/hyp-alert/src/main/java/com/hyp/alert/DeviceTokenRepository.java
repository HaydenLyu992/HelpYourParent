package com.hyp.alert;

import com.hyp.alert.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByUserId(Long userId);
    List<DeviceToken> findByUserIdIn(List<Long> userIds);
}
