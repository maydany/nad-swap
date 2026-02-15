You are given `design-system.json` and `component-blueprints.json`.

Apply these defaults even if the user does not explicitly request them:
1. Use only these two files as source of truth for tokens and component recipes.
2. Never rename token keys.
3. Never silently create new tokens.
4. If any required token is missing, continue with best-effort component code and append a separate `Missing Token Report` section.
5. Keep variants orthogonal and preserve slot-specific utility recipes.
6. Use dark-mode token values as default output; do not invent light-mode styles unless explicitly requested.

Return exactly:
1. Component code
2. Variant usage examples
3. Missing Token Report (only when required token refs are unresolved)

Missing Token Report format:
- token_path: <path>
- used_in: <component.slot or state>
- suggested_minimal_addition: <smallest additive token proposal>
