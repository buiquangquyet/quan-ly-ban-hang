# Authentication Flow — shipping-api

| Middleware | Alias | Header | Validate against | Dùng cho |
|---|---|---|---|---|
| `VerifyJWTToken` | `web.jwt` | Cookie `JWTToken` | `tymon/jwt-auth` | Admin/Web UI |
| `ApiKeyAuthentication` | `apiKeyAuth` | `x-api-key` | env `CORE_API_AUTHENTICATION_KEY` | Internal service-to-service |
| `AuthWidgetKv` | `widgetAuthKv` | `token` | JWT claims (kvrcode, kvrid, kvuid…) | Merchant widget |
| `AuthKolPublic` | `kolPublic` | `x-api-key` + body `retailer_id`, `branch_id` | env `KOL_X_API_KEY` | KOL API (public) |
| `AuthKolFlexible` | `kolFlexible` | `token` (JWT) hoặc `x-api-key` | JWT / env `KOL_X_API_KEY` | KOL API (hybrid) |
| `KSCRMAuthentication` | `kscrm.auth` | `X-API-Key` hoặc `Authorization: Bearer` | env `KSCRM_API_KEY` / `AI_API_KEY` + rate limit 200/phút | CRM / AI integration |

## JWT Widget Claims

| Claim | Field | Claim | Field |
|---|---|---|---|
| `kvrcode` | shop_code | `kvuid` | retailer_user_id |
| `kvrid` | retailer_id | `kvuadmin` | is_admin |
| `kvbid` | branch_id | `preferred_username` | username |
