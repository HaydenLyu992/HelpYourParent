package com.hyp.guardian;

import com.hyp.guardian.entity.GuardianBinding;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GuardianBindingRepository extends JpaRepository<GuardianBinding, Long> {
    List<GuardianBinding> findByElderUserId(Long elderUserId);
    List<GuardianBinding> findByGuardianUserId(Long guardianUserId);
    Optional<GuardianBinding> findByGuardianUserIdAndElderUserId(Long guardianId, Long elderId);
    Optional<GuardianBinding> findByInviteCode(String inviteCode);
}
