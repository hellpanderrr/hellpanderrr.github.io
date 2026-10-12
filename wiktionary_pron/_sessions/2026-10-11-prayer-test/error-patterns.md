# Our 647 misses on the full corpus, by cause (2026-10-12)

Source: `errors.csv` (73,755 tokens, non-words excluded) + `F:/temp/lea/review/candidates.mjs`,
which reruns each missed word through the engine in Node and asks whether any wordlist
reading, stressed by our own rule, gives the corpus accent.

| Cause | Tokens | Words | Examples | Fix | Effort | General or corpus-tuned |
|---|---:|---:|---|---|---|---|
| Capital-initial convention (Solesmes Option 2) | 264 | — | `Angelis` 46, `Etenim` 16, `Omnia` 14 | Don't write an acute on a capitalized first letter (option) | Easy (rule) | General (decision) |
| Not in the wordlist (Morpheus / ending guess) | 173 | 83 | `Ierúsalem` 56, `Iesse` 7, `Míchael`, `Ráphael`, `Andréas`, `Sínai`, `Móysi`, `Tobíam`; `propitiáberis`, `renováberis` | Accented proper-name lexicon: BrRoman/vulgate `vulgate_proper_names.txt` (3,233 names ≥3 syll., MIT) covers almost all names; ending-guess fix for `-āberis` | Medium | General (external list) |
| Right reading exists, engine picked another | 77 | 49 | `agámus`, `decóra`, `érue`, `irascéris`/`moréris`/`loquéris` (future passive), `Convértere`/`Avértere` (imperative), `pervénit`/`comédit`/`advénit` (perfect vs present) | Context-free overrides only where one reading dominates (`agámus`, `érue`, `solíus`, `estóte`, `Benedícam`); tense/mood cases need context | Hard (mostly) | Overrides are corpus-tuned |
| No reading gives the corpus accent | 57 | 36 | `Maríam` 15, `euge` 3, `Iona` 2, `Béniamin`, `Isaías`, `Tobíam`, `altérius`, `charismátum` | Exceptions (`Maríam`, `euge`, `Iona`), names via the lexicon; a few are corpus typos (`clarítate`, `Surgíte`) | Easy–medium | Partly corpus-tuned |
| Compound split by the tokenizer | 43 | 13 | `Verúmtamen` 13, `semetípsum` 8, `idípsum` 6, `seípsum` 4, `unusquísque` 4, `huiúsmodi` | Stress the rejoined word in the stress pass (parts' readings concatenated) | Easy (rule) | General |
| Books contradict themselves | 33 | — | `íllius`, `suavis`, `quórum` | none (no tool can match both) | — | — |

Not in the table: the page also showed a different word for 15 tokens (`Basan → Basa`,
`Hermon → Hermo`, `Mádian → Mádia`) where the engine output is right — fixed by having
the page display the engine's aligned text (M-032/M-036 root fix), which also keeps æ/œ
and all-caps words.

Caveat: anything tuned on this corpus (word-specific overrides, exceptions) inflates
the corpus score without proving generality. The general fixes (Option 2, compounds,
proper-name lexicon, page display) don't have that problem. The accented Vulgate in
the same repo is Collatinus-made, so it is not an independent test set.
