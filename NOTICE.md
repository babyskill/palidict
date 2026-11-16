# Notices — code license vs. data license

This repository contains two differently-licensed parts:

## 1. Application source code — MIT

The Flutter application source code (lib/, test/, platform folders, build
configuration) is licensed under the MIT License. See `LICENSE`.

## 2. Dictionary data — CC BY-NC-SA 4.0 (NOT covered by the MIT license)

The dictionary content is derived from the **Digital Pāḷi Dictionary (DPD)**
by Bhikkhu Bodhirasa and contributors:

- Project: https://github.com/digitalpalidictionary/dpd-db
- License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0
  International (CC BY-NC-SA 4.0)
  https://creativecommons.org/licenses/by-nc-sa/4.0/

This applies to:

- `data/lite_final.db` — the bundled Lite database in this repository
- the downloadable **Core pack** (`core_final.db`), distributed via the
  project's data mirrors (Cloudflare R2 and the `babyskill/suttacentral`
  GitHub repository)
- all headwords, definitions, roots and derived tables originating from DPD

If you reuse the data, you must comply with CC BY-NC-SA 4.0: attribution,
non-commercial use, and share-alike.

## 3. Vietnamese gloss layer

The Vietnamese meanings layer draws on the Pāḷi–Vietnamese dictionary
compiled by **Bửu Chơn**, with additional glosses translated and curated by
this project from DPD's English `meaning_1` field. Curated corrections are
marked in-app as "Đã hiệu đính" (edited/curated).

## 4. Pronunciation audio

Pronunciation audio is **not** included in this repository. The app streams
it directly from the DPD project's server (dpdict.net) at runtime.

## 5. Names

"Pāḷi Dictionary" / "Từ điển Pāḷi - Việt" is the name of this app.
DPD and Digital Pāḷi Dictionary are names of the upstream project.
