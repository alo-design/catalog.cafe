# Working on Catalog Cafe (catalog.cafe)

- The site is plain HTML, CSS and JavaScript in `site/index.html`. There is no build step. Pushing to `main` publishes `site/` through Netlify.
- **Work on a branch, not `main`.** Each push to `main` is a production deploy and costs Netlify credits (15 each); deploy previews are free. Push changes to a branch and open a pull request: Netlify builds a deploy preview at `https://deploy-preview-<PR number>--catalog-cafe.netlify.app`. Share that link with Adrian, keep adding commits to the same branch while he reviews, and merge to `main` only when he says to publish.
- Data lives in Supabase (project `catalog-cafe`). The schema is in `supabase/schema.sql`. Never put secret keys in `site/`; only the publishable key belongs in `site/config.js`.

## Design rules

The source of truth is the catalog.cafe design system: https://claude.ai/artifact/Mmh2LT63kWUggRwJxB1RbB (read its `project/README.md` and `project/using-this-system.md`). The tokens at the top of `site/index.html` mirror it.

- Use semantic tokens only (`--text-primary`, `--surface-raised`, `--action-primary`, `--radius-control`, `--gap-controls`…). Never use a primitive (`--grey-*`, `--bronze-*`) or a literal colour, radius or shadow in a component rule.
- One typeface, two weights: Helvetica Neue Light (300) for headings, Regular (400) for everything else. Medium (500, `--font-weight-label`) only for news labels and the bento-title hover. No bold, no other fonts.
- The site's name is written “Catalog Cafe”, both words capitalised. The domain stays catalog.cafe.
- Black, white and grey. `--accent` is only for owner-only controls and data highlights. `--surface-highlight` (pale blue) is only for the news Summary box.
- News text never leaves one word alone on the last line: keep `text-wrap: pretty` and the `keepLast()` helper.
- Light theme only: there is no dark mode (product photos are shot for light backgrounds). Do not write theme-specific colours in components.
- If no token fits, add a semantic token to the design system first, then mirror it here.
- When a design decision changes, update the design system in the same piece of work.
