package com.hyp.alert;

import com.hyp.alert.entity.AlertDispatch;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AlertDispatchRepository extends JpaRepository<AlertDispatch, Long> {
    List<AlertDispatch> findByAlertId(Long alertId);
    List<AlertDispatch> findByGuardianUserIdOrderByCreatedAtDesc(Long guardianUserId);
}
