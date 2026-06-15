package com.hyp.guardian;

import com.hyp.guardian.entity.BindingRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BindingRequestRepository extends JpaRepository<BindingRequest, Long> {
    List<BindingRequest> findByToUserIdAndStatus(Long toUserId, String status);
    boolean existsByFromUserIdAndToUserIdAndStatus(Long fromId, Long toId, String status);
}
