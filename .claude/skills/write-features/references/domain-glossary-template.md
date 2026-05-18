# Domain Glossary Template

> Template thuật ngữ domain cho step language nhất quán. Mỗi dự án customize file này.

---

## Cách dùng

1. **Chuẩn hóa ngôn ngữ** — chọn 1 term cho mỗi concept, dùng everywhere → step definitions tái sử dụng
2. **Định nghĩa personas** — dùng role rõ ràng giúp scenarios dễ đọc và step defs composable

---

## Domain Terms Template

### [Tên domain 1] — VD: Thanh toán / Hóa đơn

| Concept | Dùng term này | Tránh dùng |
|---------|--------------|-----------|
| [khái niệm] | [term ưu tiên] | [các term khác không dùng] |

### [Tên domain 2] — VD: Xác thực / Phân quyền

| Concept | Dùng term này | Tránh dùng |
|---------|--------------|-----------|
| [khái niệm] | [term ưu tiên] | [các term khác không dùng] |

---

## Persona Library

Personas mặc định cho SaaS B2B context. Dùng **role rõ ràng** thay vì tên cá nhân — step definitions tái sử dụng được và không gây nhầm lẫn với dữ liệu thật.

| Persona (role) | Gói / Quyền | Dùng cho |
|----------------|-------------|---------|
| Chủ cửa hàng | Gói trả phí active | Happy path — luồng chính |
| Chủ cửa hàng (hết hạn) | Gói miễn phí / hết hạn | Lỗi permission, upgrade prompt |
| Nhân viên kế toán | Quyền standard | Luồng accounting, báo cáo |
| Đại lý / đối tác | Quyền hạn chế | Integration, third-party flows |
| Admin | Full access | Multi-tenant, admin config |
| Internal service | JWT token hợp lệ | API-to-API calls, system integrations |

> **Quy tắc**: Dùng role (Admin, Chủ cửa hàng, Nhân viên, Internal service) — KHÔNG dùng tên cá nhân (Minh, Lan, Hùng...) để tránh nhầm với dữ liệu test thật và đảm bảo step defs reusable.

---

## Step Phrase Library

Các pattern step tái sử dụng. Customize theo domain.

### Xác thực / Phân quyền
```gherkin
Given Chủ cửa hàng đã đăng nhập với vai trò [role]
Given Nhân viên không có quyền truy cập [feature]
Given Chủ cửa hàng có gói [tên gói] đang active
Given gói dịch vụ của Chủ cửa hàng đã hết hạn
Given Internal service truyền token JWT hợp lệ
Given Admin đăng nhập với quyền full access
```

### Thiết lập dữ liệu
```gherkin
Given Chủ cửa hàng có [N] [items] trong [khu vực hệ thống]
Given [record] #[ID] đang ở trạng thái [status]
Given kỳ [period/context] cho [timeframe] đang mở
```

### Hành động nghiệp vụ
```gherkin
When Chủ cửa hàng [action verb] [object] cho [recipient/context]
When Nhân viên gửi [form/document] đến [destination]
When [hệ thống ngoài] xử lý [object]
When [timeout/scheduled event] xảy ra
```

### Kết quả observable
```gherkin
Then trạng thái [object] chuyển sang "[status]"
Then Chủ cửa hàng thấy [message/screen/result]
Then Nhân viên nhận thông báo "[nội dung]"
Then [object] xuất hiện trong [danh sách/view] của Chủ cửa hàng
```
