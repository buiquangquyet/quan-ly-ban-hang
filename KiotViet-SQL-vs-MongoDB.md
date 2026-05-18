# SQL vs MONGODB — PHÂN TÍCH CHO TỪNG MODULE

**Câu hỏi:** Có phần nào của hệ thống quản lý bán hàng có thể (nên) dùng MongoDB thay cho SQL không?

**Trả lời ngắn:** Có một số phần phù hợp, nhưng **CORE (giao dịch tài chính, tồn kho, thẻ kho) PHẢI ở SQL**. Mongo phù hợp cho data **schema linh hoạt + write-heavy + read-recent**.

---

## 1. NGUYÊN TẮC CHỌN STORAGE

### Khi nào DÙNG SQL (Postgres/MySQL)
- ✅ **ACID transactions** bắt buộc (vd: bán hàng → giảm tồn → ghi sổ — all-or-nothing)
- ✅ **Financial accuracy** — DECIMAL chính xác, không float
- ✅ **Relational integrity** mạnh (FK giữa product, invoice, customer)
- ✅ **Complex aggregations** (báo cáo, phân tích, JOIN nhiều bảng)
- ✅ **Strong consistency** — không tolerate eventual

### Khi nào DÙNG MongoDB
- ✅ **Schema linh hoạt** — mỗi document có cấu trúc khác nhau (vd messages từ nhiều platform)
- ✅ **Write-heavy + read-recent** — log, event, notification
- ✅ **Dữ liệu nested phức tạp** — embed thay vì JOIN
- ✅ **TTL** built-in — auto xóa dữ liệu cũ
- ✅ **Geospatial** — tìm shipper gần nhất
- ✅ **Full-text search** ở mức cơ bản
- ✅ **Horizontal scale** dễ dàng (sharding native)

### Khi nào CHỌN STORAGE KHÁC
- 🔵 **Redis** — cache, session, rate limit, queue ngắn
- 🟡 **Elasticsearch / Meilisearch** — search nâng cao (product search 5,510 SP)
- 🟢 **TimescaleDB / InfluxDB** — time-series metrics
- 🟣 **S3 / MinIO** — object storage (ảnh, file HĐĐT XML, video livestream)
- 🟠 **Kafka / Redis Streams** — event log/stream
- ⚫ **ClickHouse / BigQuery** — analytics OLAP

---

## 2. PHÂN TÍCH 12 MODULE

### A. Tenancy & Access → 100% SQL
**Bảng:** merchant, user, role, permission

- Strong consistency cho auth/permission
- JOIN nhiều với mọi bảng khác
- **Verdict:** ❌ KHÔNG dùng Mongo. Postgres + RLS.

### B. Org Structure → 100% SQL
**Bảng:** branch, pickup_address

- Reference master, ít thay đổi
- **Verdict:** ❌ Postgres.

### C. Product Catalog → CHỦ YẾU SQL + HYBRID
**Bảng SQL core (giữ):**
- `product` (id, code, giá, status, tax, flags)
- `product_unit` (đơn vị tính + giá theo đơn vị)
- `category`, `brand`, `supplier`
- `product_supplier` junction

**Có thể chuyển sang Mongo (hoặc JSONB):**
- 🟢 **Mô tả sản phẩm dài** (HTML/rich text, nested specs, multi-language)
- 🟢 **Reviews, ratings** (mảng nested với reply, photo)
- 🟢 **Attribute schema động** (mỗi nhóm hàng có thuộc tính khác nhau — vd điện thoại có "RAM, ROM, OS"; quần áo có "Size, Màu")
- 🟢 **External marketplace mapping & sync metadata** (Shopee/TikTok response raw)

**Đề xuất hybrid:**
```
postgres.product (core fields, indexed)
   ↓ product_id ref
mongo.product_extended {
  _id: ObjectId,
  product_id: 12345,
  description_html: "...",
  specifications: { ram: "8GB", os: "iOS 18", camera: { ... } },
  reviews: [ { user, rating, photos, ... } ],
  marketplace_sync: {
    shopee: { item_id, last_sync, raw_response },
    tiktok: { ... },
    lazada: { ... }
  }
}
```

**Lý do:** Truy vấn báo cáo & bán hàng dùng `postgres.product` (nhanh, ACID). Khi cần render product page hoặc sync marketplace mới load `mongo.product_extended`.

**Verdict:** ⚖️ HYBRID — core SQL, extended Mongo

### D. Inventory → 100% SQL (BẮT BUỘC)
**Bảng:** stock, stock_norm, batch, batch_stock, stock_unit, **stock_card_line**

- ⚠️ **stock_card_line** là general ledger — KHÔNG được mất 1 dòng
- ⚠️ **Race condition** khi 2 cashier bán cùng SP → cần SQL ROW LOCK
- ⚠️ **Running balance** cần serial consistency
- ⚠️ FEFO query trên `batch.expire_date` cần ORDER BY chính xác

**Anti-pattern:** Dùng Mongo cho stock_card_line → eventual consistency có thể làm tồn âm bất hợp lý, race condition khi 2 cashier cùng bán cuối cùng 1 chiếc iPhone serial X.

**Verdict:** ❌ TUYỆT ĐỐI KHÔNG Mongo. Postgres với strict transaction isolation.

### E. Pricing → SQL
**Bảng:** price_book, price_book_item, tax_rate

- Đọc nhiều, ghi ít → có thể cache Redis trên SQL
- Cần JOIN với product khi tính giá
- **Verdict:** ❌ Postgres + Redis cache

### F. Partners (Customer) → CHỦ YẾU SQL + HYBRID CHO CDP
**SQL core:**
- `customer` (id, code, phone, email, tier, current_debt, loyalty_points)
- `customer_address`

**Có thể Mongo:**
- 🟢 **Customer 360 / CDP profile** — behavior history, preference, predicted segments
- 🟢 **Activity timeline** (xem trang gì, click ads nào, click email gì)

```
mongo.customer_profile {
  _id: ObjectId,
  customer_id: 67890,
  segments: ["VIP_BAC", "SAP_CHURN", "MUA_BUOI_TOI"],
  behavior: {
    favorite_categories: ["Sữa", "Bánh"],
    avg_basket_size: 245000,
    visit_frequency_per_week: 1.2,
    last_visited_branch_id: 3,
    preferred_channel: "TIKTOK_SHOP"
  },
  predictions: {
    churn_score: 0.78,
    ltv: 4500000,
    next_purchase_date: "2026-06-15"
  },
  activity_timeline: [ ... 500 events ... ]
}
```

**Lý do tách:** Customer core ổn định, ACID khi giao dịch. Profile thay đổi liên tục theo behavior, không cần ACID, schema linh hoạt theo ML model phát triển.

**Verdict:** ⚖️ HYBRID — core SQL, CDP profile Mongo

### G. Sales Transactions → 100% SQL (BẮT BUỘC)
**Bảng:** invoice, invoice_line, payment, return_invoice, e_invoice...

- Tài chính — không sai một xu
- HĐĐT cần immutability + chữ ký số
- Báo cáo doanh thu cần JOIN customer/product/channel/branch
- Quy định kế toán + thuế bắt buộc audit trail strict

**Verdict:** ❌ TUYỆT ĐỐI KHÔNG Mongo. Postgres với REPEATABLE READ / SERIALIZABLE isolation.

**Ngoại lệ phụ:**
- 🟢 `e_invoice.xml_signed` (XML đã ký) có thể lưu **S3** (object storage), DB chỉ giữ URL

### H. Inventory Transactions → 100% SQL
**Bảng:** purchase_order, transfer, take, mfg, internal_use, write_off + stock_card_line

- Cùng lý do với G: tài chính + tồn kho
- **Verdict:** ❌ Postgres

### I. Delivery → CHỦ YẾU SQL + HYBRID CHO TRACKING
**SQL core:**
- `shipment` (id, invoice_id, status, fee, COD, tracking_code)
- `delivery_partner`, `delivery_service`

**Có thể Mongo:**
- 🟢 **Tracking events log** (đơn đi đâu, ai handoff, GPS điểm)

```
mongo.shipment_tracking {
  _id: ObjectId,
  shipment_id: 99887,
  tracking_code: "VTP123456789",
  events: [
    { at: ISODate, status: "PICKED_UP", location: { lat, lng }, hub: "HN-01", note: "Bưu tá Nam đã lấy" },
    { at: ISODate, status: "IN_TRANSIT", hub: "HN-02" },
    { at: ISODate, status: "OUT_FOR_DELIVERY", driver_phone: "..." },
    { at: ISODate, status: "DELIVERED", signature_image_url: "s3://..." }
  ],
  geospatial_index: { type: "Point", coordinates: [lng, lat] }
}
```

**Lý do tách:** Mỗi hãng vận chuyển gửi event với schema khác nhau (Viettel Post khác GHN khác GHTK). Volume rất lớn (mỗi đơn 5-10 events). Mongo's geospatial native phù hợp.

**Verdict:** ⚖️ HYBRID — core SQL, events Mongo

### J. Promotion & Loyalty → CHỦ YẾU SQL + HYBRID
**SQL core:**
- `promotion` (rule, condition, validity)
- `voucher` (instance đã phát hành)
- `coupon` (code dùng chung)
- `loyalty_points` (sổ điểm — bút toán)

**Có thể Mongo:**
- 🟢 **Campaign delivery logs** (gửi SMS/Zalo/Push nào tới ai, mở/click/convert)

```
mongo.campaign_message {
  _id: ObjectId,
  campaign_id: 5,
  customer_id: 67890,
  channel: "ZALO_OA",
  template_id: "TET_PROMO_2026",
  sent_at: ISODate,
  delivered_at: ISODate,
  opened_at: ISODate,
  clicked_at: ISODate,
  converted_invoice_id: 12345,
  raw_response: { ... provider-specific ... }
}
```

**Verdict:** ⚖️ HYBRID — core SQL, message logs Mongo

### K. Administrative → SQL
**Bảng:** province, ward — master hành chính

- Reference data fixed, ít update
- **Verdict:** ❌ Postgres

### L. Operations (Shift) → SQL
- Tài chính (tiền mặt đầu/cuối ca)
- **Verdict:** ❌ Postgres

---

## 3. CÁC MODULE MỚI (TRONG BRAINSTORM) — ĐÁNH GIÁ MONGO FIT

### M1. Chat đa kênh (Unified Inbox) → ⭐ RẤT PHÙ HỢP MONGO

```
mongo.conversation {
  _id: ObjectId,
  merchant_id: 1,
  customer_identity: {
    primary_phone: "0901234567",
    facebook_id: "...",
    zalo_id: "...",
    tiktok_user: "...",
    matched_customer_id: 67890  // link tới SQL.customer
  },
  channels: ["FACEBOOK", "ZALO_OA", "SHOPEE_CHAT", "TIKTOK_DM"],
  last_message_at: ISODate,
  unread_count: 3,
  assigned_to_user_id: 12,
  tags: ["HOT_LEAD", "VIP"],
  messages: [
    {
      _id: ObjectId,
      channel: "FACEBOOK",
      direction: "INBOUND",
      content_type: "TEXT|IMAGE|VIDEO|STICKER",
      text: "...",
      media_urls: [...],
      sent_at: ISODate,
      read_at: ISODate,
      raw_payload: { ... platform-specific ... }
    },
    ...
  ]
}
```

**Lý do Mongo phù hợp:**
- Schema mỗi platform khác — Facebook khác Zalo khác Shopee
- Volume cực lớn (1 shop 1000 tin/ngày)
- Append-heavy, read recent
- Embed messages trong conversation tránh JOIN N+1
- Full-text search built-in (`$text` index)

**Verdict:** ✅ MongoDB là lựa chọn tốt nhất

### M2. Notification feed → ⭐ PHÙ HỢP MONGO

```
mongo.notification {
  _id: ObjectId,
  merchant_id: 1,
  recipient_user_id: 5,
  type: "ORDER_NEW|STOCK_LOW|SHIFT_END|...",
  title: "...",
  body: "...",
  data: { ... event-specific ... },
  read: false,
  created_at: ISODate,
  expire_at: ISODate  // TTL index
}
```

**Lý do:**
- High write volume
- TTL index built-in tự xóa cũ
- Read by recipient × time DESC

**Verdict:** ✅ MongoDB

### M3. Activity log / Audit non-financial → ⭐ PHÙ HỢP MONGO

```
mongo.activity_log {
  _id: ObjectId,
  merchant_id: 1,
  user_id: 12,
  action: "LOGIN|LOGOUT|PRODUCT_EDIT|PRICE_CHANGE|SETTING_TOGGLE",
  entity_type: "PRODUCT",
  entity_id: 444,
  changes: { before: {...}, after: {...} },
  ip_address: "...",
  user_agent: "...",
  at: ISODate
}
```

**Lưu ý:** Đây là **audit hành vi user**, KHÁC với `stock_card_line` (audit kế toán). Audit kế toán PHẢI ở SQL. Audit hành vi có thể Mongo.

**Verdict:** ✅ MongoDB cho audit hành vi (security log)

### M4. AI Demand Forecasting features → ⭐ PHÙ HỢP MONGO

```
mongo.product_features {
  _id: ObjectId,
  product_id: 12345,
  branch_id: 3,
  computed_at: ISODate,
  features: {
    velocity_7d: 5.2,
    velocity_30d: 4.8,
    seasonality_index: { jan: 0.8, feb: 1.2, ... },
    elasticity: -1.5,
    cross_sell: [ { product_id: 67890, lift: 2.3 }, ... ],
    forecast_next_7d: 38,
    forecast_confidence: 0.82
  }
}
```

**Verdict:** ✅ MongoDB (hoặc feature store như Feast)

### M5. Livestream session data → ⭐ PHÙ HỢP MONGO

```
mongo.livestream_session {
  _id: ObjectId,
  merchant_id: 1,
  channel: "TIKTOK_LIVE",
  started_at, ended_at,
  host_user_id: 12,
  products_promoted: [ ... 50 SPs với timestamp xuất hiện ... ],
  viewer_stats: [ { at, count } ... 1000 datapoints ],
  chat_messages: [ ... thousands ... ],
  orders_during: [invoice_id, ...],
  replay_url: "s3://..."
}
```

**Verdict:** ✅ MongoDB

### M6. Marketplace sync raw payloads → ⭐ PHÙ HỢP MONGO

```
mongo.marketplace_event {
  _id: ObjectId,
  source: "SHOPEE|TIKTOK|LAZADA",
  event_type: "ORDER_CREATED|ITEM_UPDATED|...",
  external_id: "...",
  raw_payload: { ... whole API response ... },
  processed: false,
  processed_at: ISODate,
  related_local_id: 12345
}
```

**Lý do:** API response từ marketplace thay đổi version, schema biến hóa, lưu raw để re-process khi cần.

**Verdict:** ✅ MongoDB (hoặc data lake S3)

---

## 4. STORAGE SUMMARY TABLE

| Module | Storage chính | Storage phụ |
|---|---|---|
| Tenancy & Access | Postgres | Redis (session) |
| Org Structure | Postgres | — |
| **Product Catalog** | Postgres (core) | **Mongo (description, specs, marketplace mapping)** + Elasticsearch (search) + S3 (images) |
| **Inventory** ⭐ | **Postgres (strict)** | Redis (stock cache TTL 30s) |
| Pricing | Postgres | Redis (price_book cache) |
| **Customer** | Postgres (core) | **Mongo (CDP profile, behavior timeline)** |
| Sales Transactions ⭐ | **Postgres (strict)** | S3 (e-invoice XML) |
| Inventory Transactions ⭐ | **Postgres (strict)** | — |
| **Delivery** | Postgres (core) | **Mongo (tracking events, geospatial)** |
| Promotion & Loyalty | Postgres (core) | **Mongo (campaign message logs)** |
| Administrative | Postgres | — |
| Operations (Shift) | Postgres | — |
| **Chat đa kênh** | **MongoDB** | Postgres (customer link) |
| **Notification** | **MongoDB** (TTL) | — |
| **Activity / Audit hành vi** | **MongoDB** | — |
| **AI Features** | **MongoDB** | TimescaleDB (training data) |
| **Livestream data** | **MongoDB** | S3 (replay video) |
| **Marketplace sync** | **MongoDB** | Kafka (event stream) |

---

## 5. KIẾN TRÚC HYBRID ĐỀ XUẤT

```
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │   POSTGRES (Primary) │    │   MONGODB (Secondary)    │  │
│  │                      │    │                          │  │
│  │ • Merchant, User     │    │ • Chat conversations     │  │
│  │ • Product (core)     │    │ • Product extended       │  │
│  │ • Customer (core)    │    │ • Customer CDP profile   │  │
│  │ • Invoice + Lines    │    │ • Shipment tracking      │  │
│  │ • Payment            │    │ • Notification feed      │  │
│  │ • Stock + Stock card │ ↔  │ • Activity log (UX)      │  │
│  │ • Batch + Serial     │    │ • Campaign messages      │  │
│  │ • All Inv vouchers   │    │ • AI features            │  │
│  │ • Promotion (rules)  │    │ • Livestream session     │  │
│  │ • Loyalty ledger     │    │ • Marketplace sync raw   │  │
│  │                      │    │                          │  │
│  │   ACID, JOIN heavy   │    │   Schema flexible        │  │
│  │   Master of truth    │    │   High write throughput  │  │
│  └──────────────────────┘    └──────────────────────────┘  │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │   REDIS              │    │   S3 / MinIO             │  │
│  │ • Session            │    │ • Product images         │  │
│  │ • Cache (stock,      │    │ • E-invoice XML signed   │  │
│  │   price_book)        │    │ • Livestream replay      │  │
│  │ • Rate limit         │    │ • Receipt prints PDF     │  │
│  │ • Pub/Sub realtime   │    │ • Upload imports         │  │
│  └──────────────────────┘    └──────────────────────────┘  │
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │   ELASTICSEARCH      │    │   KAFKA / REDIS STREAM   │  │
│  │ • Product search     │    │ • Event bus              │  │
│  │ • Customer search    │    │ • Audit stream           │  │
│  │ • Invoice/Order      │    │ • Marketplace sync queue │  │
│  │   filter complex     │    │ • Notification dispatch  │  │
│  └──────────────────────┘    └──────────────────────────┘  │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │  TIMESCALEDB         │                                  │
│  │ • Metrics realtime   │                                  │
│  │ • POS heartbeat      │                                  │
│  │ • Stock movement     │                                  │
│  │   time-series        │                                  │
│  └──────────────────────┘                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. SYNC PATTERNS GIỮA POSTGRES ↔ MONGO

### Pattern 1: One-way push qua event bus (recommended)
```
Postgres COMMIT (vd: invoice created)
    ↓
Outbox table → Kafka
    ↓
Mongo consumer cập nhật:
  - customer_profile.last_purchase
  - product_extended.popularity_score
  - shipment_tracking.events
```

### Pattern 2: CDC (Change Data Capture)
- Dùng **Debezium** đọc Postgres WAL → Kafka → Mongo
- Real-time, không cần code application
- Phù hợp khi cần mirror dữ liệu master cho ML

### Pattern 3: Direct dual-write (TRÁNH)
- App ghi cả 2 cùng lúc — dễ inconsistency khi 1 bên fail
- **Anti-pattern**

---

## 7. WHEN MONGO SHINES SPECIFICALLY HERE

Trong context KiotViet/POS, **3 use case Mongo thắng rõ rệt nhất:**

### 7.1. Chat đa kênh — "killer use case" cho Mongo
- Message từ 4+ kênh schema khác nhau
- Volume: 1 shop ~ 500-2000 messages/ngày
- Query: lấy 50 messages mới nhất theo conversation
- Embed messages trong conversation → 1 query là xong
- Tránh JOIN N+1 nếu dùng SQL

### 7.2. Marketplace sync raw payloads
- Shopee API payload có thể 50+ field, đôi khi nested 4 level
- Lưu raw để re-process khi parser thay đổi
- TTL 90 ngày → auto cleanup

### 7.3. Notification + Activity feed
- Write-heavy, read-recent
- TTL built-in → không cần cron cleanup
- Schema mỗi notification type khác (push, in-app, email)

---

## 8. WHEN POSTGRES PHẢI THẮNG (NON-NEGOTIABLE)

- ⚠️ **invoice + payment** — chuyện tiền không sai 1 đồng
- ⚠️ **stock_card_line + stock** — chuyện tồn kho không sai 1 cái
- ⚠️ **e_invoice** — chuyện thuế không chấp nhận eventual consistency
- ⚠️ **shift cash count** — chuyện kết ca không sai

Tất cả phải ACID, strict transaction isolation, double-entry bookkeeping principles.

**Nếu CTO nào đề xuất chuyển stock_card_line sang Mongo → veto ngay.** Đó là general ledger — sai dòng nào là lệch sổ kế toán, lệch thuế, lệch dòng tiền.

---

## 9. KHUYẾN NGHỊ CUỐI

**Giai đoạn 1 (MVP, < 1000 merchants):** 100% Postgres + Redis cache + S3 ảnh. Đủ. Đừng over-engineer.

**Giai đoạn 2 (1000-10,000 merchants):** Thêm Mongo cho **Chat đa kênh** (lúc này feature mới quan trọng) + Elasticsearch cho search.

**Giai đoạn 3 (10,000+):** Mở rộng Mongo cho CDP, tracking events, AI features. Postgres scale-out qua read replicas + partition.

**Giai đoạn 4 (50,000+ enterprise):** Kafka backbone, CDC sync, sharded Mongo, TimescaleDB cho metrics realtime.

**Anti-pattern phổ biến cần tránh:**
- ❌ Dùng Mongo cho "everything" — sẽ trả giá khi cần báo cáo cross-data
- ❌ Dùng SQL cho "everything" kể cả messages — sẽ trả giá khi scale chat
- ❌ Dual-write Postgres + Mongo trong cùng app — race condition
- ❌ Lưu file binary (ảnh, video) trong DB — luôn dùng S3

**Vàng:** Postgres làm "source of truth" cho mọi thứ liên quan tiền/tồn. Mongo làm "secondary store" cho mọi thứ schema-flexible. Sync 1 chiều qua event bus.
