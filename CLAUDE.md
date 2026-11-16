# Working on catalog.cafe

- The site is plain HTML, CSS and JavaScript in `site/index.html`. There is no build step. Pushing to `main` publishes `site/` through Netlify.
- Data lives in Supabase (project `catalog-cafe`). The schema is in `supabase/schema.sql`. Never put secret keys in `site/`; only the publishable key belongs in `site/config.js`.

## Design rules

The source of truth is the catalog.cafe design system: https://claude.ai/artifact/Mmh2LT63kWUggRwJxB1RbB (read its `project/README.md` and `project/using-this-system.md`). The tokens at the top of `site/index.html` mirror it.

- Use semantic tokens only (`--text-primary`, `--surface-raised`, `--action-primary`, `--radius-control`, `--gap-controls`…). Never use a primitive (`--grey-*`, `--bronze-*`) or a literal colour, radius or shadow in a component rule.
- One typeface, two weights: Helvetica Neue Light (300) for headings, Regular (400) for everything else. No bold, no other fonts.
- Black, white and grey. `--accent` is only for owner-only controls and data highlights.
- Both themes come from the tokens. Do not write theme-specific colours in components.
- If no token fits, add a semantic token to the design system first, then mirror it here.
- When a design decision changes, update the design system in the same piece of work.
