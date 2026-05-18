# Edge Case & Error Patterns by Domain

Dùng file này để identify missing edge/error cases trong PRD.
Match domain của PRD → check patterns tương ứng → flag cases bị thiếu.

---

## Universal Patterns (áp dụng mọi domain)

### Input/Validation
- Empty string, null, whitespace-only
- String quá dài (vượt max length)
- Special characters: `<script>`, SQL injection, unicode, emoji
- Numeric: 0, negative, max int, decimal precision
- Date: past date, future date, Feb 29, timezone mismatch
- File upload: empty file, quá lớn, wrong format, malicious content

### State & Lifecycle
- Entity ở wrong state cho action (vd: cancel đơn hàng đã delivered)
- Concurrent modification — 2 users edit cùng entity
- Stale data — user nhìn data cũ, submit action trên data đã thay đổi
- Re-entrant action — trigger cùng action 2 lần liên tiếp
- Orphaned data — parent deleted, children còn reference

### Authorization & Multi-tenancy
- User access entity của tenant khác
- Role escalation — user tự nâng quyền
- Expired session/token giữa multi-step flow
- Admin impersonation — hành động thay user khác

### External Dependencies
- API timeout, 5xx, rate limiting
- Network disconnection giữa chừng
- Third-party data format thay đổi
- Webhook delivery failure, duplicate delivery

### Performance & Scale
- First request (cold cache)
- List endpoint với 0 items vs 100K items
- Batch operation partial failure (3/10 items fail)
- Report generation với large dataset

---

## Domain-Specific Patterns

### E-Commerce / Order Management
- Đặt hàng sản phẩm hết tồn kho (race condition giữa check + order)
- Giá sản phẩm thay đổi sau khi thêm vào giỏ hàng
- Áp dụng 2 voucher cùng lúc, voucher hết hạn
- Đơn hàng COD: khách từ chối nhận, giao không thành công
- Partial refund: hoàn 1 phần items trong đơn
- Đơn hàng cross-branch: tồn kho branch A, giao branch B
- Shipping fee thay đổi khi sửa địa chỉ giao hàng

### Inventory / Warehouse
- Tồn kho âm (overselling)
- Transfer giữa 2 kho: gửi nhưng chưa nhận, lost in transit
- Kiểm kho: chênh lệch số lượng thực vs hệ thống
- Serial number/batch tracking: trùng serial, expired batch
- Unit conversion: bán lẻ vs bán sỉ (hộp vs thùng)

### Finance / Billing / Payment
- Thanh toán partial: trả 1 phần, còn nợ
- Currency rounding: 1/3 chia 3 phần
- Invoice đã xuất → cần sửa/huỷ (credit note)
- Payment gateway timeout: tiền trừ nhưng order chưa confirm
- Reconciliation mismatch: số tiền bank vs hệ thống
- Tax calculation: VAT inclusive vs exclusive, exempt items
- End-of-period closing: transaction đến sau closing

### User Management / Auth
- Đăng ký email đã tồn tại (khác tenant vs cùng tenant)
- Reset password: token expired, used twice
- Login từ device mới: 2FA, trust device
- Deactivate user có pending transactions
- Role change: user đang active session, quyền thay đổi realtime?
- SSO/OAuth: provider down, token revoked

### Reporting / Export
- Export file quá lớn (> 1M rows): memory, timeout
- Report filter trả về 0 results
- Timezone mismatch: report ngày hôm nay nhưng server UTC khác local
- Concurrent export: 2 users export cùng lúc
- Data aggregation rounding: tổng chi tiết != tổng summary
- Report data thay đổi giữa lúc generate

### Notification / Communication
- Email bounce, invalid address
- SMS to landline number
- Push notification: device unregistered
- Notification preferences: user opt-out nhưng system notification bắt buộc
- Duplicate notification khi retry
- Template variable missing/null

### Scheduling / Time-based
- Scheduled job chạy duplicate (server restart)
- Job overlap: job trước chưa xong, job sau bắt đầu
- Timezone change (DST): job chạy sai giờ
- Recurring event: cancel single instance vs entire series
- Deadline: action sau deadline, action ngay trước deadline

### API / Integration
- Idempotency: retry cùng request → cùng result
- Pagination: data thay đổi giữa pages
- Rate limiting: burst requests
- Versioning: client dùng API v1, server deploy v2
- Webhook ordering: event B đến trước event A
- Bulk API: partial success (200 items, 3 fail)

---

## How to Use

1. Xác định PRD thuộc domain nào (có thể multi-domain)
2. Cho mỗi UC trong PRD, scan Universal Patterns + Domain-Specific Patterns
3. Mỗi pattern KHÔNG có trong PRD (không trong Error Cases, không trong BRs, không trong ACs) → flag:
   - Pattern critical cho business → `[BLOCKING]`
   - Pattern nên có → `[SUGGESTION]`
   - Pattern nice-to-have → `[NIT]`
4. Group findings: "Missing edge/error cases for UC-{nn}: {list}"
