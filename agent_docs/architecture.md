# System Architecture

## Topology

```
  ┌──────────────────────────────────────────┐   ┌───────────────────────────┐
  │        End-user / Merchant Widget        │   │  Internal Operator/Admin  │
  │  shipping-widget     kship-widget-fnb    │   │  (browser, internal tool) │
  │  (JS / S3 CDN)       (JS / S3 CDN, FnB)  │   └─────────────┬─────────────┘
  └──────┬──────────────────────┬────────────┘                 │ REST
         │ REST (orders)        │ REST (check-price)           │
         ▼                      ▼                              ▼
  ┌─────────────────┐   ┌───────────────────────┐   ┌──────────────────────┐
  │  shipping-api   │   │ kship-golang-         │   │  shipping-cpanel     │
  │  (PHP, :80)     │   │ check-price           │   │  (PHP, :88)          │
  │  Core API       │   │ (Go 1.21, :3456)      │   │  Admin/Ops panel     │
  │  REST→add-on    │   │ Redis + MySQL         │   └────────────┬─────────┘
  │  REST→cp-v3     │   │ → Carrier APIs        │                │
  └──────┬──────────┘   └───────────────────────┘                │
         │ Kafka                                                 │ Kafka
         └──────────────────────────┬────────────────────────────┘
                                    ▼ Kafka Topics
               ┌────────────────────┬──────────────────┬──────────────────┐
               ▼                    ▼                  ▼                  ▼
      ┌─────────────────┐  ┌──────────────┐  ┌──────────────────┐  ┌──────────┐
      │shipping-merchant│  │shipping-     │  │shipping-report-v5│  │shipping- │
      │ (Go 1.22, :9898)│  │report        │  │(Go 1.24, :8888)  │  │cron      │
      │ Merchant portal │  │(PHP, :8000)  │  │Clean Arch + OTel │  │(PHP)     │
      └─────────────────┘  └──────────────┘  └──────────────────┘  └──────────┘

  ┌────────────────────────────────────────────────────────────────────────────┐
  │  kship-golang-add-on (Go 1.24, REST :8888, gRPC :8082)                     │
  │  Coupons, vouchers, print/label — gRPC → user-svc :8186, reg-svc :8188     │
  └────────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────┐
  │  kship-nodejs-check-price-v3 (Node.js, :3021) — legacy pricing       │
  └──────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────┐
  │  Shared: MariaDB :3306 · Redis :6379 · MongoDB :27017 · Kafka :9092  │
  └──────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────┐
  │  kship-wiki-v2 (CucumberJS + Playwright) — @api @web @integration    │
  └──────────────────────────────────────────────────────────────────────┘
```

## Services

| Service | Stack | Port | Role |
|---------|-------|------|------|
| `shipping-api` | Laravel PHP 7.3 | :80 | Core platform API — orders, carriers, tenants |
| `shipping-cpanel` | Laravel PHP 7.3 | :88 | Admin control panel |
| `shipping-cron` | Laravel PHP 7.3 | — | Scheduled background jobs |
| `shipping-merchant` | Go 1.22, Gin, gRPC | :9898 / :8082 | Merchant/seller management |
| `kship-golang-check-price` | Go 1.21, Gin | :3456 | Pricing engine (current) |
| `kship-nodejs-check-price-v3` | Node.js 16, Express | :3021 | Pricing engine (legacy) |
| `kship-golang-add-on` | Go 1.24, Gin, gRPC | :8888 / :8082 | Coupons, vouchers, print labels |
| `shipping-report` | Laravel PHP 7.3 | :8000 | Reporting (legacy, Kafka-driven) |
| `shipping-report-v5` | Go 1.24, Gin, GORM | :8888 | Reporting v5 — Clean Arch, OTel |
| `kship-widget-fnb` | JS / Webpack | S3/CDN | FnB shipping widget |
| `shipping-widget` | JS / Webpack | S3/CDN | Price / ticket / KShip widget |
| `kship-wiki-v2` | TypeScript, CucumberJS, Playwright | — | BDD test automation & living docs |

## Shared Infrastructure

| Component | Purpose |
|-----------|---------|
| MariaDB :3306 | Primary transactional DB (`kvshipping`, `kship_merchant`, …) |
| MongoDB :27017 | Document store — reports, merchant data, location |
| Redis :6379 | Cache, session, queue, idempotency keys |
| Kafka :9092 | Async event messaging (Outbox pattern) |
| AWS S3 / CDN | Static assets for widgets |

## Key Data Flows

### API → Kafka → Consumers
```
shipping-api / shipping-cpanel
    │ produce (Outbox → Kafka)
    ▼
Kafka Topics
    ├──► shipping-merchant   (consumer: self-delivery events)
    ├──► shipping-report     (consumer: legacy analytics)
    └──► shipping-report-v5  (consumer: v5 analytics)
```

### Widget → Check Price v5
```
shipping-widget / kship-widget-fnb
    │ REST POST /api/v5/check-price
    ▼
kship-golang-check-price (:3456)          ← check price v5 engine
    │
    ├──► Redis (cache kết quả theo route + weight)
    ├──► MySQL (cấu hình giá, vùng)
    └──► Carrier APIs (Viettel, GHTK, Ahamove, BEST, …)
              │
              └──► trả về danh sách giá + ETA cho widget hiển thị
                   → user chọn carrier → widget gọi shipping-api tạo đơn
```

### API → Check Price (internal, v3 / v5)
```
shipping-api (:80)
    │
    ├──► REST → kship-nodejs-check-price-v3 (:3021)   ← check price v3 (legacy)
    └──► REST → kship-golang-check-price (:3456)      ← check price v5
```

### Add-on (Print / Coupon / Label)
```
Client            → kship-golang-add-on (:8888 REST)
shipping-api (:80)→ kship-golang-add-on (:8888 REST)   ← internal REST call
                          │
                          ├──► gRPC :8186 (user-service)
                          ├──► gRPC :8188 (registration-service)
                          └──► MySQL (module_coupon) + Redis
```

### Merchant Portal
```
Client → shipping-merchant (:9898)
              │
              ├──► shipping-api (internal REST)
              ├──► KMA (open-kma external API)
              ├──► KTarget API
              ├──► Kafka consumer
              └──► MariaDB (kship_merchant) + MongoDB + Redis
```

## External Carrier Integrations
All connected through `shipping-api` and `kship-golang-check-price`:
- Viettel Post, GHN, GHTK, BEST, Ahamove, Speedlink, Ticket Center

## Observability
- **Tracing**: OpenTelemetry → Tempo (shipping-report-v5), Jaeger (kship-golang-check-price)
- **Metrics**: Prometheus scrape `/api/metrics` (Go services) → Grafana
- **Tests**: kship-wiki-v2 BDD automation (`@api`, `@web`, `@integration`)
