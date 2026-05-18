# V4 Layer Patterns — Controller, Service, Transform, Request

---

## Request (Validate đầu vào)

Tạo trước tiên — sai input phải fail ngay, không chờ đến service.

```php
<?php
namespace App\Api\V4\Requests;

use App\Core\Base\BaseFormRequest;  // hoặc BaseApiRequest nếu có

class [Action][Domain]Request extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'code'        => 'required|string|max:50',
            'items'       => 'required|array|min:1',
            'items.*.sku' => 'required|string',
            'items.*.qty' => 'required|integer|min:1',
            'note'        => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'code.required'        => 'Mã đơn hàng không được để trống',
            'items.required'       => 'Danh sách sản phẩm không được để trống',
            'items.*.sku.required' => 'SKU sản phẩm không được để trống',
        ];
    }

    // Override để trả JSON + ghi log khi validation fail
    public function failedValidation(\Illuminate\Contracts\Validation\Validator $validator): void
    {
        \Log::warning('[V4][Action][Domain] Validation failed', [
            'errors' => $validator->errors()->toArray(),
            'input'  => $this->all(),
        ]);
        throw new \Illuminate\Validation\ValidationException($validator);
    }
}
```

**Validation rules thường dùng:**
```
required|string|max:255
required|integer|min:0
required|numeric
required|array|min:1
nullable|string
required|in:value1,value2,value3
required|date_format:Y-m-d
```

**Custom rules** (đặt trong `app/Api/V4/Rules/` hoặc `app/Rules/`):
```php
'phone' => ['required', new ShippingPhoneCustom],
'email' => ['nullable', new EmailsArray],
```

---

## Transform Input

Nhận raw request data → chuẩn hóa về internal format trước khi service xử lý.

```php
<?php
namespace App\Api\V4\Transform\[Domain];

use App\Core\Base\BaseTransform;

class [Action]InputTransform extends BaseTransform
{
    // $this->data    = input data (được set bởi BaseTransform)
    // $this->transformedData = output data (phải set trong transformData)

    protected function transformData(): void
    {
        $requestData = $this->data['request'] ?? [];
        $shopData    = $this->data['shop'] ?? [];

        $this->transformedData = [
            'shop_code'    => $shopData['code'] ?? null,
            'order_code'   => $requestData['code'] ?? null,
            'items'        => $this->transformItems($requestData['items'] ?? []),
            'total_weight' => $this->calcTotalWeight($requestData['items'] ?? []),
        ];
    }

    private function transformItems(array $rawItems): array
    {
        return array_map(fn($item) => [
            'sku'      => $item['sku'],
            'quantity' => (int) $item['qty'],
            'name'     => $item['name'] ?? '',
        ], $rawItems);
    }

    private function calcTotalWeight(array $items): float
    {
        return array_sum(array_column($items, 'weight'));
    }
}
```

**Cách gọi trong Service:**
```php
$transformed = [Action]InputTransform::getTransformedData([
    'request' => $requestData,
    'shop'    => $shopData,
]);
```

---

## Transform Output

Nhận kết quả từ business logic → format response về đúng cấu trúc API trả client.

```php
<?php
namespace App\Api\V4\Transform\[Domain];

use App\Core\Base\BaseTransform;

class [Action]OutputTransform extends BaseTransform
{
    protected function transformData(): void
    {
        $results = $this->data['results'] ?? [];
        $meta    = $this->data['meta'] ?? [];

        $this->transformedData = [
            'total'   => count($results),
            'items'   => array_map(fn($r) => $this->formatItem($r), $results),
            'summary' => [
                'total_fee' => $meta['total_fee'] ?? 0,
                'currency'  => 'VND',
            ],
        ];
    }

    private function formatItem(array $item): array
    {
        return [
            'service_id'   => $item['service_id'],
            'service_name' => $item['service_name'],
            'fee'          => (int) ($item['fee'] ?? 0),
            'estimated_at' => $item['estimated_delivery_date'] ?? null,
        ];
    }
}
```

---

## V4 Service

Orchestration layer: kết hợp Core domains, gọi external services, không biết về HTTP Request/Response.
Gọi Eloquent model trực tiếp hoặc qua Cache — không dùng Repository.

```php
<?php
namespace App\Api\V4\Services\[Domain];

use App\Core\[Domain]\[Domain];
use App\Core\[Domain]\Cache\[Domain]Cache;
use App\Core\Shops\Cache\ShopCache;
use App\Api\V4\Transform\[Domain]\[Action]InputTransform;
use App\Api\V4\Transform\[Domain]\[Action]OutputTransform;

class [Domain]Service
{
    // State caching trong request cycle — tránh query DB nhiều lần
    private $shop = null;

    // Không cần inject gì nếu chỉ dùng Eloquent + Cache static calls
    public function __construct() {}

    public function [action](array $requestData, string $clientCode): array
    {
        // 1. Lấy shop (với state caching)
        $shop = $this->getShop($requestData['retailer_id']);

        // 2. Transform input
        $input = [Action]InputTransform::getTransformedData([
            'request' => $requestData,
            'shop'    => $shop,
        ]);

        // 3. Business logic
        $results = $this->process($input, $clientCode);

        // 4. Transform output
        return [Action]OutputTransform::getTransformedData([
            'results' => $results,
            'meta'    => ['total_fee' => array_sum(array_column($results, 'fee'))],
        ]);
    }

    public function getShop(string $retailerId): array
    {
        // State cache trong request cycle — pattern từ CheckPriceService
        if ($this->shop !== null) {
            return $this->shop;
        }
        return $this->shop = ShopCache::getShopByRetailerId($retailerId) ?? [];
    }

    private function process(array $input, string $clientCode): array
    {
        // Business logic implementation
        return [];
    }
}
```

**DI binding cho V4 Service** (nếu dùng interface):
```php
// Hoặc bind trực tiếp class trong AppServiceProvider nếu không có interface
$this->app->bind([Domain]Service::class, [Domain]Service::class);
```

---

## Controller

Mỏng nhất có thể: validate → gọi service → trả response. Không chứa business logic.

```php
<?php
namespace App\Api\V4\Controllers;

use App\Http\Controllers\Controller;
use App\Api\V4\Requests\[Action][Domain]Request;
use App\Api\V4\Services\[Domain]\[Domain]Service;
use App\Api\V4\Traits\HandleException;
use App\Api\V4\Traits\Api;
use Illuminate\Http\Request;

class [Domain]Controller extends Controller
{
    use Api, HandleException;

    private $[domain]Service;

    public function __construct([Domain]Service $[domain]Service)
    {
        $this->[domain]Service = $[domain]Service;
    }

    public function [action]([Action][Domain]Request $request, string $clientCode)
    {
        try {
            $data = $this->[domain]Service->[action](
                $request->all(),
                $clientCode
            );

            return $this->responseSuccess($data);

        } catch (\App\Exceptions\KShipException $e) {
            return $this->handleKShipException($e);

        } catch (\Exception $e) {
            \Log::error('[V4][[Domain]][action] Unexpected error', [
                'message'     => $e->getMessage(),
                'client_code' => $clientCode,
                'request'     => $request->all(),
            ]);
            return $this->responseError($e->getMessage(), 500);
        }
    }
}
```

**Response helpers (từ Api trait):**
```php
$this->responseSuccess($data)              // HTTP 200
$this->responseError($message, $code)      // HTTP 4xx/5xx
$this->responseSuccess($data, $message)    // HTTP 200 với custom message
```

**Exception handling:**
```php
// KShipException — business rule violations (domain errors, external service errors)
throw new \App\Exceptions\KShipException('Shop không tồn tại', 404);

// handleKShipException() từ HandleException trait — tự log + format response
```

---

## Route Registration

```php
// routes/api.php
// Thêm vào group v4 đang có (tìm 'v4' trong file):

$api->group([
    'middleware' => ['widgetAuthKv'],
    'prefix'     => 'v4',
], function ($api) {
    // ...existing routes...

    // Thêm route mới:
    $api->post('[domain]/[action]',   '[Domain]Controller@[action]');
    $api->get('[domain]/{id}',        '[Domain]Controller@show');
    $api->put('[domain]/{id}',        '[Domain]Controller@update');
});
```

**Middleware thường dùng:**
- `widgetAuthKv` — auth cho widget/merchant API (V4 chuẩn)
- `jwt.auth` — JWT authentication
- `throttle:60,1` — rate limiting

---

## Checklist khi thêm feature V4

```
[ ] Request class: rules() + messages() + failedValidation()
[ ] InputTransform: transformData() với private helper methods
[ ] OutputTransform: format đúng cấu trúc client expect
[ ] Service: inject dependencies, state caching cho shop/client
[ ] Controller: thin, try-catch KShipException + generic Exception
[ ] Route: thêm vào group v4 đúng middleware
[ ] Core module (nếu domain mới):
    [ ] Model trong app/Core/[Domain]/
    [ ] Cache class với CONFIG_KEYS
    [ ] Core Service (nếu có logic CRUD dùng lại)
[ ] php artisan route:list | grep v4/[domain]
```
