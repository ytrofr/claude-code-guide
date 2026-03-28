---
paths:
  - "**/*.sh"
---

# Bash Filename Iteration — Never Word-Split

**Scope**: ALL bash scripts, hooks, and shell automation
**Authority**: MANDATORY — prevents broken output on filenames with spaces
**Evidence**: A hook script printed each word on a separate line because `for f in $RECENT` word-splits on spaces in filenames

---

## Core Rule

**Never use `for f in $VAR` to iterate over filenames. Always use `while IFS= read -r` with a pipe or process substitution.**

## Anti-Pattern

```bash
# WRONG — word-splits on spaces, globs on wildcards
FILES=$(find . -name "*.md")
for f in $FILES; do
    echo "$f"
done
```

## Correct Pattern

```bash
# CORRECT — handles spaces, special chars, newlines in paths
find . -name "*.md" | while IFS= read -r f; do
    echo "$f"
done

# OR with variable:
echo "$FILES" | while IFS= read -r f; do
    [ -n "$f" ] && echo "$f"
done
```

## When to Apply

- Any bash script iterating over file paths
- Hook scripts processing `find` or `ls` output
- Any variable that may contain filenames with spaces

---

**Last Updated**: 2026-03-24
