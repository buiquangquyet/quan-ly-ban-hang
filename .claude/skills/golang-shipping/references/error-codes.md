# Error Codes Reference

All error codes are defined in `pkg/errbase/error.go`.

## Existing Codes

| Code constant | String value | HTTP status | Constructor | When to use |
|---|---|---|---|---|
| `CodeUndefined` | `UNDEFINED` | 500 | — | Unknown/untyped error |
| `CodeServerError` | `SERVER_ERROR` | 500 | `NewServerError()` | Generic internal error |
| `CodePanic` | `PANIC` | 500 | — | Panic recovery |
| `CodeDatabaseExecFail` | `DATABASE_EXEC_FAIL` | 500 | `NewDatabaseExecFail()` | DB query/write failed |
| `CodeDatabaseTxFail` | `DATABASE_TX_FAIL` | 500 | `NewDatabaseTxFail()` | Transaction commit/rollback failed |
| `CodeDatabaseResultDecodeFail` | `DATABASE_RESULT_DECODE_FAIL` | 500 | `NewDatabaseResultDecodeFail()` | Cannot decode DB result |
| `CodeBindFail` | `BIND_FAIL` | 400 | `NewBindFail()` | Request binding failed |
| `CodeValidateFail` | `VALIDATE_FAIL` | 400 | `NewValidateFail()` | Validation rule violated |
| `CodeJsonUnmarshalFail` | `JSON_UNMARSHAL_FAIL` | 400 | `NewJsonUnmarshalFail()` | JSON parse failed |
| `CodeNotFoundUser` | `NOT_FOUND_USER` | 404 | `NewNotFoundUser()` | User not found |
| `CodeNotFoundSetting` | `NOT_FOUND_SETTING` | 404 | `NewNotFoundSetting()` | Setting not found |
| `CodeAlreadyExistedUser` | `ALREADY_EXISTED_USER` | 409 | `NewAlreadyExistedUser()` | Duplicate user |

## Adding a New Error Code

1. Add constant to `pkg/errbase/error.go`:
```go
const (
    // ... existing ...
    CodeNotFoundOrder       Code = "NOT_FOUND_ORDER"
    CodeAlreadyExistedOrder Code = "ALREADY_EXISTED_ORDER"
)
```

2. Add HTTP status mapping in the same file:
```go
var httpStatusMap = map[Code]int{
    // ... existing ...
    CodeNotFoundOrder:       http.StatusNotFound,         // 404
    CodeAlreadyExistedOrder: http.StatusConflict,         // 409
}
```

3. Add constructor functions:
```go
func NewNotFoundOrder() *Error {
    return &Error{
        Code:       CodeNotFoundOrder,
        HttpStatus: httpStatusMap[CodeNotFoundOrder],
        stack:      captureStack(),
    }
}

func NewAlreadyExistedOrder() *Error {
    return &Error{
        Code:       CodeAlreadyExistedOrder,
        HttpStatus: httpStatusMap[CodeAlreadyExistedOrder],
        stack:      captureStack(),
    }
}
```

## Usage Pattern

```go
// Simple
return nil, errbase.NewNotFoundOrder()

// With context
return nil, errbase.NewNotFoundOrder().
    WithMessage("order does not exist in this retailer").
    WithDetail(map[string]any{"order_id": id, "retailer_id": retailerID}).
    WithCause(originalMongoErr)  // original cause is logged but not exposed to client

// Wrapping unknown errors
func handleUnknown(err error) error {
    e := errbase.Of(err)  // unwraps to *errbase.Error; wraps unknown errs with CodeUndefined
    if e.Code == errbase.CodeNotFoundOrder {
        // handle specifically
    }
    return e
}
```

## HTTP Status Guidelines

| Situation | Code | HTTP |
|---|---|---|
| Resource not found | `CodeNotFound*` | 404 |
| Duplicate/conflict | `CodeAlreadyExisted*` | 409 |
| Invalid input | `CodeBindFail`, `CodeValidateFail` | 400 |
| Business rule violation | define specific code | 422 |
| DB error | `CodeDatabaseExecFail` | 500 |
| Auth/unauthorized | define `CodeUnauthorized` | 401 |
| Forbidden | define `CodeForbidden` | 403 |
