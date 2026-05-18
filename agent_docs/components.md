# Components

Danh sách đầy đủ các cấu phần (component/service/module) trong hệ thống KShip, vai trò và mục đích sử dụng.

---

## Backend Services

| Service | Port | Ngôn ngữ / Runtime | Framework | Vai trò / Mục đích |
|---------|------|--------------------|-----------|---------------------|
| `shipping-api` | :80 | PHP >= 7.1.3 | Laravel 5.6 | Core API — xử lý đơn hàng, quản lý carrier, multi-tenant, tích hợp carriers bên ngoài |
| `shipping-cpanel` | :88 | PHP >= 7.2 | Laravel 5.6 | Admin/Ops panel — giao diện quản trị nội bộ cho operator; produce Kafka events |
| `shipping-cron` | — | PHP >= 7.1.3 | Laravel 5.6 | Scheduled jobs — tác vụ nền định kỳ: sync trạng thái đơn, reconcile data, cleanup |
| `shipping-merchant` | REST :9898 / gRPC :8082 | Go 1.22 | Gin v1.10 | Merchant portal backend — quản lý merchant/seller; Kafka consumer; tích hợp KMA, KTarget |
| `kship-golang-check-price` | :3456 | Go 1.21 | Gin v1.9 | Pricing engine v5 (hiện tại) — tra cước realtime, cache Redis, tích hợp trực tiếp Carrier APIs |
| `kship-nodejs-check-price-v3` | :3021 | Node.js | Express ^4.18 | Pricing engine v3 (legacy) — chỉ dùng cho luồng backward-compat từ `shipping-api` |
| `kship-golang-add-on` | REST :8888 / gRPC :8082 | Go 1.21.4 | Gin v1.9 | Add-on service — coupon/voucher, in nhãn, label; gọi gRPC tới user-service và registration-service |
| `shipping-report` | :8000 | PHP ^7.2.5 \| ^8.0 | Laravel ^7.29 | Reporting v1 (legacy) — Kafka consumer, phục vụ analytics cũ |
| `shipping-report-v5` | :8888 | Go 1.24 | Gin v1.11 | Reporting v5 — Clean Architecture, OTel tracing, Kafka consumer, multi-tenant shard routing |

### Dependencies chi tiết

| Service | DB / Storage | Cache | Messaging | Tracing | Thư viện đáng chú ý |
|---------|-------------|-------|-----------|---------|----------------------|
| `shipping-api` | MariaDB | Redis (predis ^1.1) | — | — | Laravel Horizon ^1.2, JWT (tymon ^0.5, firebase-jwt ^5.2), Guzzle ^7.8, AWS S3 3.304.5, dingo/api, maatwebsite/excel |
| `shipping-cpanel` | MariaDB, MongoDB (jenssegers ^3.5) | Redis (predis ^1.1) | Kafka (produce) | — | Laravel Horizon ^1.2, JWT, Guzzle ^6.3, BigQuery ^1.18, ClickHouse ^1.5, socialite ^3.2 |
| `shipping-cron` | MariaDB, MongoDB (jenssegers ^3.5) | Redis (predis ^1.1) | — | — | Laravel Horizon ^1.2, JWT, Guzzle ^6.3, AWS S3 ~3.0 |
| `shipping-merchant` | MySQL (GORM v1.25.11), MongoDB v1.16 | go-redis v9.6.1 | confluent-kafka-go v2.5.0 | OTel v1.28 + Jaeger v1.17 | Gin v1.10, gRPC v1.65, uber/zap v1.27, uber/fx v1.22, viper v1.19, imroc/req v3.43 |
| `kship-golang-check-price` | MySQL (GORM v1.25.5), MongoDB v1.12 | go-redis v9.2.1 | — | OTel v1.19 + Jaeger v1.17 | Gin v1.9, gRPC v1.59, uber/zap v1.26, uber/fx v1.20, golang-jwt v5, lumberjack v2.2 |
| `kship-nodejs-check-price-v3` | MongoDB (Mongoose ^5.13) | redis ^4.6.13 | — | stackify-node-apm | Express ^4.18, axios ^1.6, apicache ^1.5, v8-profiler-next |
| `kship-golang-add-on` | MySQL (GORM v1.25.5) | go-redis v9.5.1 | confluent-kafka-go v2.4.0 | OTel v1.21 + Jaeger v1.17 | Gin v1.9, gRPC v1.62, uber/zap v1.26, uber/fx v1.20, gocron v2.11 |
| `shipping-report` | MariaDB, MongoDB (jenssegers ^3.7) | Redis (predis ^2.0) | Kafka (consume) | — | Laravel Horizon ^4.0, JWT (tymon ^1.0), Guzzle ^6.3\|^7.0, AWS S3 3.6.0 |
| `shipping-report-v5` | MySQL + PostgreSQL (GORM v1.31), MongoDB v2.4, ClickHouse v2.30 | go-redis v9.17.1 | confluent-kafka-go v2.12.0 | OTel v1.38 + OTLP HTTP | Gin v1.11, Prometheus client v1.23, uber/zap v1.27, uber/fx v1.24, swaggo v1.16, ants v2.11, samber/lo v1.52 |

---

## Frontend / Widget

| Service | Deploy | Stack | Vai trò / Mục đích |
|---------|--------|-------|---------------------|
| `shipping-widget` | S3/CDN | JavaScript, Webpack | Widget đa năng — tra giá, vé, KShip; gọi check-price v5 rồi tạo đơn qua `shipping-api` |
| `kship-widget-fnb` / `kship/` | S3/CDN | Vue 3.5, Vite 6.2, TypeScript 5.8, Pinia ^3.0, Vitest ^3.0 | Widget chính FnB — nhúng vào trang merchant ngành F&B |
| `kship-widget-fnb` / `price-fnb/` | S3/CDN | Vue 3.5, Vite 4.4, TypeScript 5.2, Pinia ^2.1, vue-router ^4.2, Vitest ^0.34 | Component tra giá FnB — hỗ trợ calendar, IndexedDB (idb ^7.1), nén build (vite-plugin-compression) |

---

## Quality Assurance

| Service | Node | Stack | Vai trò / Mục đích |
|---------|------|-------|---------------------|
| `kship-wiki-v2` | >= 18.0.0 | TypeScript ^5.0, CucumberJS 12.2, Playwright 1.56, Allure, Faker, KafkaJS ^2.2, mysql2 ^3.20, mongodb ^6.21, mssql 12.0, TypeORM ^0.3 | BDD test automation & living docs — profiles: `@api`, `@web`, `@mobile`, `@integration` |

---

## Shared Infrastructure

| Component | Vai trò / Mục đích |
|-----------|---------------------|
| **MariaDB :3306** | Primary transactional DB — `kvshipping` (orders, carriers, tenants), `kship_merchant`, `module_coupon` |
| **MongoDB :27017** | Document store — reports, merchant data, location data |
| **Redis :6379** | Cache, session, queue, idempotency keys (dedup Kafka messages) |
| **Kafka :9092** | Async event messaging theo Outbox pattern — kết nối `shipping-api` / `shipping-cpanel` → consumers |
| **AWS S3 / CDN** | Static assets cho widgets |

---

## External Carrier Integrations

Tích hợp qua `shipping-api` và `kship-golang-check-price`:

| Carrier | Ghi chú |
|---------|---------|
| Viettel Post | |
| GHN (Giao Hàng Nhanh) | |
| GHTK (Giao Hàng Tiết Kiệm) | |
| BEST Express | |
| Ahamove | |
| Speedlink | |
| Ticket Center | |

---

## Giao tiếp giữa các cấu phần

```
[End-user / Merchant]
    │
    ├──► shipping-widget / kship-widget-fnb
    │         │ check-price  → kship-golang-check-price (:3456) → Carrier APIs
    │         │ tạo đơn      → shipping-api (:80)
    │
    └──► Internal Operator → shipping-cpanel (:88)

[shipping-api / shipping-cpanel]
    │ produce Kafka (Outbox pattern)
    ▼
Kafka :9092
    ├──► shipping-merchant   (self-delivery events)
    ├──► shipping-report     (legacy analytics)
    └──► shipping-report-v5  (analytics v5)

[shipping-api]
    ├──► REST → kship-golang-check-price (:3456)      (check price nội bộ, v5)
    ├──► REST → kship-nodejs-check-price-v3 (:3021)   (check price nội bộ, legacy)
    └──► REST → kship-golang-add-on (:8888)            (coupon, label, print)

[kship-golang-add-on]
    ├──► gRPC :8186  (user-service)
    └──► gRPC :8188  (registration-service)

[shipping-merchant]
    ├──► REST → shipping-api
    ├──► REST → KMA (open-kma external API)
    └──► REST → KTarget API
```

---

## Observability

| Tool | Service áp dụng | Mục đích |
|------|----------------|----------|
| OTel + OTLP → Tempo | `shipping-report-v5` | Distributed tracing |
| OTel + Jaeger | `shipping-merchant`, `kship-golang-check-price`, `kship-golang-add-on` | Distributed tracing |
| Prometheus → Grafana | Tất cả Go services | Metrics scrape `/api/metrics` |
| kship-wiki-v2 BDD | Toàn hệ thống | Functional test coverage |
