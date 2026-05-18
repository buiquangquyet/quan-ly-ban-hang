# Core Module — Model, Service, Cache

Mọi domain logic đều sống trong `app/Core/[Domain]/`. Đây là nơi đặt model, không phải `app/Models/`.

```
app/Core/[Domain]/
├── [Domain].php          # Eloquent model
├── Services/
│   └── [Domain]Service.php
└── Cache/
    └── [Domain]Cache.php
```

---

## Model

```php
<?php
namespace App\Core\[Domain];

use Illuminate\Database\Eloquent\Model;

class [Domain] extends Model
{
    protected $table = '[table_name]';
    protected $connection = 'mysql';  // luôn khai báo rõ connection

    protected $fillable = [
        'field_one',
        'field_two',
        // ...
    ];

    // Relationships
    public function shop(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(\App\Core\Shops\Shop::class);
    }
}
```

**Lưu ý model:**
- Đặt `protected $connection` dù dùng connection mặc định — tránh nhầm lẫn khi thêm DB sau
- Không đặt business logic phức tạp vào model; logic đó thuộc về Service
- Relationships trả về kiểu Eloquent relation, không trả về Collection trực tiếp

---

## Cache

```php
<?php
namespace App\Core\[Domain]\Cache;

use App\Core\Base\BaseCache;
use App\Core\[Domain]\[Domain];

class [Domain]Cache extends BaseCache
{
    // Định nghĩa key constants — dùng snake_case, prefix rõ ràng
    const CACHE_BY_CODE = 'cache_[domain]_by_code';
    const CACHE_BY_ID   = 'cache_[domain]_by_id';

    // CONFIG_KEYS định nghĩa TTL và method lấy data khi cache miss
    const CONFIG_KEYS = [
        self::CACHE_BY_CODE => [
            'life_time' => 1 * 24 * 60,   // phút; 1 ngày là mặc định cho master data
            'method'    => 'getDataByCode',
        ],
        self::CACHE_BY_ID => [
            'life_time' => 1 * 24 * 60,
            'method'    => 'getDataById',
        ],
    ];

    // Static facade — Service gọi trực tiếp không cần khởi tạo
    public static function getByCode(string $code)
    {
        return (new static())->getCache(self::CACHE_BY_CODE, $code);
    }

    public static function getById(int $id)
    {
        return (new static())->getCache(self::CACHE_BY_ID, $id);
    }

    // Private methods — BaseCache gọi khi cache miss
    private function getDataByCode(string $code): ?array
    {
        $record = [Domain]::where('code', $code)->first();
        return $record ? $record->toArray() : null;
    }

    private function getDataById(int $id): ?array
    {
        $record = [Domain]::find($id);
        return $record ? $record->toArray() : null;
    }
}
```

**Cách dùng trong Service:**
```php
// Đọc từ cache (tự động fallback DB khi cache miss)
$data = [Domain]Cache::getByCode($code);
```

**TTL guidelines:**
- Master data (shop, service, location): `1 * 24 * 60` (1 ngày)
- Transactional data (order, transaction): không cache hoặc TTL ngắn (5-15 phút)
- Config data: `7 * 24 * 60` (1 tuần)

---

## Service

Service gọi Eloquent model trực tiếp — không qua repository.

```php
<?php
namespace App\Core\[Domain]\Services;

use App\Core\[Domain]\[Domain];
use App\Core\[Domain]\Cache\[Domain]Cache;

class [Domain]Service
{
    public function create(array $data): [Domain]
    {
        return [Domain]::create($data);
    }

    public function update(int $id, array $data): bool
    {
        return (bool) [Domain]::where('id', $id)->update($data);
    }

    public function findByCode(string $code): ?array
    {
        $record = [Domain]::where('code', $code)->first();
        return $record?->toArray();
    }

    public function findById(int $id): ?array
    {
        // Dùng cache cho master data
        return [Domain]Cache::getById($id);
    }

    public function delete(int $id): bool
    {
        return (bool) [Domain]::destroy($id);
    }
}
```

**Query patterns thường dùng:**
```php
// Lấy một record
[Domain]::find($id)
[Domain]::where('code', $code)->first()
[Domain]::where('status', 1)->where('shop_id', $shopId)->first()

// Lấy nhiều records
[Domain]::where('shop_id', $shopId)->get()
[Domain]::whereIn('id', $ids)->get()
[Domain]::where('status', 1)->orderBy('created_at', 'desc')->paginate(20)

// Tạo / cập nhật
[Domain]::create($data)
[Domain]::where('id', $id)->update($data)
[Domain]::updateOrCreate(['code' => $code], $data)

// Xóa
[Domain]::destroy($id)
[Domain]::where('shop_id', $shopId)->delete()

// Với relationships
[Domain]::with('shop')->find($id)
```

**Phân biệt Core Service vs V4 Service:**
- **Core Service** (`app/Core/[Domain]/Services/`): CRUD thuần, gần DB, không biết về HTTP
- **V4 Service** (`app/Api/V4/Services/`): Orchestration, kết hợp nhiều Core domain, biết về HTTP context
