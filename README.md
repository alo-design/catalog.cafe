# Catalog Cafe

Catalog Cafe (catalog.cafe) is a coffee setup finder: pick a category, answer a few questions, and the catalog narrows to the gear that fits.

- `site/` is the website (plain HTML, CSS and JavaScript, no build step). Netlify publishes this folder.
- `site/config.js` holds the public Supabase URL and publishable key.
- `site/photos/` holds product photos with transparent backgrounds.
- `supabase/schema.sql` is the database setup: tables, access rules and the approve/reject functions.
- `supabase/news.sql` adds the `news` table and lets `apply_proposal` publish news drafts.

## How it runs
- **Hosting:** Netlify project `catalog-cafe`, domain catalog.cafe.
- **Data:** Supabase project `catalog-cafe`. Tables `gear`, `beans`, `meta` and `news` are public read; `proposals` and `runs` are owner-only.
- **Owner sign-in:** catalog.cafe/#owner, by emailed link. Owner emails are listed in the `admin_emails` table.
- **Research agent:** a daily Claude scheduled task ("Catalog.cafe research", 5:17 am Toronto) that files proposed catalog changes into `proposals` for review on the site, and drafts a news post (at most 2 a run) when it finds new gear.

## News
News posts are drafted into `proposals` with `collection: 'news'` (`doc_id` is the URL slug, `data` holds the article, `sources` the links). Signed in as the owner, drafts appear at the top of catalog.cafe/#news and in the review queue. Open one to preview it, then choose Publish or Reject. “Approve all” never publishes news.

Each post can carry `data.images` (`[{url, alt, caption?, credit}]`): the makers' own product photos. The first is the post's photo in the list and beside the headline; the rest go through the article, one after each paragraph. Photos from hosts listed in `netlify.toml` (`[images] remote_images`, mirrored in `IMG_HOSTS`) are resized by Netlify's image CDN; others load straight from the maker.

## Publishing
Pushing to `main` publishes the `site/` folder to catalog.cafe through Netlify.

## Design
The design rules (type, colour, spacing, layout) live in the catalog.cafe design system: https://claude.ai/artifact/Mmh2LT63kWUggRwJxB1RbB
One family, two weights: Helvetica Neue Light for headings, Regular for everything else (Medium only for news labels and the bento-title hover). Black, white and grey.
