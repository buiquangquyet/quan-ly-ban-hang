# Repository Structure & Access

Mô tả cấu trúc solution KShip: tổ chức git repositories, access model, và branch strategy.

---

## Solution Overview

KShip sử dụng mô hình **monorepo-with-submodules**: một meta-repo trung tâm quản lý 14 submodule độc lập thông qua Git submodules. Mỗi submodule là một project riêng, có vòng đời độc lập, nhưng được đồng bộ hoá branch và version thông qua workspace.

```
shipping-meta-repo  (workspace, không chứa source code)
├── src/shipping-api
├── src/shipping-cpanel
├── src/shipping-cron
├── src/shipping-merchant
├── src/shipping-report
├── src/shipping-report-v5
├── src/shipping-log
├── src/kship-golang-check-price
├── src/kship-golang-add-on
├── src/kship-nodejs-check-price-v3
├── src/kship-widget-fnb
├── src/shipping-widget
├── src/kship-wiki-v2
└── src/kiotviet-shipping-location
```

---

## Git Hosting

| Property | Value |
|----------|-------|
| Provider | GitLab self-hosted |
| Host | `https://gitlab.citigo.com.vn` |
| Group | `kship/` |
| Meta-repo | `kship/shipping-meta-repo` |

Tất cả repositories đều nằm trong GitLab group **`kship/`**. Access được quản lý ở cấp group — thành viên group thừa hưởng permission vào tất cả repos trong group.

---

## Repository Inventory

### Meta-repo (Workspace)

| Repository | GitLab URL | Mục đích |
|-----------|-----------|----------|
| `shipping-meta-repo` | `https://gitlab.citigo.com.vn/kship/shipping-meta-repo` | Workspace quản lý submodules, chứa Makefile, CLAUDE.md, agent_docs, test configs |

### Backend Services

| Repository | GitLab URL | Stack | Submodule path |
|-----------|-----------|-------|----------------|
| `shipping-api` | `https://gitlab.citigo.com.vn/kship/shipping-api.git` | Laravel PHP 7.3 | `src/shipping-api` |
| `shipping-cpanel` | `https://gitlab.citigo.com.vn/kship/shipping-cpanel.git` | Laravel PHP 7.3 | `src/shipping-cpanel` |
| `shipping-cron` | `https://gitlab.citigo.com.vn/kship/shipping-cron.git` | Laravel PHP 7.3 | `src/shipping-cron` |
| `shipping-merchant` | `https://gitlab.citigo.com.vn/kship/shipping-merchant.git` | Go 1.22, Gin + gRPC | `src/shipping-merchant` |
| `kship-golang-check-price` | `https://gitlab.citigo.com.vn/kship/kship-golang-check-price.git` | Go 1.21, Gin | `src/kship-golang-check-price` |
| `kship-golang-add-on` | `https://gitlab.citigo.com.vn/kship/kship-golang-add-on.git` | Go 1.24, Gin + gRPC | `src/kship-golang-add-on` |
| `kship-nodejs-check-price-v3` | `https://gitlab.citigo.com.vn/kship/kship-nodejs-check-price-v3.git` | Node.js 16, Express | `src/kship-nodejs-check-price-v3` |
| `shipping-report` | `https://gitlab.citigo.com.vn/kship/shipping-report.git` | Laravel PHP 7.3 | `src/shipping-report` |
| `shipping-report-v5` | `https://gitlab.citigo.com.vn/kship/shipping-report-v5.git` | Go 1.24, Gin, GORM | `src/shipping-report-v5` |
| `shipping-log` | `https://gitlab.citigo.com.vn/kship/shipping-log.git` | — | `src/shipping-log` |

### Frontend / Widget

| Repository | GitLab URL | Stack | Submodule path |
|-----------|-----------|-------|----------------|
| `shipping-widget` | `https://gitlab.citigo.com.vn/kship/shipping-widget.git` | JavaScript, Webpack | `src/shipping-widget` |
| `kship-widget-fnb` | `https://gitlab.citigo.com.vn/kship/kship-widget-fnb.git` | JavaScript, Laravel Mix | `src/kship-widget-fnb` |

### Data / Location

| Repository | GitLab URL | Stack | Submodule path |
|-----------|-----------|-------|----------------|
| `kiotviet-shipping-location` | `https://gitlab.citigo.com.vn/kship/kiotviet-shipping-location.git` | — | `src/kiotviet-shipping-location` |

### QA / Documentation

| Repository | GitLab URL | Stack | Submodule path |
|-----------|-----------|-------|----------------|
| `kship-wiki-v2` | `https://gitlab.citigo.com.vn/kship/kship-wiki-v2.git` | TypeScript, CucumberJS 12, Playwright 1.56 | `src/kship-wiki-v2` |

---

## Access Model

### GitLab Roles

GitLab sử dụng role-based access control (RBAC) với 5 cấp độ:

| Role | Quyền chính |
|------|-------------|
| **Owner** | Toàn quyền: quản lý group, xoá repo, thay đổi visibility |
| **Maintainer** | Merge vào protected branches, quản lý CI/CD, quản lý members |
| **Developer** | Push/pull code, tạo MR, tạo branch, chạy pipelines |
| **Reporter** | Xem code, clone repo, xem issues/MRs |
| **Guest** | Xem issues và comments (không xem code) |

### Access Scope

- **Group-level access**: Gán role ở group `kship/` → thừa hưởng vào tất cả repos trong group.
- **Project-level override**: Từng repo có thể override role riêng (ví dụ: chỉ một số Developer có Maintainer trên `shipping-api`).
- **Protected branches**: Branches `main` và `develop` được protect — chỉ Maintainer trở lên mới merge trực tiếp; Developer phải tạo MR.

### Recommended Access by Team

| Team | Role đề xuất | Phạm vi |
|------|-------------|---------|
| Backend Engineers | Developer | Tất cả backend repos |
| Frontend Engineers | Developer | `shipping-widget`, `kship-widget-fnb`, `shipping-cpanel` |
| QA Engineers | Developer | `kship-wiki-v2` + Reporter trên service repos |
| Tech Leads / DevOps | Maintainer | Tất cả repos |
| Project Managers | Reporter | Meta-repo, tất cả service repos |

---

## Branch Strategy

### Standard Branches

| Branch | Mục đích | Protected |
|--------|----------|-----------|
| `main` | Production-ready code | Có — chỉ merge qua MR |
| `develop` | Integration branch, staging | Có — chỉ merge qua MR |
| `feat/<ticket-id>/<description>` | Feature development | Không |
| `fix/<ticket-id>/<description>` | Bug fixes | Không |
| `hotfix/<description>` | Production hotfix | Không |

Ví dụ: `feat/SHIP-13978/clients-kol` hoặc `quyetbq/SHIP-13978` (user-scoped feature branch).

### Branch Synchronisation

Meta-repo và submodules sử dụng **cùng tên branch** để tránh nhầm lẫn. Tạo/xoá branch luôn thực hiện qua Makefile để đồng bộ:

```bash
# Tạo branch trên workspace + tất cả submodules
make branch-create NAME=feat/SHIP-xxxx/feature-name

# Kiểm tra trạng thái branch
make branch-status

# Xoá branch sau khi merge
make branch-delete NAME=feat/SHIP-xxxx/feature-name
```

### Submodule Commit Pinning

Meta-repo **không track branch** mà **track commit SHA** của từng submodule. Khi phát triển xong một submodule:

1. Commit + push trong submodule
2. Về meta-repo: `git add src/<submodule>` → commit meta-repo để cập nhật SHA pointer
3. Tên commit meta-repo theo format: `[TICKET-ID] Update submodule: <submodule-name> — <mô tả>`

```
Ví dụ commit lịch sử:
  3e9f6ad [SHIP-13978] Update submodule: shipping-api — unit tests for getAllClientsKol
  29b2b68 [SHIP-13978] Update submodule: shipping-api — getAllClientsKol use retail carrier list
```

---

## Shallow Clone

Các submodule được clone **shallow** (`--depth=1`) để tiết kiệm dung lượng và tốc độ. Khi cần full history:

```bash
cd src/<submodule>
git fetch --unshallow
```

---

## CI/CD Integration

Mỗi submodule có pipeline GitLab CI riêng (`.gitlab-ci.yml`). Meta-repo không có pipeline CI — chỉ dùng làm workspace.

| Stage | Trigger |
|-------|---------|
| `test` | Mỗi push lên feature branch |
| `build` | Merge vào `develop` |
| `deploy-staging` | Merge vào `develop` |
| `deploy-production` | Merge vào `main` (sau manual approval) |
