# API Step Definition Patterns

> Reference cho test-engineer agent khi generate API test step definitions từ Cucumber feature files.
> Stack: TypeScript + CucumberJS + axios.

---

## Project Structure

```
src/
├── api_clients/                # Typed HTTP clients
│   ├── base_api_client.ts      # Base class: auth, headers, axios setup
│   └── {domain}_api_client.ts  # Per-domain clients (ProductApiClient, OrderApiClient)
├── step_definitions/
│   └── api/                    # API step definitions
│       └── {feature}_api_steps.ts
├── models/
│   └── api/                    # TypeScript request/response interfaces
│       └── {domain}.ts
└── support/
    ├── world.ts                # CustomWorld — apiResponse, authToken, savedValues
    ├── helpers/
    │   └── api_helpers.ts      # getNestedValue, buildRequestBody
    └── fixture/
        └── api_data.ts         # API test data, credentials per role
```

---

## BaseApiClient Pattern

Mọi domain client extend `BaseApiClient`:

- `validateStatus: () => true` — KHÔNG throw on non-2xx, trả status trong `ApiResponse`
- `ApiResponse<T>` chứa: `status`, `data`, `headers`, `ok` (2xx shorthand), `error?`
- Auth token inject qua `setAuthToken()`, tự build Authorization header
- Convenience methods: `get<T>`, `post<T>`, `put<T>`, `patch<T>`, `delete<T>`

### Domain Client Conventions

- **Class**: `PascalCase` + `ApiClient` suffix → `ProductApiClient`
- **File**: `snake_case` + `_api_client.ts` → `product_api_client.ts`
- **Methods**: verb + resource → `getProduct`, `createOrder`, `updateInventory`
- **Types**: `{Domain}Request`, `{Domain}Response` → `CreateProductRequest`, `ProductResponse`
- **basePath**: constant per client → `/api/v1/products`

---

## World Context (API additions)

```typescript
// Thêm vào CustomWorld cho API test state
authToken?: string;
apiResponse?: ApiResponse<unknown>;
lastRequestBody?: unknown;
lastEndpoint?: string;
savedValues?: Record<string, unknown>;  // cho chained scenarios

// Dynamic client registry
getApiClient<T extends BaseApiClient>(ClientClass: new () => T): T
refreshAllClientTokens(): void  // re-inject token vào tất cả active clients
```

---

## Step Pattern Catalog

### Authentication Steps

| Gherkin step | Implementation |
|---|---|
| `I am authenticated as {string}` | Login via authApiClient → store `this.authToken` → `refreshAllClientTokens()` |
| `I am not authenticated` | Clear `this.authToken` → `refreshAllClientTokens()` |

### Generic HTTP Request Steps

| Gherkin step | Implementation |
|---|---|
| `I send a {string} request to {string}` | `client.request(method, endpoint)` → store `this.apiResponse` |
| `I send a {string} request to {string} with body:` | Parse docString JSON → `client.request(method, endpoint, { body })` |
| `I send a {string} request to {string} with data:` | `dataTable.rowsHash()` → `client.request(method, endpoint, { body })` |

### Domain-Specific Request Steps (generated per feature)

| Pattern | Example |
|---|---|
| `I create a {resource} with:` | `client.createProduct(buildRequestBody(dataTable))` |
| `I get the {resource} with id {string}` | `client.getProductById(id)` |
| `I update {resource} {string} with:` | `client.updateProduct(id, updateData)` |
| `I delete the {resource} with id {string}` | `client.deleteProduct(id)` |
| `I search {resources} with keyword {string}` | `client.getProducts({ keyword })` |

### Response Assertion Steps

| Gherkin step | Assertion |
|---|---|
| `the response status should be {int}` | `expect(apiResponse.status).toBe(status)` |
| `the request should succeed` | `expect(apiResponse.ok).toBe(true)` |
| `the request should fail` | `expect(apiResponse.ok).toBe(false)` |
| `the response field {string} should be {string}` | `getNestedValue(data, fieldPath)` — supports dot notation |
| `the response should contain fields:` | DataTable rowsHash → iterate field assertions |
| `the response body should not be empty` | `expect(data).toBeDefined()` |
| `the response list should have {int} items` | Check `data.items ?? data.data ?? data` length |
| `the error message should contain {string}` | `expect(data.message ?? data.error).toContain(text)` |
| `the response should contain validation errors for {string}` | `expect(data.errors[field]).toBeDefined()` |

### Stored Value Steps (chained scenarios)

| Gherkin step | Implementation |
|---|---|
| `I save the response field {string} as {string}` | `this.savedValues[name] = getNestedValue(data, path)` |
| `I get the resource with the saved {string}` | `this.savedValues[name]` → use in API call |

### Header Assertion Steps

| Gherkin step | Assertion |
|---|---|
| `the response header {string} should be {string}` | `expect(headers[name.toLowerCase()]).toBe(value)` |
| `the response should have header {string}` | `expect(headers[name.toLowerCase()]).toBeDefined()` |

---

## Helper Utilities

- **`getNestedValue(obj, path)`**: Dot-notation path resolver → `"data.product.name"` → value
- **`buildRequestBody(dataTable)`**: DataTable rowsHash với type coercion (string → number/boolean)

---

## Assertion Coverage Checklist

| Area | Assertions cần có |
|---|---|
| **Status codes** | 200, 201, 204, 400, 401, 403, 404, 422, 500 |
| **Field existence** | `toHaveProperty`, `toBeDefined`, `not.toHaveProperty` (sensitive fields) |
| **Field values** | Exact match, contains, pattern match (`toMatch`), numeric comparisons |
| **Collections** | Length, contains item matching, all items match, no item matches |
| **Errors** | Message content, error code, validation errors per field |
| **Pagination** | pageSize, items.length ≤ pageSize, total, totalPages calculation |
| **Schema** | Optional zod/ajv validation for complex responses |
| **Performance** | Response time `durationMs` (requires BaseApiClient modification) |

---

## Code Style

- TypeScript strict — no `any`
- async/await for all HTTP calls
- Import order: cucumber → api client → models → support
- Descriptive error messages in assertions
- Template literals for dynamic endpoints
