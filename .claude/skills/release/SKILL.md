---
name: release
description: >-
  Release management — generate changelog từ conventional commits, bump version (CalVer YY.MM.N
  cho user-facing, SemVer cho internal libraries), tạo git tag, release notes cho developers
  và stakeholders. Trigger: "release", "tạo release", "bump version", "changelog",
  "release notes", "tag version", "cut release". Do NOT use for committing code (use commit),
  deploying to production (CI/CD handles), hoặc hotfix (use fix-bug first, then release).
argument-hint: "major/minor/patch" cho SemVer hoặc để trống cho CalVer auto
---

# Release Management

Generate changelog, bump version, tạo release notes từ conventional commits.

## Versioning Schemes

- **CalVer** (`YY.MM.N`): Cho user-facing projects. N = lần release trong tháng.
  - Ví dụ: `26.3.2` = lần release thứ 2 trong tháng 3 năm 2026
  - Detect: project có pattern CalVer trong git tags hoặc CLAUDE.md ghi rõ
- **SemVer** (`MAJOR.MINOR.PATCH`): Cho internal libraries.
  - Detect: package.json version, .csproj Version, hoặc CLAUDE.md ghi rõ

---

## Bước 1: Detect Version Scheme + Current Version

**Actions**:
1. Check CLAUDE.md cho versioning convention
2. Check git tags: `git tag --sort=-v:refname | head -5`
3. Check package files: package.json, *.csproj, pubspec.yaml
4. Detect scheme:
   - Tags match `YY.MM.N` pattern → CalVer
   - Tags match `vX.Y.Z` hoặc `X.Y.Z` pattern → SemVer
   - Không rõ → hỏi user
5. Report: current version, scheme, last release date

---

## Bước 2: Generate Changelog

**Actions**:
1. Get commits since last release tag:
   ```
   git log {last-tag}..HEAD --format="%h %s" --no-merges
   ```
2. Parse conventional commits → group by type:

   ```markdown
   ## What's New
   ### Features
   - **sales**: add revenue export to Excel (#KV-100)
   - **inventory**: stock transfer between branches (#KV-200)

   ### Bug Fixes
   - **auth**: fix token refresh race condition (#KV-150)

   ### Performance
   - **reports**: optimize dashboard query 3x faster

   ### Breaking Changes
   - **api**: remove deprecated /v1/products endpoint
   ```

3. Nếu có JIRA integration → link ticket IDs to JIRA URLs
4. Present changelog cho user review

---

## Bước 3: Bump Version

**Actions** (sau user approve changelog):

### CalVer (`YY.MM.N`):
1. Get current year + month: `YY.MM`
2. Count existing releases this month: `git tag -l "YY.MM.*" | wc -l`
3. New version: `YY.MM.{count + 1}`
4. Update version in relevant files (package.json, .csproj, etc.)

### SemVer:
1. Determine bump type từ commits:
   - `feat` → minor
   - `fix` → patch
   - `BREAKING CHANGE` hoặc `!` → major
   - User có thể override: `/release major`
2. Bump version in relevant files
3. Report: `{old_version} → {new_version}`

---

## Bước 4: Create Release

**Actions**:
1. Create annotated git tag:
   ```
   git tag -a {version} -m "Release {version}"
   ```
2. Generate release notes (2 versions):
   - **Technical** (cho developers): full changelog
   - **Stakeholder** (cho PO/PM): features + fixes summary, business impact
3. Write to `CHANGELOG.md` (prepend new version section)
4. Commit version bump + changelog: `chore(release): {version}`
5. Nếu Atlassian MCP available → tạo Confluence release notes page
6. Nếu JIRA tickets in changelog → dùng `transitionJiraIssue` chuyển sang Done (nếu chưa)

**Không tự push** — user quyết định khi nào push tag + commits.

---

## Examples

**Example 1: CalVer release**
User says: "/release"
Actions:
1. Detect CalVer, last tag: 26.3.1
2. Parse 5 commits: 2 feat, 1 fix, 2 chore
3. Generate changelog
4. New version: 26.3.2
5. Tag + changelog + commit
Result: `26.3.2` tagged, CHANGELOG.md updated

**Example 2: SemVer library release**
User says: "/release minor"
Actions:
1. Detect SemVer, current: 2.1.3
2. User specified minor → 2.2.0
3. Update package.json version
4. Generate changelog
5. Tag + commit
Result: `v2.2.0` tagged, package.json updated

**Example 3: With JIRA**
User says: "/release"
Actions: Changelog includes KV-100, KV-150 → transition both to Done on JIRA
Result: Release + JIRA cleanup

---

## Troubleshooting

**No conventional commits**: Parse best-effort, warn user about commit convention
**No previous tag**: Treat all commits as first release, suggest version `1.0.0` (SemVer) hoặc `YY.MM.1` (CalVer)
**Version conflict in files**: Show which files have version, let user choose which to update
