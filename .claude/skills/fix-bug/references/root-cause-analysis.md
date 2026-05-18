# Root Cause Analysis for Development Bugs

Techniques phân tích root cause trong context development (khác với production RCA của respond-incident skill). Focus vào code-level investigation và evidence gathering.

---

## 5 Whys (Adapted for Code)

Bắt đầu từ symptom, hỏi "tại sao" lặp lại cho đến khi đến root cause actionable.

**Ví dụ**:
- Tại sao tổng tiền sai? -> Discount applied sau tax
- Tại sao sau tax? -> `CalculateTotal()` gọi `ApplyDiscount()` sau `CalculateTax()`
- Tại sao thứ tự đó? -> Original dev giả định discount trên final amount
- -> **Root cause**: Sai business logic assumption trong calculation order

**Tips**:
- Dừng khi 3-5 whys, quá 5 thường là overthinking
- Mỗi "why" phải có evidence từ code (file:line)
- Dừng lại khi đến được actionable code change

---

## Hypothesis Testing Framework

Structured approach khi root cause không hiển nhiên.

### Process:

1. **State hypothesis**: "Tôi tin rằng X gây ra Y vì Z"
   - Phải cụ thể: file, function, line, condition
   - Ví dụ: "Race condition trong `OrderService.ProcessAsync()` line 78 vì `_cache` được access không có lock"

2. **Predict**: Nếu hypothesis đúng, gì khác phải true?
   - Ví dụ: "Nếu là race condition, bug chỉ xảy ra khi 2+ requests concurrent"

3. **Test prediction**: Verify prediction có đúng không
   - Đọc code confirm pattern
   - Check git blame xem khi nào code thay đổi
   - Tìm evidence trong logs/data

4. **Evaluate**:
   - Prediction đúng -> hypothesis likely correct, proceed to fix
   - Prediction sai -> revise hypothesis, lặp lại từ bước 1

### Template:

```
Hypothesis #1: [Mô tả root cause]
- Evidence for: [Gì ủng hộ hypothesis này]
- Evidence against: [Gì mâu thuẫn]
- Prediction: [Nếu đúng thì X phải true]
- Confidence: [High/Medium/Low] + lý do
```

---

## Confidence Scoring

Đánh giá mức độ tin tưởng vào mỗi hypothesis để user quyết định.

| Level | Range | Điều kiện |
|-------|-------|-----------|
| **High** | 80-100% | Direct evidence trong code, reproducible, clear causal chain |
| **Medium** | 50-79% | Circumstantial evidence, plausible nhưng chưa confirm, hoặc chỉ reproduce được intermittent |
| **Low** | 0-49% | Speculation, cần thêm investigation, hoặc evidence mâu thuẫn |

**Quy tắc**:
- High confidence -> recommend proceed to fix
- Medium confidence -> recommend thêm 1-2 investigation steps để confirm
- Low confidence -> recommend investigate khác approach, có thể cần thêm logging hoặc monitoring

---

## Fault Tree Analysis (Simplified)

Dùng khi bug có nhiều possible causes (OR) hoặc cần nhiều điều kiện đồng thời (AND).

### Cách dùng:

1. **Root**: Symptom (VD: "API trả 500")
2. **Level 1**: Possible causes (OR gate — bất kỳ cause nào cũng đủ)
   - Database timeout
   - Null reference
   - Auth failure
3. **Level 2**: Sub-causes cho mỗi Level 1
   - Database timeout -> Connection pool exhausted OR slow query OR deadlock
4. **Prioritize**: Verify causes theo likelihood và ease of checking
   - Kiểm tra dễ nhất trước (check logs, check config)
   - Kiểm tra likely nhất trước (dựa trên recent changes, pattern)

### Template:

```
[SYMPTOM] API trả 500
├── [OR] Database issue
│   ├── Connection pool exhausted -> Check: connection count, pool config
│   ├── Slow query -> Check: query execution time, missing index
│   └── Deadlock -> Check: SQL Server deadlock graph
├── [OR] Code error
│   ├── Null reference -> Check: null checks, optional chaining
│   └── Type mismatch -> Check: serialization, casting
└── [OR] External dependency
    ├── Service down -> Check: health endpoint
    └── Timeout -> Check: timeout config, network
```

---

## Evidence Gathering Techniques

### Code Reading
- Trace execution path với file:line references
- Follow method calls từ entry point đến error point
- Check all branches và edge cases
- Dùng IDE "Find Usages" / "Go to Definition" để trace

### Git History
- `git log -p -- <file>`: Xem lịch sử thay đổi của file
- `git blame <file>`: Ai thay đổi dòng nào, khi nào
- `git bisect`: Binary search tìm commit introduce bug
- `git log --oneline -20`: Recent changes có thể liên quan

### Data Inspection
- Check actual values tại key points (logging, debugger)
- So sánh: working data vs broken data
- Tìm pattern: data nào trigger bug, data nào không?

### Comparison
- Working flow vs broken flow: gì khác biệt?
- Working environment vs broken environment: config nào khác?
- Working version vs broken version: code nào thay đổi?

---

## Khi Nào Escalate

Escalate (hỏi user, hỏi team, hoặc log bug cho team khác) khi:
- Đã thử 3+ hypotheses mà không tìm được root cause
- Bug ở code không thuộc scope của team
- Fix cần thay đổi architecture hoặc shared library
- Bug là known issue của third-party dependency
- Cần access production data/logs mà không có quyền
