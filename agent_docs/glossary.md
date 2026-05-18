# Glossary

Thuật ngữ kỹ thuật dùng trong workspace này.

## Domain Terms

| Term | Description |
|------|-------------|
| Tenant | Khách hàng/tổ chức — mỗi tenant là một đơn vị độc lập trong hệ thống multi-tenant |
| Merchant | Alias của Tenant trong một số context |

## Technical Terms

| Term | Description |
|------|-------------|
| Shard | Database partition cho tenant isolation (Shard_{shardId}) |
| TenantContext | Context chứa tenant_id, shard_id — resolve ở entry point |
| Outbox | Transactional Outbox pattern — ghi event vào DB cùng transaction, relay qua CDC |
| CDC | Change Data Capture (Debezium) — đọc outbox table và publish ra Kafka |
| Idempotency | Check message_id trong Redis trước khi xử lý Kafka message |
| Aggregate Root | Entry point cho writes — enforce business rules, own child entities |
| UseCase | Command handler (write operations, EF Core) |
| Query | Query handler (read operations, Dapper) |
| Result\<T\> | Return type pattern — Success/Failure thay vì null/throw |
| UUIDv7 | Time-ordered UUID — dùng cho tất cả entity IDs mới |
| Branded Types | TypeScript type safety cho IDs — `type OrderId = Brand<string, 'OrderId'>` |
