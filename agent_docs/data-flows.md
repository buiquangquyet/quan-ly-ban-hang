# Data Flows

Tài liệu này mô tả các luồng dữ liệu chính trong hệ thống, dựa trên topology tại `agent_docs/architecture.md`.

---

## 1. Đặt đơn hàng (Widget → API)

```
End-user / Merchant
    │
    ├──► shipping-widget / kship-widget-fnb
    │         │ REST POST /api/v5/check-price  → kship-golang-check-price (:3456)
    │         │                                   (xem flow #2 bên dưới)
    │         │
    │         │ REST POST /orders  (user chọn carrier xong)
    │         ▼
    │    shipping-api (:80)
    │         │ lưu đơn vào MariaDB
    │         │ produce Kafka event (Outbox/CDC)
    │         ▼
    │    Kafka Topics  →  consumers (xem flow #4)
    │
    └──► Internal Operator → shipping-cpanel (:88) → tương tự
```

---

## 2. Check Price v5 (Widget → kship-golang-check-price)

Widget tra cước trực tiếp trước khi tạo đơn.

```
shipping-widget / kship-widget-fnb
    │ REST POST /api/v5/check-price
    ▼
kship-golang-check-price (:3456)          ← check price v5 engine
    │
    ├──► Redis  (cache kết quả theo route + weight)
    ├──► MySQL  (cấu hình giá, vùng phủ sóng)
    └──► Carrier APIs (Viettel, GHN, GHTK, BEST, Ahamove, Speedlink, …)
              │
              └──► trả về danh sách giá + ETA
                   → user chọn carrier → widget gọi shipping-api tạo đơn
```

---

## 3. Check Price nội bộ từ API (v3 / v5)

`shipping-api` tự gọi check-price khi cần tính cước trong luồng nghiệp vụ nội bộ.

```
shipping-api (:80)
    │
    ├──► REST → kship-nodejs-check-price-v3 (:3021)   ← check price v3 (legacy)
    └──► REST → kship-golang-check-price (:3456)      ← check price v5
```

---

## 4. Kafka Event Flow (API / CPanel → Consumers)

`shipping-api` và `shipping-cpanel` publish sự kiện trực tiếp lên Kafka.

```
shipping-api / shipping-cpanel
    │ produce → Kafka
    ▼
Kafka Topics
    ├──► shipping-merchant   (consumer: self-delivery events)
    ├──► shipping-report     (consumer: legacy analytics, PHP)
    └──► shipping-report-v5  (consumer: analytics v5, Go 1.24)
```

### Xử lý phía Consumer

```
Kafka Message
    │
    ▼
1. Extract message_id từ Kafka headers
    │
    ▼
2. Check Redis idempotency key → skip nếu đã xử lý
    │
    ▼
3. Resolve TenantContext (tenant_id, shard_id)
    │
    ▼
4. Dispatch to handler
    │
    ▼
5. Handler xử lý business logic qua UseCase
    │
    ▼
6. UseCase commit + ghi OutboxEvent trong cùng transaction
    │
    ▼
7. Outbox dispatcher publish downstream Kafka topics (async)
```

---

## 5. Outbox Pattern

Đảm bảo reliable event publishing: domain event được ghi vào DB cùng transaction với business data, sau đó Outbox dispatcher publish lên Kafka.

```
┌─ Same Transaction ──────────────────────┐
│                                         │
│  Business Data                          │
│  +                                      │
│  OutboxEvent table                      │
│                                         │
└─────────────────────────────────────────┘
                    │
                    ▼ Outbox dispatcher (async)
                    │
              Kafka Topic
                    │
                    ▼
          Downstream consumers
```

**Rules:**
- KHÔNG publish Kafka trực tiếp trong UseCase
- Outbox event luôn trong cùng transaction với business data
- Outbox dispatcher đọc OutboxEvent table và publish lên Kafka
- Downstream consumers xử lý idempotent (check `message_id`)

---

## 6. Add-on: Print / Coupon / Label

`shipping-api` và các client ngoài đều gọi `kship-golang-add-on` qua REST.

```
Client             ─┐
shipping-api (:80) ─┤──► kship-golang-add-on (:8888 REST)
                    │              │
                    │              ├──► gRPC :8186  (user-service)
                    │              ├──► gRPC :8188  (registration-service)
                    │              └──► MySQL (module_coupon) + Redis
```

---

## 7. Merchant Portal

```
Client → shipping-merchant (:9898)
              │
              ├──► shipping-api (internal REST)
              ├──► KMA (open-kma external API)
              ├──► KTarget API
              ├──► Kafka consumer
              └──► MariaDB (kship_merchant) + MongoDB + Redis
```

---

## 8. Multi-Tenant Shard Routing

Áp dụng cho các Go services (shipping-merchant, shipping-report-v5, …).
Đơn vị tenant là **`retailer_id`**.

```
Request / Kafka Message
    │
    ▼
ITenantContextResolver
    │ extract retailer_id
    ▼
IShardingService
    │ retailer_id → shard_id
    ▼
Connection String: Shard_{shardId}
    │
    ▼
GORM DbContext (scoped per retailer)
```

**Databases:**
- `MasterDb` — shared reference data
- `Shard_{shardId}` — retailer data

**Rules:**
- EVERY query phải filter theo `retailer_id`
- Không share DbContext giữa các retailers
- Dùng `IShardingService` để resolve connection string
