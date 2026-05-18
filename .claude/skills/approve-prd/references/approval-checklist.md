# PRD Business Approval Checklist

Reference file cho skill `approve-prd`. Mỗi dimension có hướng dẫn chi tiết để giúp approver đưa ra quyết định có cơ sở.

---

## Dimension 1: Business Value

**Mục tiêu**: Xác nhận PRD giải quyết đúng vấn đề và có impact rõ ràng.

**Câu hỏi cần trả lời**:
- Problem statement có mô tả đủ "why now" — tại sao feature này cần build ở sprint này không?
- Impact được đo bằng metric cụ thể không? (ví dụ: giảm 30% support ticket, tăng conversion 5%)
- User benefit có được articulate từ góc nhìn người dùng, không phải từ góc nhìn system không?

**Dấu hiệu cần reject**:
- Problem statement chỉ nói "system cần có tính năng X" mà không giải thích tại sao
- Không có metric hoặc KPI để đo success
- Impact mơ hồ: "cải thiện trải nghiệm người dùng"

---

## Dimension 2: Stakeholder Alignment

**Mục tiêu**: Đảm bảo đúng người đã tham gia định nghĩa requirements, tránh rework sau khi dev bắt đầu.

**Câu hỏi cần trả lời**:
- Các UC và AC có phản ánh đúng ý kiến của business owners không?
- UX/Design đã review và sign-off chưa (nếu feature có UI)?
- Ops/Infra có được tham khảo về NFR chưa?
- Feature owner (PO) được xác định rõ chưa?

**Dấu hiệu cần reject**:
- Requirements viết từ assumption của dev team, không có input từ business
- Feature có UI nhưng không có Figma link và Design chưa review
- NFR được đặt ra mà không confirm với team infra/ops

---

## Dimension 3: Scope & Priority

**Mục tiêu**: Đảm bảo scope phù hợp capacity và priority được set đúng.

**Câu hỏi cần trả lời**:
- Số lượng Must Have UCs có phù hợp với 1 sprint không? (thông thường ≤ 5-7 UC/sprint)
- Out of Scope có được liệt kê đầy đủ để tránh scope creep không?
- Could Have có nguy cơ bị pull vào Must Have không?
- Có UC nào nên tách thành epic riêng không?

**Dấu hiệu cần reject**:
- Tất cả UC đều là Must Have — thiếu MoSCoW prioritization thực chất
- Out of Scope trống hoặc quá generic ("mọi thứ không được đề cập")
- Scope quá lớn để deliver trong 1 sprint mà không được giải thích

---

## Dimension 4: Feasibility

**Mục tiêu**: Xác nhận PRD khả thi về mặt kỹ thuật và resource trong timeline đề xuất.

**Câu hỏi cần trả lời**:
- Team có đủ kỹ năng để implement không?
- External dependencies (3rd party API, other team, data source) đã được xác nhận availability chưa?
- NFR có realistic không? (ví dụ: "response time < 100ms" với query phức tạp trên dataset lớn)
- Có technical debt hoặc refactoring lớn cần làm trước khi implement feature này không?

**Dấu hiệu cần reject**:
- NFR đặt ra con số cụ thể nhưng chưa có bất kỳ benchmark/analysis nào
- Dependencies với external team nhưng chưa có agreement
- Feature require infrastructure mới (new service, new DB) nhưng chưa có plan

---

## Dimension 5: Compliance & Risk

**Mục tiêu**: Đảm bảo các yêu cầu pháp lý, bảo mật, và privacy được đề cập đầy đủ.

**Câu hỏi cần trả lời**:
- Feature có xử lý PII (Personal Identifiable Information) không? Nếu có, GDPR/PDPA compliance được đề cập chưa?
- Authentication và authorization requirements có rõ ràng không?
- Có financial transaction không? Audit log requirements có được nêu không?
- Rủi ro chính (technical, business, security) đã được nhận diện chưa?

**Dấu hiệu cần reject**:
- Feature xử lý data nhạy cảm nhưng không có security requirements
- Financial feature nhưng không có audit trail requirement
- Không có error handling plan cho critical path failures

---

## Dimension 6: Success Metrics

**Mục tiêu**: Đảm bảo có cách đo lường xem feature có thành công không sau khi ship.

**Câu hỏi cần trả lời**:
- Có ít nhất 1 leading metric (đo được trong vòng 2 tuần sau ship) không?
- Có ít nhất 1 lagging metric (đo impact dài hạn) không?
- Acceptance criteria có đủ specific để dùng làm definition of done không?
- Có plan để track metrics sau khi launch không? (analytics event, dashboard)

**Dấu hiệu cần reject**:
- Success chỉ được định nghĩa là "feature hoạt động đúng spec" — không có business KPI
- Không có plan để collect metrics (không có analytics, không có monitoring)
- AC quá mơ hồ: "user có thể thực hiện X" mà không nêu điều kiện cụ thể

---

## Approval Scenarios & Guidance

### Scenario A: Full Approval (recommended)
Tất cả 6 dimensions đều pass → Approve không điều kiện.

### Scenario B: Conditional Approval
Một số items là `no` nhưng không blocking → Approve với conditions:
- Ghi rõ conditions trong Approval Record
- Assign owner và deadline cho mỗi condition
- Ví dụ: "Approved conditional on: Design sign-off before sprint start"

### Scenario C: Rejection với Feedback
Dimension 1, 2, hoặc 6 fail → Reject và yêu cầu revise:
- Giải thích rõ lý do và cách fix
- Không để user đoán "tại sao bị reject"

### Scenario D: Partial Scope Approval
Scope quá lớn → Approve subset (Must Have only):
- Mark Should Have và Could Have là "deferred to next sprint"
- Đề xuất tách thành epic mới nếu cần

---

## Anti-patterns cần tránh

| Anti-pattern | Vấn đề |
|--------------|--------|
| Approve PRD mà chưa đọc | Mất ý nghĩa của approval gate |
| Approve với quá nhiều conditions mà không track | Conditions bị quên, rủi ro tăng |
| Reject vì lý do kỹ thuật | approve-prd chỉ gate business concerns — kỹ thuật thuộc review-prd |
| Block approval vì MoSCoW chưa perfect | Ghi note và move on — đừng dừng flow vì minor |
