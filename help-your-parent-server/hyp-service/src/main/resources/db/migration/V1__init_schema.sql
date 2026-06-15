-- ==========================================
-- 康护亲 · 数据库初始化脚本
-- MySQL 8.0 · 字符集 utf8mb4
-- ==========================================

CREATE DATABASE IF NOT EXISTS hyp_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE hyp_db;

-- 用户表
CREATE TABLE user_profile (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号，登录凭证',
    role VARCHAR(20) NOT NULL COMMENT '角色: ELDER / GUARDIAN',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar_url VARCHAR(255) COMMENT '头像地址',
    password_hash VARCHAR(255) COMMENT '密码哈希（预留，当前短信验证码登录）',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_role (role)
) ENGINE=InnoDB COMMENT='用户表';

-- 老人健康档案
CREATE TABLE elder_profile (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '关联 user_profile.id',
    height DECIMAL(5,2) COMMENT '身高 cm',
    weight DECIMAL(5,2) COMMENT '体重 kg',
    blood_type VARCHAR(5) COMMENT '血型',
    birthday DATE COMMENT '出生日期',
    medical_history JSON COMMENT '既往病史 [{condition, diagnosed_at, notes}]',
    medications JSON COMMENT '当前用药 [{name, dose, frequency, since}]',
    allergies JSON COMMENT '过敏史 [string]',
    emergency_contact VARCHAR(20) COMMENT '紧急联系人电话',
    emergency_contact_name VARCHAR(50) COMMENT '紧急联系人姓名',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_elder_user FOREIGN KEY (user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='老人健康档案';

-- 守护者绑定关系
CREATE TABLE guardian_binding (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    guardian_user_id BIGINT NOT NULL COMMENT '守护者 user_id',
    elder_user_id BIGINT NOT NULL COMMENT '老人 user_id',
    relationship VARCHAR(30) NOT NULL COMMENT '关系: 子女/配偶/亲属/邻居/医生',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE / INACTIVE / PENDING',
    invite_code VARCHAR(8) COMMENT '邀请码，扫码绑定用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_guardian_elder (guardian_user_id, elder_user_id),
    INDEX idx_elder (elder_user_id),
    INDEX idx_guardian (guardian_user_id),
    CONSTRAINT fk_binding_guardian FOREIGN KEY (guardian_user_id) REFERENCES user_profile(id),
    CONSTRAINT fk_binding_elder FOREIGN KEY (elder_user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='守护者绑定关系';

-- 告警记录（脱敏存储）
CREATE TABLE alert_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    elder_user_id BIGINT NOT NULL COMMENT '关联老人 user_id',
    alert_level VARCHAR(10) NOT NULL COMMENT 'YELLOW / ORANGE / RED',
    risk_type VARCHAR(50) NOT NULL COMMENT '风险类型: HEART_RATE / SPO2 / FALL / INACTIVITY / SLEEP',
    summary VARCHAR(500) COMMENT '脱敏摘要',
    ai_advice TEXT COMMENT 'DeepSeek 生成的建议文案',
    is_merged TINYINT(1) DEFAULT 0 COMMENT '是否为合并告警',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dispatched_at DATETIME COMMENT '分发时间',
    INDEX idx_elder_time (elder_user_id, created_at DESC),
    INDEX idx_level (alert_level),
    CONSTRAINT fk_alert_elder FOREIGN KEY (elder_user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='告警记录（脱敏）';

-- 通知偏好
CREATE TABLE notification_preference (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '关联 user_profile.id',
    push_enabled TINYINT(1) NOT NULL DEFAULT 1 COMMENT '推送开关',
    sms_enabled TINYINT(1) NOT NULL DEFAULT 0 COMMENT '短信开关（暂不启用）',
    email_enabled TINYINT(1) NOT NULL DEFAULT 0 COMMENT '邮件开关（暂不启用）',
    quiet_hours_start TIME COMMENT '免打扰开始',
    quiet_hours_end TIME COMMENT '免打扰结束',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pref_user FOREIGN KEY (user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='通知偏好设置';

-- 绑定申请（推送通知 → 对方确认）
CREATE TABLE binding_request (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT NOT NULL COMMENT '发起申请的用户',
    to_user_id BIGINT NOT NULL COMMENT '被申请的用户',
    relationship VARCHAR(30) NOT NULL COMMENT '关系: 子女/配偶/亲属/邻居/医生',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/ACCEPTED/REJECTED',
    message VARCHAR(200) COMMENT '申请附言',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_to_user_status (to_user_id, status),
    UNIQUE KEY uk_from_to_pending (from_user_id, to_user_id, status),
    CONSTRAINT fk_req_from FOREIGN KEY (from_user_id) REFERENCES user_profile(id),
    CONSTRAINT fk_req_to FOREIGN KEY (to_user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='绑定申请记录';

-- 告警分发记录
CREATE TABLE alert_dispatch (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    alert_id BIGINT NOT NULL COMMENT '关联 alert_record.id',
    guardian_user_id BIGINT NOT NULL COMMENT '接收告警的守护者',
    channel VARCHAR(10) NOT NULL COMMENT 'PUSH / SMS / EMAIL',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING / SENT / FAILED / DELAYED',
    retry_count INT DEFAULT 0,
    error_msg VARCHAR(500) COMMENT '失败原因',
    sent_at DATETIME COMMENT '实际发送时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alert (alert_id),
    INDEX idx_guardian_status (guardian_user_id, status),
    CONSTRAINT fk_dispatch_alert FOREIGN KEY (alert_id) REFERENCES alert_record(id),
    CONSTRAINT fk_dispatch_guardian FOREIGN KEY (guardian_user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='告警分发记录';

-- 设备推送 Token
CREATE TABLE device_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '关联 user_profile.id',
    device_token VARCHAR(256) NOT NULL COMMENT 'APNs device token',
    platform VARCHAR(10) NOT NULL DEFAULT 'IOS',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_device (user_id),
    CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES user_profile(id)
) ENGINE=InnoDB COMMENT='设备推送Token';

-- 验证码表（Redis 为主，MySQL 备份）
CREATE TABLE verification_code (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    used TINYINT(1) NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone_expires (phone, expires_at)
) ENGINE=InnoDB COMMENT='短信验证码';
