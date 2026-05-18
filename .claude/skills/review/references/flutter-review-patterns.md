# Flutter & Mobile Review Patterns

> Anti-patterns cần flag khi review Flutter/Dart code. Thêm patterns mới vào đây.

---

## Mobile (General)

- Handles app lifecycle events (background/foreground, termination)
- Tránh blocking main/UI thread cho I/O hoặc heavy work
- Handles offline/poor network conditions gracefully
- Respects platform permissions và privacy prompts
- Optimizes image/video loading và caching
- Tránh excessive memory usage (large bitmaps, retained views)
- Battery và network usage reasonable
- Analytics/logging không leak PII

---

## Flutter — Flag khi thấy

| Anti-pattern | Correct pattern |
|---|---|
| Missing `const` trên widgets | `const` wherever possible — giảm rebuilds |
| `setState` không guard `mounted` | `if (mounted) setState(...)` |
| Expensive work trong `build()` | Move to initState hoặc separate method |
| `print()` statements | `dart:developer` `log` hoặc `debugPrint` |
| Missing dispose cho controllers | `TextEditingController` / `FocusNode` / `AnimationController` phải dispose |
| Missing dispose cho streams | `Stream` / `Future` / `Controller` subscriptions phải cancel/dispose |
| `ListView()` without builder | `ListView.builder()` cho long lists |
| `!` (null assertion) without guarantee | Prefer null-safe patterns, `!` chỉ khi safety guaranteed |

---

## State Management

- Consistent với app conventions (Riverpod/Bloc/GetX — theo project)
- `BuildContext` usage safe — no async gaps after dispose
- Avoid rebuilding expensive widgets without `const`/`keys`
- `SizedBox` / `Expanded` / `Flexible` appropriate — tránh layout thrash

---

## Performance

- `compute()` / isolates cho heavy work
- Platform channels handle errors và threading correctly
- `ListView` / `GridView` dùng builders và proper keys
- Lazy loading cho heavy assets

---

## Dart (General)

- Prefer concise, declarative code và immutability
- `Future` / `async` / `await` cho async work, `Stream` cho events
- Enforce `flutter_lints` và `dart format`
