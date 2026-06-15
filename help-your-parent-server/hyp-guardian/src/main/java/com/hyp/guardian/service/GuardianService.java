package com.hyp.guardian.service;

import com.hyp.alert.DeviceTokenRepository;
import com.hyp.alert.entity.DeviceToken;
import com.hyp.alert.service.APNsService;
import com.hyp.common.BusinessException;
import com.hyp.common.User;
import com.hyp.common.UserRepository;
import com.hyp.guardian.BindingRequestRepository;
import com.hyp.guardian.GuardianBindingRepository;
import com.hyp.guardian.dto.BindRequest;
import com.hyp.guardian.dto.GuardianInfo;
import com.hyp.guardian.dto.PendingRequestInfo;
import com.hyp.guardian.entity.BindingRequest;
import com.hyp.guardian.entity.GuardianBinding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class GuardianService {

    private final GuardianBindingRepository bindingRepo;
    private final BindingRequestRepository requestRepo;
    private final UserRepository userRepository;
    private final DeviceTokenRepository deviceTokenRepo;
    private final APNsService apnsService;

    @Transactional
    public void requestBind(Long fromUserId, BindRequest req) {
        User target = userRepository.findByPhone(req.getElderPhone())
                .orElseThrow(() -> BusinessException.notFound("用户"));

        if (requestRepo.existsByFromUserIdAndToUserIdAndStatus(fromUserId, target.getId(), "PENDING")) {
            throw BusinessException.alreadyExists("绑定申请");
        }
        if (bindingRepo.findByGuardianUserIdAndElderUserId(fromUserId, target.getId()).isPresent()) {
            throw BusinessException.alreadyExists("绑定关系");
        }

        BindingRequest br = new BindingRequest();
        br.setFromUserId(fromUserId);
        br.setToUserId(target.getId());
        br.setRelationship(req.getRelationship());
        br.setMessage(req.getMessage());
        br.setStatus("PENDING");
        requestRepo.save(br);

        // Push to target user
        User fromUser = userRepository.findById(fromUserId).orElse(null);
        String fromName = fromUser != null ? fromUser.getNickname() : "用户";
        DeviceToken token = deviceTokenRepo.findByUserId(target.getId()).orElse(null);
        if (token != null) {
            apnsService.sendPush(token.getToken(),
                    "🤝 新的绑定申请",
                    fromName + " 申请成为您的" + req.getRelationship() + "，点击查看详情",
                    Map.of("type", "binding_request", "requestId", br.getId(), "fromUserId", fromUserId));
        }
        log.info("Binding request: user {} -> {} as {}", fromUserId, target.getId(), req.getRelationship());
    }

    @Transactional
    public GuardianBinding acceptBind(Long requestId, Long userId) {
        BindingRequest br = requestRepo.findById(requestId)
                .orElseThrow(() -> BusinessException.notFound("绑定申请"));
        if (!br.getToUserId().equals(userId)) {
            throw new BusinessException("无权操作此申请");
        }
        if (!"PENDING".equals(br.getStatus())) {
            throw new BusinessException("该申请已处理");
        }
        br.setStatus("ACCEPTED");
        requestRepo.save(br);

        GuardianBinding binding = new GuardianBinding();
        binding.setGuardianUserId(br.getFromUserId());
        binding.setElderUserId(br.getToUserId());
        binding.setRelationship(br.getRelationship());
        binding.setStatus("ACTIVE");
        bindingRepo.save(binding);

        log.info("Binding accepted: {} <-> {}", br.getFromUserId(), br.getToUserId());
        return binding;
    }

    @Transactional
    public void rejectBind(Long requestId, Long userId) {
        BindingRequest br = requestRepo.findById(requestId)
                .orElseThrow(() -> BusinessException.notFound("绑定申请"));
        if (!br.getToUserId().equals(userId)) {
            throw new BusinessException("无权操作此申请");
        }
        br.setStatus("REJECTED");
        requestRepo.save(br);
        log.info("Binding rejected: {} by user {}", requestId, userId);
    }

    public List<PendingRequestInfo> pendingRequests(Long userId) {
        return requestRepo.findByToUserIdAndStatus(userId, "PENDING").stream()
                .map(br -> {
                    User from = userRepository.findById(br.getFromUserId()).orElse(null);
                    return new PendingRequestInfo(
                            br.getId(),
                            br.getFromUserId(),
                            from != null ? from.getNickname() : "未知",
                            from != null ? from.getPhone() : "",
                            br.getRelationship(),
                            br.getMessage(),
                            br.getCreatedAt()
                    );
                }).toList();
    }

    @Transactional
    public void unbind(Long guardianUserId, Long elderUserId) {
        GuardianBinding binding = bindingRepo
                .findByGuardianUserIdAndElderUserId(guardianUserId, elderUserId)
                .orElseThrow(() -> BusinessException.notFound("绑定关系"));
        bindingRepo.delete(binding);
        log.info("Unbound: guardian {} <-> elder {}", guardianUserId, elderUserId);
    }

    public List<GuardianInfo> listGuardians(Long elderUserId) {
        return bindingRepo.findByElderUserId(elderUserId).stream().map(b -> {
            User u = userRepository.findById(b.getGuardianUserId()).orElse(null);
            return new GuardianInfo(b.getGuardianUserId(),
                    u != null ? u.getNickname() : "未知",
                    u != null ? u.getPhone() : "",
                    b.getRelationship(), b.getStatus());
        }).toList();
    }

    public List<GuardianInfo> listElders(Long guardianUserId) {
        return bindingRepo.findByGuardianUserId(guardianUserId).stream().map(b -> {
            User u = userRepository.findById(b.getElderUserId()).orElse(null);
            return new GuardianInfo(b.getElderUserId(),
                    u != null ? u.getNickname() : "未知",
                    u != null ? u.getPhone() : "",
                    b.getRelationship(), b.getStatus());
        }).toList();
    }
}
