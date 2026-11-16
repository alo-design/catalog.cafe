# catalog.cafe

A coffee setup finder: pick a category, answer a few questions, and the catalog narrows to the gear that fits.

- `site/` is the website (plain HTML, CSS and JavaScript, no build step). Netlify publishes this folder.
- `site/config.js` holds the public Supabase URL and publishable key.
- `site/photos/` holds product photos with transparent backgrounds.
- `supabase/schema.sql` is the database setup: tables, access rules and the approve/reject functions.

## How it runs
- **Hosting:** Netlify project `catalog-cafe`, domain catalog.cafe.
- **Data:** Supabase project `catalog-cafe`. Tables `gear`, `beans`, `meta` are public read; `proposals` and `runs` are owner-only.
- **Owner sign-in:** catalog.cafe/#owner, by emailed link. Owner emails are listed in the `admin_emails` table.
- **Research agent:** a daily Claude scheduled task ("Catalog.cafe research") that files proposed catalog changes into `proposals` for review on the site.

## Publishing
Pushing to `main` publishes the `site/` folder to catalog.cafe through Netlify.
