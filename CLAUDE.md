# CLAUDE.md — HelpYourParent (康护亲)

## 项目概述

帮助子女远程守护父母健康的 iOS App。包含用户注册登录体系，通过 HealthKit 读取老人健康数据，结合个人健康档案与 DeepSeek V4 Flash 大模型进行智能风险分析，发现异常时通过短信/邮件通知绑定的守护者。

## 设计规范
涉及 UI/UX 任务时，自动应用 UI/UX Pro Max 设计系统。设计需面向老年用户：大字体（不小于 17pt）、高对比度、简洁导航、大触控区域（≥44pt）、减少信息密度。图标使用 SF Symbols，禁止 emoji 作为图标。必须符合 Apple HIG 与深色模式适配。

## 项目架构总览

```
┌─────────────────────────────────────────────┐
│  iOS App (前端)                              │
│  SwiftUI + HealthKit + Core ML              │
│  → 可独立编译，运行时需连接后端               │
└────────────────────┬────────────────────────┘
                     │ HTTP / HTTPS
                     ▼
┌─────────────────────────────────────────────┐
│  Spring Cloud 后端服务 (ECS / ACK 容器部署)    │
│                                              │
│  服务注册: Nacos  ·  配置中心: Nacos          │
│  限流降级: Sentinel  ·  链路追踪: 可选 SkyWalking│
│                                              │
│  ┌──────────┐ ┌────────────┐ ┌─────────────┐ │
│  │ 用户模块  │ │ 守护者模块  │ │  告警模块    │ │
│  └──────────┘ └────────────┘ └─────────────┘ │
│  ┌──────────┐ ┌────────────┐                 │
│  │ 健康模块  │ │  AI 模块   │                 │
│  └──────────┘ └────────────┘                 │
│                                              │
│  数据层: MySQL + Redis                       │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  阿里云函数计算 FC (补充场景)                  │
│  → fn-deepseek-gateway  (大模型 API 代理)    │
│  → fn-send-sms          (短信发送)           │
│  → fn-send-email        (邮件发送)           │
└─────────────────────────────────────────────┘
```

- **前后端分离**：iOS App 通过 HTTP 调用后端 API，JSON 格式交互，后端不依赖 iOS 编译环境。
- **Spring Cloud 就绪**：代码按模块拆分，当前可单体部署降低运维成本，流量增长后可拆分为独立微服务，只需将模块间的本地调用改为 Feign 远程调用。

## 关键约束

- **健康数据不出设备**：HealthKit 传感器采集的原始生理数据（心率、血氧、ECG 等）仅在设备本地分析，不上传云端。后端仅存储脱敏后的风险摘要和告警记录。用户手动填写的健康档案（身高、体重、病史、用药）因守护者查看和 AI 分析需要，会加密传输并存于服务端。
- **Apple 审核合规**：HealthKit 使用必须通过 App Review，Info.plist 中必须包含 `NSHealthShareUsageDescription` 和 `NSHealthUpdateUsageDescription`。
- **最低系统版本**：iOS 17+（SwiftUI 5.0 / SwiftData / HealthKit 增强）。
- **本地化优先**：首发简体中文，所有用户可见字符串使用 `String(localized:)`，预留多语言能力。

## 技术栈

### 前端 (iOS)

| 层级 | 选型 |
|------|------|
| UI | SwiftUI + Combine |
| 健康数据 | HealthKit (`HKHealthStore`) |
| 本地存储 | SwiftData |
| 本地 AI | Core ML (心率异常分类、跌倒确认) |
| 网络 | URLSession + Codable |

### 后端 (Java)

| 层级 | 选型 |
|------|------|
| 语言 | Java 17 + Spring Boot 3.x |
| 微服务框架 | Spring Cloud Alibaba 2023.0.x (兼容 Spring Boot 3.2+) |
| 服务注册 & 配置 | Nacos |
| API 网关 | Spring Cloud Gateway |
| 限流降级 | Sentinel |
| 鉴权 | Spring Security + JWT (自维护 Session Token) |
| ORM | Spring Data JPA + QueryDSL |
| 数据库 | 阿里云 RDS MySQL 8.0 |
| 缓存 | 阿里云 Redis 7.0 |
| 短信 | 阿里云短信 SDK (通过函数计算 FC 异步调用) |
| 邮件 | 阿里云邮件推送 SDK (通过函数计算 FC 异步调用) |
| 部署 | 阿里云 ECS (单体初期) / ACK (拆分后) |

### 云函数 (FC 补充)

| 函数 | 职责 | 触发方式 |
|------|------|---------|
| `fn-deepseek-gateway` | DeepSeek API 代理（大模型调用耗时长，独立出去避免阻塞服务线程池） | HTTP (由后端服务 Async 调用) |
| `fn-send-sms` | 短信发送（独立出去方便独立扩缩容，避免短信发送失败影响主链路） | HTTP (由 hyp-alert 异步调用) |
| `fn-send-email` | 邮件发送（同上） | HTTP (由 hyp-alert 异步调用) |

> 为什么不把短信/邮件直接写在 Spring Boot 里？初期可以，但独立成云函数的好处是：短信/邮件发送属于 IO 密集型操作，独立部署后不影响主业务服务性能，且支持独立扩缩容。

## 项目结构

```
HelpYourParent/
├── HelpYourParent.xcodeproj               # iOS App (前端)
├── App/
│   ├── HelpYourParentApp.swift
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Features/
│   ├── Auth/                              # 注册登录
│   ├── HealthDashboard/                   # 首页仪表盘
│   ├── HealthProfile/                     # 个人健康档案
│   ├── RiskAnalysis/                      # 风险分析引擎
│   │   ├── RiskEngine.swift
│   │   ├── RiskRules/                     # 规则定义
│   │   └── CoreML/                        # Core ML 模型
│   ├── AIAssistant/                       # AI 健康助手
│   ├── Guardian/                          # 守护者管理
│   ├── Settings/                         # 通知偏好设置
│   │   ├── NotificationSettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── Alerts/                            # 告警系统
│       ├── AlertManager.swift
│       ├── AlertLevel.swift
│       └── AlertHistoryView.swift
├── Core/
│   ├── HealthKit/                         # HealthKit 封装
│   ├── AI/                                # DeepSeekService + AIPrompts
│   ├── Network/                           # APIClient + endpoint 配置
│   ├── Persistence/                       # SwiftData 模型
│   └── Extensions/
├── Resources/
│   ├── Info.plist
│   ├── Assets.xcassets
│   └── Localizable.strings
│
├── help-your-parent-server/               # 后端服务 (Spring Boot 多模块)
│   ├── hyp-common/                        # 公共模块 (DTO/Utils/Exception/Constants)
│   │   └── src/main/java/com/hyp/common/
│   ├── hyp-user/                          # 用户模块 (注册/登录/角色/通知偏好)
│   │   └── src/main/java/com/hyp/user/
│   ├── hyp-guardian/                      # 守护者模块 (绑定/查询/权限)
│   │   └── src/main/java/com/hyp/guardian/
│   ├── hyp-alert/                         # 告警模块 (规则编排/分级/分发)
│   │   └── src/main/java/com/hyp/alert/
│   ├── hyp-health/                        # 健康模块 (摘要查询/趋势计算)
│   │   └── src/main/java/com/hyp/health/
│   ├── hyp-ai/                            # AI 模块 (DeepSeek代理/Prompt管理)
│   │   └── src/main/java/com/hyp/ai/
│   ├── hyp-gateway/                       # API 网关 (Spring Cloud Gateway)
│   │   └── src/main/java/com/hyp/gateway/
│   ├── hyp-service/                       # 启动入口 + 配置聚合
│   │   ├── src/main/java/com/hyp/service/
│   │   └── src/main/resources/
│   │       ├── application.yml
│   │       └── bootstrap.yml              # Nacos 配置
│   └── pom.xml                            # 父 POM
│
├── cloud-functions/                       # 阿里云函数计算 (FC)
│   ├── fn-deepseek-gateway/
│   │   ├── index.js
│   │   └── package.json
│   ├── fn-send-sms/
│   │   ├── index.js
│   │   └── package.json
│   └── fn-send-email/
│       ├── index.js
│       └── package.json
│
└── docs/                                  # 架构文档 & API 接口文档
```

## Spring Cloud 微服务拆分策略

当前采用**模块化单体（Modular Monolith）**部署，各模块编译为独立 JAR 但运行在同一个进程中；条件成熟时可按以下粒度拆出独立服务：

| 当前模块 | 拆分为独立服务 | 拆出条件 |
|----------|--------------|---------|
| `hyp-user` | user-service | 用户量突破 10w，登录 QPS > 500 |
| `hyp-guardian` | guardian-service | 守护者关系查询成为热点 |
| `hyp-alert` | alert-service | 告警延迟要求 < 1s，需独立线程池 |
| `hyp-health` | health-service | 健康摘要计算量增大 |
| `hyp-ai` | ai-service | DeepSeek 调用量增长，需独立限流 |
| `hyp-gateway` | gateway-service | 已有，作为 API 统一入口 |

拆分步骤：
1. 在 Nacos 中注册新服务名
2. 模块间本地 `@Service` 调用改为 `@FeignClient`
3. Sentinel 配置新的限流规则
4. 独立数据库时，通过 Seata 引入分布式事务

## 数据流

```
HealthKit 健康数据存储
      │
      ▼
HealthKitManager (本地读取) ──► SwiftData 本地缓存
      │
      ▼
RiskEngine (规则匹配 + Core ML 推理)
      │
      ├── 正常 ──► DailySummary 本地记录，无告警
      │
      └── 异常 ──► POST /api/alert/trigger
                        │
                    Spring Cloud Gateway
                        │
                    hyp-alert (告警编排)
                        │
                   查通知偏好 (sms? email? push?)
                        │
                   ┌────┼────┐
                   │    │    │
                   ▼    ▼    ▼
              DeepSeek  短信  邮件
              (async)   (async) (async)
                   │
       fn-deepseek-gateway (FC)
                   │
              DeepSeek API
                   │
              AI 风险解读文案
                   │
              ──► 生成告警消息 ──► fn-send-sms / fn-send-email ──► 守护者
```

## 用户注册登录

- **老人端**：手机号 + 阿里云短信验证码 → hyp-user 校验 → 签发 JWT → 写入 MySQL
- **守护者端**：同上，注册时额外填写与老人的关系，支持扫码绑定
- 两种角色共用 `user_profile` 表，通过 `role` 字段区分（`.elder` / `.guardian`）
- JWT 由 Spring Security 签发，客户端存入 iOS Keychain，后续请求在 Gateway 层校验
- 老人与守护者为多对多关系，中间表 `guardian_binding` 维护

## 通知偏好设置

- 每位守护者可独立配置三种通知渠道的开关：`push_enabled` / `sms_enabled` / `email_enabled`
- 三个开关彼此独立，可全部关闭——此时所有告警仅在 App 内的通知中心展示，不主动触达
- 老人在 App 内也看到自己的告警通知，同样走上述偏好
- 偏好数据存储在 `notification_preference` 表，与用户 ID 一对一绑定
- 告警分发时，`hyp-alert` 先查偏好再决定走哪些渠道：推送（APNs 直发，必经）、短信（可选）、邮件（可选）

## 数据库核心表

```sql
-- 用户表
user_profile: id, phone, role, nickname, avatar_url, created_at

-- 老人健康档案 (user_id 为 FK → user_profile.id)
elder_profile: id, user_id(FK), height, weight, blood_type, birthday, 
               medical_history(JSON), medications(JSON), allergies(JSON)

-- 守护者绑定 (guardian_user_id / elder_user_id 均为 FK → user_profile.id)
guardian_binding: id, guardian_user_id(FK), elder_user_id(FK), relationship, status, created_at

-- 告警记录 (脱敏)
alert_record: id, elder_user_id, alert_level, risk_type, created_at, dispatched_at

-- 通知偏好
notification_preference: id, user_id, push_enabled, sms_enabled, email_enabled, updated_at

-- 告警接收记录
alert_dispatch: id, alert_id, guardian_user_id, channel(sms/email/push), status, sent_at
```

## DeepSeek V4 Flash 集成

- **模型**：`deepseek-chat`（V4 Flash），OpenAI 兼容 API
- **Base URL**：`https://api.deepseek.com/v1/chat/completions`
- **调用链路**：iOS → Gateway → hyp-ai (async) → fn-deepseek-gateway (FC) → DeepSeek → 回写告警文案
- **API Key 存储**：仅存在于阿里云函数计算环境变量中，Spring Boot 通过调用云函数间接访问，不直接持有 Key。客户端零接触

| 场景 | 输入 | 输出 |
|------|------|------|
| 风险解读 | 脱敏异常指标 + 病史摘要 | 通俗风险解释 + 就医建议 |
| 用药咨询 | 当前用药列表 | 药物相互作用提醒 + 注意事项 |
| 健康报告 | 一周健康趋势摘要 | 自然语言周报 |
| AI 问诊 | 自然语言提问 | 基于档案上下文的建议 |

- **Prompt 管理**：分为两层——iOS 端 `Core/AI/AIPrompts.swift` 存储 AI 助手对话 prompt（用户问诊、用药咨询等交互场景）；后端 `hyp-ai` 模块管理告警解读 prompt（系统自动触发，组装脱敏健康数据后调用 DeepSeek 生成文案）
- **隐私约束**：传给 DeepSeek 的数据必须脱敏，不含真实姓名、手机号、GPS。日志保留 7 天审计。

## 风险规则设计原则

- 每条规则实现协议 `protocol RiskRule { func evaluate(snapshot: HealthSnapshot, profile: ElderProfile) -> RiskResult? }`（Swift，运行在 iOS 本地）
- HealthKit 后台推送：通过 `HKObserverQuery` 监听健康数据类型变化，系统在数据更新时唤醒 App 进行增量分析；同时使用 `HKAnchoredObjectQuery` 在 App 前台启动时拉取增量数据
- 规则参数依据《中国老年人健康管理专家共识》设定默认值，守护者可微调
- 规则输出包含：风险等级（yellow/orange/red）、风险名称、建议措施文案
- 多条规则同时命中时取最高等级

### 默认阈值

| 指标 | 绿色线 | 黄色线 | 橙色线 | 红色线 |
|------|--------|--------|--------|--------|
| 静息心率 (bpm) | 60-90 | 50-60 / 90-110 | 45-50 / 110-130 | <45 / >130 |
| SpO₂ (%) | ≥95 | 90-95 | 85-90 | <85 |
| 跌倒置信度 | 无 | — | — | 跌倒事件 |
| 静止时间 (h) | <4 | 4-6 | 6-12 | >12 |

## 常用命令

```bash
# ===== iOS 前端 =====
xcodebuild -project HelpYourParent.xcodeproj -scheme HelpYourParent \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild test -project HelpYourParent.xcodeproj -scheme HelpYourParent \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Swift Package Manager
swift package resolve
swift package update

# ===== 后端 Spring Boot =====
cd help-your-parent-server

# 编译所有模块
mvn clean package -DskipTests

# 运行单体服务 (Nacos 需先启动)
cd hyp-service
mvn spring-boot:run

# 运行单元测试
mvn test

# Docker 构建
docker build -t hyp-service:latest .

# ===== 云函数 =====
# 使用 fun CLI 或 Serverless Devs 部署
cd cloud-functions/fn-deepseek-gateway
s deploy
```

## 命名规范

- SwiftUI View 以 `View` 结尾：`DashboardView.swift`
- ViewModel 以 `ViewModel` 结尾：`DashboardViewModel.swift`
- iOS 模型以名词命名：`UserProfile`, `AlertRecord`
- iOS 管理器以 `Manager` 结尾：`HealthKitManager`, `AlertManager`
- Swift 规则以 `Rule` 结尾：`HeartRateRule`
- Java 包名遵循 `com.hyp.<module>`，类名遵循阿里规约
- 云函数以 `fn-` 前缀命名：`fn-deepseek-gateway`
- 数据库表名 `snake_case` 下划线分隔

## 注意事项

- HealthKit 授权在每次 App 启动时检查，拒绝或部分授权要优雅降级
- Core ML 模型仅在 iPhone 本地运行，原始数据不出设备
- 验证码生成/校验逻辑在 `hyp-user` 服务端完成，客户端不可信
- 短信模板需提前在阿里云后台报备
- DeepSeek、阿里云短信/邮件的 AK/SK 统一通过 Nacos 配置中心下发，或直接注入函数计算环境变量
- 告警记录存入 MySQL 时脱敏（仅存风险类型、时间、等级，不含原始健康数值）
- JWT 过期时间：access_token 2h，refresh_token 7d
- APNs 推送使用 Apple Developer 账号签发的 JWT（在 hyp-alert 服务中维护），定期刷新
- 单体部署阶段，Nacos 可以和业务服务部署在同一台 ECS 上；拆分后 Nacos 需独立部署或使用 MSE（微服务引擎）托管版
- DeepSeek API 超时（> 30s）或限流时，告警消息降级为无 AI 解读的纯文本，正常发送短信/邮件，不阻塞告警主链路
- 设备断网时本地队列暂存待发告警，网络恢复后自动补发；超过 5 分钟的告警标记为"延迟送达"并注明实际发生时间
- 同一老人在短时间内（如 5 分钟窗口内）触发多条告警时，合并为一条聚合消息发送，避免守护者收到短信轰炸
