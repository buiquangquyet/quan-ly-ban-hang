# Feature Discovery — Modes, Techniques & Question Banks

## 3 Discovery Modes

### Mode 1: Problem-First

**When to use**: User mô tả pain point, vấn đề, hoặc complaint — chưa có solution trong đầu.

**Goal**: Hiểu root cause, map problem ecosystem, explore solution space rộng trước khi converge.

**Workflow**:
1. Map who has the problem (user roles, frequency, severity)
2. Understand current state — what are they doing today?
3. Identify root cause via 5 Whys
4. Explore solution directions (3+ options)
5. Evaluate fit and choose direction

**Key questions**:
- "Vấn đề xảy ra với ai? Tất cả user hay subset cụ thể?"
- "Họ biết vấn đề này tồn tại không? Hay chỉ trải nghiệm mà không nhận ra?"
- "Điều gì trigger vấn đề? Luôn xảy ra hay chỉ trong điều kiện nhất định?"
- "Hệ quả nếu không giải quyết — cho user, cho business?"
- "Ai đã giải quyết vấn đề tương tự trong context khác?"

**Traps to avoid**:
- Nhảy vào solution sau câu hỏi đầu tiên
- Assume root cause mà không probe deeper
- Confuse symptom với problem ("app chậm" là symptom — root cause có thể là query không optimize, design không phù hợp, hay expectation mismatch)

---

### Mode 2: Solution-First

**When to use**: User đề xuất feature/solution cụ thể — "tôi muốn thêm X", "build Y".

**Goal**: Uncover problem behind the solution, validate fit, tránh build wrong thing.

**Workflow**:
1. Acknowledge solution idea
2. Uncover problem: "Solution này giải quyết vấn đề gì?"
3. Validate problem: evidence, frequency, severity
4. Check fit: is this solution the best fit for the problem?
5. Explore alternatives: "Có cách nào khác giải quyết problem này không?"
6. Confirm direction

**Key questions**:
- "Feature này giải quyết vấn đề gì cho user?"
- "User nào sẽ dùng feature này? Tần suất?"
- "Nếu không có feature này, user làm gì? Workaround có acceptable không?"
- "Tại sao solution này — thay vì [alternative approach]?"
- "Assumption quan trọng nhất là gì? Chúng ta có evidence không?"

**Traps to avoid**:
- Reject solution ngay mà không explore problem
- Accept solution mà không question fit
- Forget to explore alternatives

---

### Mode 3: Opportunity-First

**When to use**: User thấy market opportunity, gap, hoặc competitive threat — "đối thủ có X, chúng ta chưa có", "thị trường cần Y".

**Goal**: Validate opportunity, identify user need, xác định business case trước khi commit.

**Workflow**:
1. Define opportunity: what exactly is the gap?
2. Validate market need: do our users actually need this?
3. Understand competitive context: what are competitors doing and why?
4. Identify user jobs-to-be-done
5. Explore build vs buy vs partnership
6. Define MVP scope

**Key questions**:
- "Cơ hội này real hay perceived? Evidence từ đâu?"
- "User của chúng ta có job-to-be-done này không? Hay chỉ competitor's users?"
- "Đối thủ implement như thế nào? Users hài lòng không?"
- "Nếu không có feature này, chúng ta mất gì? User churn? Deals blocked?"
- "MVP nhỏ nhất để test opportunity này là gì?"

---

## Discovery Techniques Chi Tiết

### 5 Whys — Root Cause Analysis

Dùng để drill down từ symptom đến root cause.

**Protocol**:
1. Start với problem statement user cung cấp
2. Hỏi "Tại sao?" — tìm underlying cause
3. Lặp lại với câu trả lời mới
4. Dừng khi đạt structural/systemic cause (thường sau 3-5 lần)

**Example**:
- "Nhân viên mất nhiều thời gian báo cáo cuối tháng"
- Tại sao? → "Phải tổng hợp data từ nhiều sheet Excel khác nhau"
- Tại sao sheets khác nhau? → "Mỗi team dùng template riêng"
- Tại sao templates khác nhau? → "Không có standard được enforce"
- Tại sao không enforce? → "Không có tool nào tự động validate format khi nhập"
- Root cause: **thiếu data entry validation và standardization**, không phải "thiếu báo cáo feature"

**Khi nào dừng**: Khi đạt level mà cause là structural (process, policy, tool gap) — không còn "tại sao" có meaningful answer.

---

### Jobs-to-be-Done (JTBD)

Dùng để frame user need theo job language, không theo feature language.

**Structure**:
> Khi **[tình huống/trigger]**, tôi muốn **[động lực/mục tiêu]** để **[kết quả/outcome mong muốn]**.

**Levels**:
- **Functional job**: Làm được việc gì đó — "export báo cáo để gửi cho sếp"
- **Emotional job**: Cảm thấy thế nào — "cảm thấy confident khi present data"
- **Social job**: Được nhìn nhận thế nào — "được team nhìn nhận là người làm việc data-driven"

**Tips**:
- Functional jobs dễ discover — hỏi "user đang cố làm gì?"
- Emotional và social jobs mạnh hơn nhưng cần probe deeper — "tại sao điều đó quan trọng với họ?"
- Job stable dù solution thay đổi — "chia sẻ update với team" là job cũ, từ email đến Slack đến Teams

**Discovery questions**:
- "Khi nào user tìm đến tính năng này? Trigger là gì?"
- "Kết quả thực sự họ muốn đạt được là gì — không phải feature, mà là outcome?"
- "Họ 'hire' sản phẩm nào trước đây để làm job này? Tại sao switch?"

---

### Assumption Mapping

Dùng để identify và prioritize assumptions cần validate.

**Categories**:

| Category | Question |
|----------|----------|
| **User** | Users muốn feature này — evidence gì? Có bao nhiêu users? |
| **Problem** | Đây là real problem — tần suất, severity? |
| **Solution** | Solution này sẽ work — tại sao approach này? |
| **Business** | Điều này sẽ move metric — metric nào, bao nhiêu? |
| **Feasibility** | Chúng ta có thể build — timeline, trade-offs? |
| **Adoption** | Users sẽ tìm và dùng — behavior change nào required? |

**Prioritization matrix**:

| | High Importance | Low Importance |
|---|---|---|
| **High Risk** | VALIDATE FIRST — kill-switch assumptions, test before building | VALIDATE LATER — important but less urgent |
| **Low Risk** | MONITOR — track but not critical | ACCEPT — safe to assume for now |

**Cheapest validation methods** (tăng dần effort):
1. Desk research — data có sẵn, competitor analysis
2. Survey / poll existing users
3. User interview (5-7 người)
4. Prototype test / landing page
5. Wizard of Oz / concierge MVP
6. Technical spike

---

### Inversion — Anti-Problem Thinking

Dùng khi stuck hoặc muốn surface hidden constraints.

**Protocol**:
1. Đảo ngược: "Điều gì sẽ làm tính năng này thất bại hoàn toàn?"
2. Generate danh sách failure modes
3. Đảo ngược lại: mỗi failure mode → success condition
4. Evaluate: success conditions nào quan trọng nhất để address

**Example**:
- Feature: notification hệ thống đơn hàng
- Failure modes: quá nhiều notification → user tắt, notification không đúng timing, không personalized, không actionable
- Success conditions: chỉ notify milestone quan trọng, đúng lúc cần, có action rõ ràng

---

## Question Banks Theo Dimension

### Dimension 1: Problem & User Need

**Để identify who**:
- "User nào gặp vấn đề này nhất? Tất cả hay subset?"
- "Có sự khác biệt về pain giữa new user và experienced user không?"
- "Ai là user bị ảnh hưởng nhiều nhất nếu không giải quyết?"

**Để understand severity**:
- "Tần suất vấn đề xảy ra? Hàng ngày, hàng tuần, hàng tháng?"
- "Impact cụ thể là gì — mất bao nhiêu thời gian? Mất tiền? Gây frustration?"
- "User có churn vì vấn đề này không? Có data không?"

**Để discover current state**:
- "Họ đang làm gì để giải quyết vấn đề này today?"
- "Workaround hiện tại có acceptable không? Tại sao không?"
- "Có tool nào bên ngoài họ dùng thay thế không?"

---

### Dimension 2: Context & Trigger

**Để map context**:
- "Vấn đề xảy ra trong workflow nào? Trước/sau bước nào?"
- "Môi trường nào — desktop, mobile, trong cuộc họp, đang di chuyển?"
- "Ai khác involved khi vấn đề xảy ra? Có dependencies không?"

**Để understand trigger**:
- "Điều gì khiến user cần tính năng này ngay lúc đó?"
- "Có urgency không? Hay là nice-to-have khi rảnh?"
- "Có deadline hay event nào liên quan không?"

---

### Dimension 3: Success & Value

**Để define success**:
- "Nếu tính năng hoạt động perfectly, user experience như thế nào?"
- "Metric nào thay đổi? Bao nhiêu là đủ để call it success?"
- "Ai trong tổ chức sẽ biết feature này thành công?"

**Để quantify value**:
- "Business benefit cụ thể — tăng revenue, giảm cost, tăng retention?"
- "Có thể estimate được không — vd: 100 users × 30 phút tiết kiệm/tuần?"
- "Nếu không build, cost của việc không làm là gì?"

---

### Dimension 4: Scope & Boundaries

**Để clarify scope**:
- "Đây là MVP hay full vision? Chúng ta đang spec cho giai đoạn nào?"
- "Có phần nào related nhưng chủ động exclude không? Tại sao?"
- "Có phase 2, phase 3 không? Ranh giới ở đâu?"

**Để find dependencies**:
- "Feature này depend vào feature/team/system nào khác?"
- "Có API, data, hoặc infrastructure nào cần build trước không?"
- "Stakeholder nào cần approve scope này?"

---

### Dimension 5: Constraints & Risks

**Để surface constraints**:
- "Technical limitation nào đã biết? Cái gì đặc biệt hard?"
- "Business constraint — compliance, legal, budget?"
- "Timeline cứng không? Có deadline business nào không?"

**Để validate assumptions**:
- "Assumption quan trọng nhất trong feature này là gì?"
- "Confidence level bao nhiêu? Evidence từ đâu?"
- "Nếu assumption này sai, feature có còn value không?"

**Để assess risk**:
- "Worst case scenario nếu build xong mà không work?"
- "Có thể rollback không? Reversibility thế nào?"
- "User impact nếu có bug — minor inconvenience hay critical failure?"

---

### Dimension 6: Edge Cases & Exceptions

**Để discover edge cases**:
- "Điều gì xảy ra khi user không có permission?"
- "Behavior khi data trống, null, hay invalid?"
- "Điều gì xảy ra khi 2 user thực hiện action cùng lúc?"
- "Mobile behavior khác desktop không?"

**Để identify exceptions**:
- "Có user nào sẽ dùng feature này theo cách unexpected không?"
- "Power user behavior khác new user thế nào?"
- "Có edge case nào cần business decision — không phải tech decision?"

---

## Feature Brief Quality Checklist

Trước khi handoff sang `/write-prd`, verify Feature Brief đã cover:

- [ ] Problem statement rõ ràng — ai gặp, tần suất, impact
- [ ] Target users xác định — roles cụ thể, không phải generic "người dùng"
- [ ] JTBD articulated — functional job ít nhất
- [ ] Feature direction phác thảo — không phải spec chi tiết, nhưng đủ hướng
- [ ] Key capabilities listed — 3-5 điều hệ thống cần làm
- [ ] Success metrics defined — ít nhất 1 measurable metric
- [ ] Constraints documented — business và technical
- [ ] Out of scope explicit — ít nhất 1-2 items với lý do
- [ ] Key assumptions listed — với confidence và validation method
- [ ] Open questions captured — không để hidden unknowns

**Green light cho /write-prd**: Tất cả checkboxes ticked, hoặc user explicitly acknowledge các gaps và accept risk.

**Yellow light**: Còn open questions quan trọng — proceed nhưng flag trong PRD Open Questions section.

**Red light**: Problem statement chưa rõ, hoặc chưa biết target users → tiếp tục discovery.
