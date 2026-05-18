# Figma Design Workflow

Quy trình phân tích Figma design và translate thành code — áp dụng cho mọi frontend stack (Angular, Flutter, React, mobile, web).

---

## 1. Lấy Design

### Có Figma
Dùng Figma MCP lấy design specs: layout, spacing, colors, typography, responsive breakpoints.

### Không có Figma — Fallback
Hỏi user cung cấp (theo thứ tự ưu tiên):
1. **Screenshot/mockup** — bất kỳ visual reference nào
2. **Wireframe description** — mô tả layout bằng text
3. **Reference page** — trang existing trong app để tham khảo
4. **Acceptance criteria** — behavioral requirements

Flag mọi design assumptions trong REVIEW phase.

---

## 2. Design Analysis Checklist

Extract từ Figma design:

### Layout
- Layout pattern (flex row/column, grid, sidebar + content)
- Container widths, spacing between sections
- Alignment rules, overflow behavior

### Typography
- Font family, sizes (heading/body/caption/label), weights
- Line heights, letter spacing (nếu non-default)
- Text color variations (primary, secondary, muted, error)

### Colors
- Primary, secondary, accent, background, border colors
- Status colors (success, warning, error, info)
- **Map vào design tokens/variables hiện có trong project**

### Spacing
- Spacing scale (4px, 8px, 16px, 24px...)
- Padding inside components, margin between components, gap

### Responsive / Adaptive
- Mobile (< 768px), Tablet (768-1024px), Desktop (> 1024px)
- Thay đổi gì giữa breakpoints (column stacking, hidden elements, font sizes)
- Với mobile app: orientation, safe areas, notch handling

### Interactive States
Default, hover, focus, active/pressed, disabled, loading, error, empty

### Animations
Entry/exit, hover transitions, loading (skeleton/spinner), page transitions

---

## 3. Component Decomposition

Break design thành components theo atomic design:

### Step 1: Atoms
Buttons, inputs, labels, icons, badges, avatars
→ Check đã có trong project chưa (UI library, shared components)

### Step 2: Molecules
Form fields (label + input + error), card, list item, search bar
→ Check shared components có thể reuse

### Step 3: Organisms
Form sections, data tables, navigation, header, sidebar
→ Thường feature-specific

### Step 4: Pages/Screens
Full page layouts combining organisms — smart components quản lý state và data flow

### Decomposition Output
```
Page/Screen: [Name]
├── [Organism] — [responsibility]
│   ├── [Molecule] — [responsibility]
│   │   ├── [Atom] — existing ✅ / new 🆕
│   │   └── [Atom] — existing ✅ / new 🆕
│   └── [Molecule] — [responsibility]
└── [Organism] — [responsibility]
```

---

## 4. Design-to-Code Mapping

Map Figma values vào project's design system:

| Figma Property | Map vào |
|---------------|---------|
| Colors | Design tokens, CSS variables, theme colors |
| Spacing | Spacing scale (CSS/Tailwind classes, EdgeInsets, etc.) |
| Typography | Text styles, theme typography, mixins |
| Breakpoints | Media queries, responsive utilities, LayoutBuilder |
| Icons | Project icon system (icon font, SVG, Material icons) |
| Shadows/Radius | Elevation tokens, border-radius variables |

**Nguyên tắc**: Luôn map vào tokens/variables hiện có. Chỉ tạo mới khi không có equivalent.

---

## 5. Post-Implementation Review

Verify implementation vs design:

### Visual
- [ ] Layout matches design structure
- [ ] Spacing, typography, colors consistent
- [ ] Border radius, shadows, icons correct

### Responsive/Adaptive
- [ ] Mobile, tablet, desktop layouts match
- [ ] Transitions giữa breakpoints smooth

### States & Interactions
- [ ] Hover, focus, disabled, loading, error states match
- [ ] Animations/transitions match

### Edge Cases
- [ ] Long text (truncation, wrapping)
- [ ] Missing/null data, empty lists
- [ ] Single item vs many items, scroll behavior

### Accessibility
- [ ] Semantic markup (headings, landmarks, labels)
- [ ] Keyboard navigation works
- [ ] Color contrast WCAG AA (4.5:1 for text)
- [ ] Focus indicators visible
