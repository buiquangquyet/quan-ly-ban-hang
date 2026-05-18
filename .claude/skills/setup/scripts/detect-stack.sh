#!/usr/bin/env bash
# detect-stack.sh
# Auto-detect language stack của project hiện tại
# Output: JSON array of detected languages

DETECTED=()
ROOT="${1:-.}"  # default current dir

# ── C# / .NET ──────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "*.csproj" -o -name "*.sln" -o -name "*.fsproj" \) 2>/dev/null | grep -q .; then
  DETECTED+=("csharp")
fi

# ── TypeScript / JavaScript ────────────────────────────────
if find "$ROOT" -maxdepth 3 -name "tsconfig.json" 2>/dev/null | grep -q .; then
  DETECTED+=("typescript")
elif find "$ROOT" -maxdepth 2 -name "package.json" -not -path "*/node_modules/*" -exec grep -l '"typescript"' {} + 2>/dev/null | grep -q .; then
  DETECTED+=("typescript")
elif find "$ROOT" -maxdepth 2 -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
  DETECTED+=("javascript")
fi

# ── Go ─────────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 -name "go.mod" 2>/dev/null | grep -q .; then
  DETECTED+=("go")
fi

# ── PHP ────────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "composer.json" -o -name "artisan" \) 2>/dev/null | grep -q .; then
  DETECTED+=("php")
fi

# ── Python ─────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "requirements.txt" -o -name "pyproject.toml" -o -name "setup.py" -o -name "Pipfile" \) 2>/dev/null | grep -q .; then
  DETECTED+=("python")
fi

# ── Java ───────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "pom.xml" -o -name "build.gradle" -o -name "build.gradle.kts" \) 2>/dev/null | grep -q .; then
  DETECTED+=("java")
fi

# ── Kotlin ─────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "*.kt" -o -name "build.gradle.kts" \) 2>/dev/null | grep -q .; then
  DETECTED+=("kotlin")
fi

# ── Rust ───────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 -name "Cargo.toml" 2>/dev/null | grep -q .; then
  DETECTED+=("rust")
fi

# ── Ruby ───────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 -name "Gemfile" 2>/dev/null | grep -q .; then
  DETECTED+=("ruby")
fi

# ── C / C++ ───────────────────────────────────────────────
# CMakeLists.txt hoặc source files là strong indicators
# Makefile alone quá generic (Go, Python cũng có) → không dùng standalone
if find "$ROOT" -maxdepth 3 \( -name "CMakeLists.txt" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" \) 2>/dev/null | grep -q .; then
  DETECTED+=("cpp")
fi

# ── Swift ─────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "Package.swift" -o -name "*.xcodeproj" \) 2>/dev/null | grep -q .; then
  DETECTED+=("swift")
fi

# ── Dart / Flutter ────────────────────────────────────────
if find "$ROOT" -maxdepth 3 -name "pubspec.yaml" 2>/dev/null | grep -q .; then
  DETECTED+=("dart")
fi

# ── Lua ───────────────────────────────────────────────────
if find "$ROOT" -maxdepth 3 \( -name "*.lua" -o -name ".luarc.json" \) 2>/dev/null | grep -q .; then
  DETECTED+=("lua")
fi

# ── Git submodules ─────────────────────────────────────────
SUBMODULES=()
if [ -f "$ROOT/.gitmodules" ]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.+)$ ]]; then
      SUBMODULES+=("${BASH_REMATCH[1]// /}")
    fi
  done < "$ROOT/.gitmodules"
fi

# ── Output JSON ────────────────────────────────────────────
printf '{\n'
printf '  "languages": ['
for i in "${!DETECTED[@]}"; do
  [ $i -gt 0 ] && printf ','
  printf '"%s"' "${DETECTED[$i]}"
done
printf '],\n'

printf '  "submodules": ['
for i in "${!SUBMODULES[@]}"; do
  [ $i -gt 0 ] && printf ','
  printf '"%s"' "${SUBMODULES[$i]}"
done
printf '],\n'

printf '  "is_monorepo": '
CSPROJ_COUNT=$(find "$ROOT" -maxdepth 4 -name "*.csproj" 2>/dev/null | wc -l | tr -d ' ')
GOMOD_COUNT=$(find "$ROOT" -maxdepth 4 -name "go.mod" 2>/dev/null | wc -l | tr -d ' ')
PKG_COUNT=$(find "$ROOT" -maxdepth 3 -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
HAS_WORKSPACES=false
if [ -f "$ROOT/pnpm-workspace.yaml" ] || [ -f "$ROOT/lerna.json" ]; then
  HAS_WORKSPACES=true
elif [ -f "$ROOT/package.json" ] && grep -q '"workspaces"' "$ROOT/package.json" 2>/dev/null; then
  HAS_WORKSPACES=true
fi
if [ "$CSPROJ_COUNT" -gt 1 ] || [ "$GOMOD_COUNT" -gt 1 ] || [ "$PKG_COUNT" -gt 2 ] || [ "$HAS_WORKSPACES" = true ]; then
  printf 'true'
else
  printf 'false'
fi
printf '\n}\n'
