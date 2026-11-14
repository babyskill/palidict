MUSE_TASK_ID: palidict-20261114-phase1-build
REQUESTED_BY: Muse

# Build Brief — Pali-Viet Dictionary App, Phase 1 (MVP lookup app)

You are building a brand-new standalone Flutter app: an offline-first Pali-Vietnamese dictionary based on the Digital Pali Dictionary (DPD) data prepared by Muse. Work in this repo only. All code, comments, docs and commit messages in English. The app UI is localized through i18n from day one: Vietnamese (vi) is the first and default locale; NO user-facing string may be hardcoded in widgets — everything goes through the localization layer, structured so new locales are added later without code changes.

## Data (provided, do not rebuild)
Two SQLite files are placed in `data/` in this repo (copied by Muse before dispatch):
- `lite_final.db` (12.2 MB) — bundled with the app as an asset.
- `core_final.db.gz` (29 MB) — this is the downloadable Core pack content; the app downloads a file with exactly this content (for this phase, host it as a local file the app can fetch from a configurable URL constant; a debug menu may also side-load it from device storage).
Read `data/DATA_SPEC.md` (copied alongside) for the full schema: tables `headwords`, `lookup`, `roots`, `meaning_vi` (Vietnamese gloss per lemma, source Buu Chon 1976), `meaning_vi_senses` (Vietnamese gloss per sense entry, source phase1-draft). Join keys and search normalization rules are specified there — follow them exactly.

## Scope (MVP — nothing beyond this list)
1. **Search screen**: single search field. Accepts input with diacritics (dhammā), without diacritics (dhamma), and Velthuis (dhammaa, .m, "n). Live suggestions as the user types: exact/prefix matches on headwords first, then inflected-form matches via `lookup`. Tapping a suggestion opens the word card.
2. **Inflected-form lookup**: if the query matches `lookup.lookup_key`, open a results view listing the headwords it points to (with the grammar note from `lookup.grammar` when present), each opening its word card.
3. **Word card** (the core screen — layout follows the approved HTML prototype Muse provided):
   - Lemma (large), IPA if available in data, part of speech + grammar line.
   - Vietnamese meaning FIRST: `meaning_vi.gloss_main` with source label "HT Buu Chon (1976)"; if a sense has `meaning_vi_senses.vi_gloss`, show it at that sense with label "New translation — under review". Then the per-sense list: Vietnamese (when available) with the English `meaning_1` under it.
   - Grammar & construction block: root (`root_key` + root meaning from `roots`), `construction`, `phonetic`, Sanskrit equivalent when the column exists (Core only).
   - Example block: `example_1` with `source_1`/`sutta_1` citation (render `<b>` markup as highlight).
   - EBT frequency line (`ebt_count`).
   - Inflections: Core pack only — collapsible chip list from the `inflections` column. Lite cards show a note that full inflections come with the Core pack.
   - **Audio: male voice ONLY.** One listen button; plays `https://dpdict.net/audio/<lemma_clean, diacritics preserved, URL-encoded>?gender=male`. No female voice, no voice picker, no audio download/caching to disk (streaming playback only).
4. **Data packs**: Lite works fully offline out of the box. Settings/Packs screen: download Core (progress bar, cancel, delete pack), storage used shown. All queries transparently run against Core when present, else Lite.
5. **About screen**: attribution — Digital Pali Dictionary by Bhikkhu Bodhirasa (CC BY-NC-SA 4.0), Vietnamese layer from HT Buu Chon's Pali-Viet dictionary (1976) and new translations; non-commercial notice. This app must contain NO ads, NO in-app purchases, NO accounts, NO analytics/cloud calls (license requirement).

## Out of scope
No sutta reader, no SRS/flashcards/quiz, no deconstructor pack, no second UI language beyond the vi locale + en string table skeleton, no embedding into any other app.

## Technical constraints
- Flutter, offline-first; SQLite via drift or sqflite — read-only access to the provided DB files (copy Lite from assets to app docs dir on first run).
- Search normalization exactly as DATA_SPEC: ascii_fold = lowercase, strip combining marks (Mn), remove spaces; Velthuis conversion table for aa/ii/uu/.t/.d/.n/"n/~n/.m/.l.
- Keep DB access behind a repository layer keyed by meaning locale (meaning_vi today) so a future meaning_<lang> layer plugs in without schema change.

## Deliverables & gates
- Project scaffold + the 5 scope items above, unit tests for normalization (diacritics/plain/Velthuis equivalence classes) and for lookup resolution on 10 sample forms (incl. bhikkhunaṃ → bhikkhu, dhamma senses = 16 entries).
- When done: write `.agy/done/AGY_DONE_palidict-20261114-phase1-build.md` with: what was built, test results (command + counts), how to run, known gaps. STOP at that point — do not publish, do not submit to any store, do not merge anywhere (there is no upstream yet).
- If the provided DB files are missing from `data/` or their schema differs from DATA_SPEC, STOP and report in the DONE file instead of inventing a schema.
