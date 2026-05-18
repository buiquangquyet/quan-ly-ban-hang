# Design System Review Checklist

> Reference cho code-reviewer agent khi review UI components (web + mobile).

---

## Token Compliance

| Check | What to Verify |
|-------|---------------|
| Colors | Component uses design tokens (e.g., `--color-primary`) not hardcoded hex |
| Typography | Font sizes, weights, line-heights from design system scale |
| Spacing | Margins, paddings use spacing scale (4px, 8px, 16px...) |
| Border radius | Consistent with design system tokens |
| Shadows | Use defined elevation levels |

## Component Patterns

| Check | What to Verify |
|-------|---------------|
| Existing components | Reuse existing components before creating new |
| Component API | Props/inputs match similar components in the system |
| Composition | Compose from primitives, don't duplicate |
| Responsive | Component works across breakpoints |

## Accessibility (a11y) Basics

| Check | What to Verify |
|-------|---------------|
| Semantic HTML | Use appropriate elements (button, nav, main, form) |
| ARIA labels | Interactive elements have accessible names |
| Keyboard | Tab order logical, focus visible, Enter/Space activate |
| Color contrast | Text meets WCAG AA (4.5:1 normal, 3:1 large) |
| Alt text | Images have descriptive alt attributes |

## Mobile-Specific (Flutter/React Native)

| Check | What to Verify |
|-------|---------------|
| Touch targets | Minimum 44x44dp tap area |
| Platform conventions | iOS/Android specific patterns respected |
| Safe area | Content respects device notches, status bars |
| Orientation | Landscape/portrait handled if applicable |

---

## How to Apply

Reviewer agent check these when:
- Task involves UI components (detected from file extensions: `.tsx`, `.vue`, `.dart`, `.component.ts`)
- Figma link was provided in design phase
- CLAUDE.md mentions a design system

Report findings as `[SUGGESTION]` unless breaking existing patterns → `[BLOCKING]`.
