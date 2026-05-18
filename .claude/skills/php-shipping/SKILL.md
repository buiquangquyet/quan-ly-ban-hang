---
name: php-shipping
description: >
  Hướng dẫn phát triển feature mới cho shipping-api (Laravel 5.6) theo đúng architecture V4.
  Dùng skill này khi làm việc trong submodule `src/shipping-api`: thêm API endpoint V4 mới,
  tạo Core module mới, mở rộng domain hiện có (Shop, BillLading, Client...), viết Request
  validation, Transform, Cache, hoặc Core Service. Kích hoạt bất cứ khi nào user
  đề cập đến shipping-api, Laravel shipping, thêm controller/service trong
  shipping-api, hoặc làm việc với bất kỳ file nào trong src/shipping-api.
---

# PHP Shipping API — Feature Development Guide

Đây là Laravel 5.6 backend với kiến trúc phân tầng rõ ràng. Luôn đọc reference files khi
cần chi tiết về từng layer.

## Kiến trúc tổng quan

```
HTTP Request
  → Routes (routes/api.php)
  → Middleware (widgetAuthKv, JWT, etc.)
  → V4 Controller (app/Api/V4/Controllers/)
      → V4 Request (validate input)
      → V4 Service
          → Transform Input (chuẩn hóa dữ liệu vào)
          → Core Model (Eloquent) / Cache (đọc/ghi DB)
          → Transform Output (format response)
  → Response (Dingo API wrapper)
```

**Quy tắc quan trọng nhất:**
- Model **luôn** đặt trong `app/Core/[Domain]/` — **không** dùng `app/Models/`
- V4 là version mới nhất; các version cũ (V1-V3) chỉ đọc để tham khảo, không sửa
- Mỗi dependency phải được inject qua constructor; không dùng facade trực tiếp trong service

---

## Quy trình thêm feature mới

### Bước 1 — Xác định scope

Trước khi viết code, trả lời:
1. Feature thuộc domain nào? (Shop, BillLading, Order, Client, v.v.)
2. Domain đó đã có Core module chưa? (`app/Core/[Domain]/`)
3. Cần endpoint mới hay chỉ mở rộng endpoint cũ?

### Bước 2 — Core module (nếu domain mới)

Tạo 3 thành phần. Xem chi tiết cấu trúc → `references/core-module.md`

```
app/Core/[Domain]/
├── [Domain].php                        # Eloquent model
├── Services/
│   └── [Domain]Service.php
└── Cache/
    └── [Domain]Cache.php
```

### Bước 3 — V4 Layer (Controller / Request / Service / Transform)

Thứ tự tạo file được khuyến nghị:

1. **Request** — validate input trước tiên (fail fast)
2. **Transform Input** — chuẩn hóa data vào internal format
3. **Service** — business logic chính
4. **Transform Output** — format response cho client
5. **Controller** — gọi service, bắt exception
6. **Route** — đăng ký endpoint

Xem pattern chi tiết từng layer → `references/v4-patterns.md`

### Bước 4 — Route

```php
// routes/api.php — trong group v4 với middleware widgetAuthKv
$api->post('v4/[resource]/[action]', '[Domain]Controller@[method]');
```

### Bước 5 — Kiểm tra

```bash
cd src/shipping-api
php artisan route:list | grep v4/[resource]   # Xác nhận route đăng ký đúng
php vendor/bin/phpunit tests/Unit/Api/V4/     # Chạy unit test V4
```

---

## Conventions nhanh

| Thứ | Convention |
|-----|------------|
| Namespace model | `App\Core\[Domain]\[Domain]` |
| Namespace V4 controller | `App\Api\V4\Controllers\[Domain]Controller` |
| Namespace V4 service | `App\Api\V4\Services\[Domain]\[Domain]Service` |
| Namespace transform | `App\Api\V4\Transform\[Domain]\[Action][Input/Output]Transform` |
| Exception | `throw new KShipException($message, $code)` |
| Response thành công | `$this->responseSuccess($data)` |
| Response lỗi | `$this->responseError($message, $code)` |
| Cache TTL mặc định | 1 ngày = `1 * 24 * 60` phút |
| DB connection | `protected $connection = 'mysql';` trong model |

---

## Reference files

- `references/core-module.md` — Model, Repository, Cache: cấu trúc đầy đủ với code mẫu
- `references/v4-patterns.md` — Controller, Service, Transform, Request: patterns V4 với ví dụ thực tế
