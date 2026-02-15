You are given `design-system.json` and `component-blueprints.json`.
Apply these defaults even if the user does not explicitly request them:
1. Use only these two files as source of truth.
2. Never rename token keys.
3. Never silently create new tokens.
4. If a required token is missing, continue with best-effort component code and append a separate `Missing Token Report` section.

Implementation rules:
1. Resolve semantic token references first, then mode-specific mappings (`light`/`dark`), then emit classes.
2. Keep variant groups orthogonal; use `compoundVariants` only when interaction between variant axes is required.
3. Preserve accessibility constraints from each component blueprint (`a11y` block), including focus treatment and minimum target size.
4. Do not collapse status variants (`success`, `warning`, `danger`, `info`) into one generic style.

Return:
1. Component code
2. Variant usage examples
3. Missing Token Report (if any missing token exists)
