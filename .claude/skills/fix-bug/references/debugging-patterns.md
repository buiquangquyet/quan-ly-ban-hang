# Debugging Patterns & Bug Classification

Catalog phân loại bug và investigation strategies cho từng loại. Dùng trong Phase 2 của fix-bug skill để chọn đúng approach điều tra.

---

## Bug Categories

### 1. Logic Bugs

**Dấu hiệu**: Output sai, calculation sai, kết quả không khớp expected behavior

**Ví dụ**: Discount tính sai, sorting order ngược, off-by-one error, wrong operator (`&&` thay vì `||`)

**Investigation strategy**:
- Trace data flow step-by-step từ input đến output
- Check boundary values (0, 1, max, empty, null)
- Check conditions và branching logic — có path nào bị miss?
- So sánh expected vs actual tại mỗi bước

### 2. State Bugs

**Dấu hiệu**: Hoạt động lúc đúng lúc sai, phụ thuộc vào thứ tự operations

**Ví dụ**: Shared mutable state, stale cache, initialization order sai, state không reset giữa requests

**Investigation strategy**:
- Identify tất cả state mutations (ai thay đổi state, khi nào?)
- Check lifecycle: initialization -> usage -> cleanup
- Check shared state giữa threads/requests
- Check caching: invalidation đúng chưa?

### 3. Integration Bugs

**Dấu hiệu**: Lỗi khi gọi service khác, DB, hoặc external API

**Ví dụ**: API contract mismatch, serialization/deserialization sai, timeout handling thiếu, wrong HTTP method/status code

**Investigation strategy**:
- Check contracts tại boundaries (request/response schema)
- Verify data transformations giữa systems
- Check error handling — timeout, retry, fallback
- So sánh actual API call vs expected (headers, body, query params)

### 4. Concurrency Bugs

**Dấu hiệu**: Intermittent failures, timing-dependent, chỉ xảy ra dưới load

**Ví dụ**: Race conditions, deadlocks, non-atomic read-modify-write, missing locks, async/await sai

**Investigation strategy**:
- Identify shared resources và access patterns
- Check locking strategy (missing lock, lock ordering, lock scope)
- Check async/await correctness (missing await, fire-and-forget)
- Test dưới concurrent load để reproduce

### 5. Data Bugs

**Dấu hiệu**: Chỉ xảy ra với data cụ thể, hoạt động bình thường với data khác

**Ví dụ**: Null/undefined handling, encoding issues (UTF-8, BOM), type coercion sai, special characters, boundary values

**Investigation strategy**:
- Test với edge case data: null, empty string, unicode, special chars, max length
- Check type conversions (implicit casting, serialization)
- Check encoding chain: source -> processing -> output
- Tìm data pattern: chỉ fail khi data có đặc điểm gì?

### 6. Configuration Bugs

**Dấu hiệu**: Lỗi ở environment cụ thể (dev OK, staging fail), hoặc sau config change

**Ví dụ**: Wrong env vars, missing config, feature flag conflict, dependency version mismatch, connection string sai

**Investigation strategy**:
- Diff configurations giữa working vs broken environments
- Check env vars, config files, feature flags
- Check dependency versions (package.json, .csproj)
- Check infrastructure: connection strings, endpoints, certificates

---

## Investigation Techniques

### Binary Search (git bisect)

**Khi nào**: Bug tồn tại bây giờ nhưng trước đó hoạt động bình thường

**Cách dùng**:
1. Tìm commit cuối cùng mà code còn hoạt động (good)
2. Tìm commit đầu tiên mà bug xuất hiện (bad)
3. `git bisect start` -> `git bisect bad` -> `git bisect good <commit>` -> test mỗi commit git suggest
4. Git sẽ narrow down đến commit introduce bug

### Delta Debugging

**Khi nào**: Bug trigger bởi specific input nhưng không biết phần nào của input gây ra

**Cách dùng**:
1. Bắt đầu với full input trigger bug
2. Chia đôi input, test mỗi nửa
3. Tiếp tục chia cho đến khi tìm được minimal reproduction
4. Minimal input = pin-point root cause

### Trace Logging

**Khi nào**: Execution path phức tạp, khó trace bằng đọc code

**Cách dùng**:
1. Thêm logging tại key decision points
2. Log: input values, conditions, branch taken, output values
3. Run với bug-triggering scenario
4. So sánh log output vs expected flow
5. Xóa logging sau khi tìm được root cause

### Comparison Debugging

**Khi nào**: Bug chỉ xảy ra trong điều kiện cụ thể

**Cách dùng**:
1. Setup 2 scenarios: 1 working, 1 broken
2. So sánh từng yếu tố: input data, config, state, timing
3. Narrow down: thay đổi 1 yếu tố tại 1 thời điểm
4. Yếu tố nào làm switch từ working -> broken = root cause

---

## Common Pitfalls

| Pitfall | Tại sao nguy hiểm | Cách tránh |
|---------|-------------------|------------|
| Fix symptom thay vì root cause | Bug sẽ quay lại hoặc xuất hiện ở chỗ khác | Luôn trace đến root cause với evidence |
| Giả định bug ở chỗ error manifest | Error message có thể ở xa root cause | Trace ngược từ error đến source |
| Không check bug ở nhiều nơi | Fix 1 chỗ nhưng bug tồn tại ở 5 chỗ khác | Search similar patterns trong codebase |
| Quên check recent changes | 80% bugs liên quan đến code mới thay đổi | `git log --oneline -20` là bước đầu tiên |
| Shotgun debugging (thử random) | Tạo bugs mới, mất thời gian, không hiểu root cause | Hypothesis -> evidence -> fix |
| Không viết test reproduce | Không chắc fix đúng, không có regression protection | Luôn viết failing test trước khi fix |
