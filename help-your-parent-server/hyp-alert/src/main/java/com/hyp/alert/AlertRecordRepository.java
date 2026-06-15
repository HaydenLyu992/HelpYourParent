package com.hyp.alert;

import com.hyp.alert.entity.AlertRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface AlertRecordRepository extends JpaRepository<AlertRecord, Long> {
    List<AlertRecord> findByElderUserIdAndCreatedAtAfter(Long elderUserId, LocalDateTime since);
    List<AlertRecord> findByElderUserIdOrderByCreatedAtDesc(Long elderUserId);
    List<AlertRecord> findByElderUserIdAndAlertLevelOrderByCreatedAtDesc(Long elderUserId, String alertLevel);
    long countByElderUserIdAndCreatedAtAfter(Long elderUserId, LocalDateTime since);
}
