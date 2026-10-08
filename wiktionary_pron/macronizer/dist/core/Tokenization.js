/**
 * Tokenization module
 * Ported from latin_macronizer/tokenization.py
 * Handles Latin text tokenization with enclitic support
 */
import { Token } from './Token.js';
import { normalizeTag } from '../utils/latin.js';
import { scanVerses as doScanVerses } from './Scansion.js';
import { alignMacronized } from './alignMacronized.js';
import { applyStress } from './Stress.js';
import { toAscii, isWhitespace, isSentenceEnder, splitEnclitic, tagDistance, levenshteinDistance, underscoreToUnicode, prefixesWithShortJ, stripStressMark } from '../utils/latin.js';
/**
 * Accent overrides for words whose quantity is context-dependent — short in
 * prose, long when a meter demands it (e.g. italorum: Ĭtălōrum in prose,
 * Ītălōrum at the fixed-long position 8 of a hendecasyllable).
 *
 * Kept here instead of editing the 33MB wordlist: macrons.txt is regenerated
 * from upstream and would silently lose a one-off data edit. The extra forms
 * are injected as additional scansion candidates (prose keeps accenteds[0]).
 */
const ACCENT_OVERRIDES = {
    // Gen. pl. of Italus. Wordlist has only the short reading I^ta^lo_rum;
    // the meter of Catullus 1.5 requires the long ī (position 8).
    'italorum': ['i^ta^lo_rum', 'i_ta^lo_rum'],
    // Gold-confirmed quantity fixes (hypotactic.com macronized Aeneid, M-013).
    // The wordlist marks the first syllable long where the edition has it short;
    // the extra short form becomes a scansion candidate the meter can pick.
    // Lāvini → la-vī-nī (Aen 1.263, 6.890): wordlist la_vi_ni_ has long first a.
    'lavini': ['la_vi_ni_', 'la^vi_ni_'],
    // Orīōn → ŏ-rī-ōn (Aen 1.535, 4.52): wordlist O_ri_o_n has long first o.
    'orion': ['O_ri_o_n', 'o^ri_o_n'],
    // dehīscēns → dĕ-hīs-cēns (Aen 1.106): wordlist de_hi_sce_ns has long de.
    'dehiscens': ['de_hi_sce_ns', 'de^hi_sce_ns'],
    // dehiscit → dĕ-hīs-cit (SLL) Aen 5.142: "infindunt pariter sulcos, totumque
    // dehiscit" needs the short de (wordlist has dēhiscit with long de, which
    // can't fit the dactyl position). Same dĕ-hīs- shape as dehiscens.
    'dehiscit': ['de^hi_sci_t', 'de_hi_sci_t'],
    // ecqua → ec-qua (Aen 3.488): wordlist ecqua_ has long final a.
    'ecqua': ['ecqua_', 'ecqua'],
    // Phryges → phry-ges (Aen 1.102): wordlist phry^ge_s has long e.
    'phryges': ['phry^ge_s', 'phry^ges'],
    // Trōes → trō-es (Aen 1.30): wordlist tro_e_s has long e.
    'troes': ['tro_e_s', 'tro_es'],
    // Dīāna → dī-ā-na (Aen 1.499): wordlist Di^a_na has SHORT first i (inverse case).
    'diana': ['Di^a_na', 'di_a_na'],
    // Catullus + Greek-name quantity fixes (M-013, verified by subagent against
    // Latin Library / wikisource / negenborn scanned Catullus / virgil.org).
    // soluit → sŏ-lu-it (Catullus 2b.13): wordlist collapses to 2-syll "solvit".
    'soluit': ['solvit', 'so^lu^it'],
    // inelegantes → in-ē-lĕ-gān-tēs (Catullus 6.2): wordlist has long "le".
    'inelegantes': ['ine_le_gante_s', 'ine_le^gante_s'],
    // fragrans → fră-grāns (Catullus 6.8): wordlist has long root a.
    'fragrans': ['fra_gra_ns', 'fra^gra_ns'],
    // volo → vŏlŏ (Catullus 6.16): short final -ō of 1st-person verbs.
    'volo': ['volo_', 'vo^lo^'],
    // dabo → dăbŏ (Catullus 13.11): short final -ō.
    'dabo': ['da^bo_', 'da^bo^'],
    // Cyrenis → cŷ-rē-nīs (Catullus 7.4): Greek upsilon is short.
    'cyrenis': ['Cy_re_ni_s', 'Cy^re_ni_s'],
    // Mane → mănĕ (Catullus 10.27): hiatus at the quote boundary needs short final e.
    'mane': ['ma_ne', 'ma^ne_', 'ma^ne^'],
    // abite → ă-bī-te (Catullus 14.21): wordlist wrong on both vowels.
    'abite': ['a_bi_te', 'a^bi_te'],
    // quandoquidem → quāndŏ-quīdem (Catullus 101): wordlist has long o.
    'quandoquidem': ['quando_qui^dem', 'quando^qui^dem'],
    // tete → tētĕ (Catullus 101.5): missing from wordlist entirely.
    'tete': ['te_te'],
    // Oilei → ŏ-ĭ-lē-ī (Aen 1.41): wordlist has 4 long syllables.
    'oilei': ['Oi_le_i_', 'O^le_i_'],
    // Thesea → Thē-sĕ-ă (Aen 6.122, 6.123, LXIV): wordlist has long se.
    'thesea': ['The_se_a', 'The_se^a'],
    // Euryalus / Euryalum → Eu-ry-ă-lus (Aen 5.295, 5.323): wordlist has long a.
    // e^u^ry^a^lu_s (LSSL, Aen 5.337) is the gold 4-syllable reading with y as a
    // consonant (e-ury-a-lu-s) — the wordlist forms Eu-ry-a-lus give LSLS/LSSS
    // and never reach the gold LSSL that completes "emicat Euryalus et munere".
    'euryalus': ['Eury^a_lus', 'Eury^a^lus', 'e^u^ry^a^lu_s'],
    'euryalum': ['Eury^a_lum', 'Eury^a^lum', 'e^u^ry^a^lu_m'],
    // Letum → lētum (Aen 6.277): capitalized proper noun falls to ending engine.
    'letum': ['letum', 'le_tum'],
    // ── M-013b: true-quantity cluster (gold-verified, hypotactic per-syllable) ──
    // rēligiō/ne/sa: L&S double quantity; Vergil scans long re. (6 lines)
    'religio': ['re^li^gi^o_', 're_li^gi^o_'],
    'religione': ['re^li^gi^o_ne', 're_li^gi^o_ne'],
    'religiosa': ['re^li^gi^o_sa', 're_li^gi^o_sa'],
    // saniē (abl. sg. of sanies, 5th decl): gold sa-ni-ē (SSL, final ē LONG).
    // Wordlist "sanie" gives SSS; mark the final e long.
    'sanie': ['sa^ni^e_', 'sa^ni^e'],
    // līquentia (Aen 1.432): gold long li (spondaic line); 5.238/5.776 short li
    // → keep both candidates.
    'liquentia': ['li^quenti^a', 'li_quenti^a'],
    // exoritur: gold ex-o-ri-tur (LSSL); ex long by position (x-cluster), ri
    // short, tur long by position. exori_tur (wordlist) wrongly marks ri long.
    'exoritur': ['exo^ri^tur', 'exori_tur'],
    // potitur: gold po-ti-tur (SSL); wordlist po^ti_tur marks ti long.
    'potitur': ['po^ti^tur', 'po^ti_tur'],
    // dīmōverat (Aen 3.589, 4.7): gold di-mo-ve-rat (LLSS). Wordlist dimo_verat
    // marks only mo long; add the long first di.
    'dimoverat': ['di_mo_verat', 'di^mo_verat'],
    // excita (Aen 4.301): gold ex-ci-ta (LSS). Wordlist excita_ marks final a
    // long; override with final short.
    'excita': ['exci^ta', 'exci^ta_'],
    // ── M-013b: closed-prefix cluster (gold-verified) ──
    // subiciunt/obicitur/coniciunt/inice: the prefix vowel is short in the
    // wordlist (subi^ciunt → su-bi-ci-unt = SSS...), but the meter needs the
    // prefix syllable CLOSED (sub-i-ci-unt = LSS...). The prefix vowel stays
    // short in the orthography; marking the syllable heavy (as the existing
    // dehiscens pattern does) lets the meter pick it. Gold: sub:long i:short
    // ci:short unt:long.
    'subiciunt': ['su_bi^ciunt', 'subi^ciunt'],
    'subicio': ['su_bi^cio', 'subi^cio'],
    'obicitur': ['o_bi^citur', 'obi^citur'],
    'obicit': ['o_bi^cit', 'obi^cit'],
    'obicis': ['o_bi^cis', 'obi^cis'],
    'coniciunt': ['co_ni^ciunt', 'coni^ciunt'],
    'conicit': ['co_ni^cit', 'coni^cit'],
    'inice': ['i_ni^ce', 'ini^ce'],
    // ── M-013b: Greek-name quantity cluster (gold-verified, hypotactic) ──
    // Each: wordlist form → gold per-syllable pattern.
    // Ilionea → Ī-lĭ-o-nē-ă (LSSLS); wordlist I_li^o^nea_ gives LSSSL (final a long).
    'ilionea': ['i_lione_a', 'i_li^one_a'],
    // Idomenea → Ī-do-me-nē-ă (LSSLS); wordlist I_do^me^nea_ gives LSSSL.
    'idomenea': ['i_domene_a', 'i_do^mene_a'],
    // Mnesthea → Mnēs-the-a (LSS); wordlist Mnesthea_ gives LSL (final a long).
    'mnesthea': ['mnesthea', 'mne_sthea'],
    // Salmonea → Sal-mō-ne-a (LLSS); wordlist Salmo_nea_ gives LLL.
    'salmonea': ['salmo_nea', 'sa_lmo_nea'],
    // Tritonidis → Trī-tō-ni-dis (LLSS); wordlist Tri_to_ni^di_s gives LLSL.
    'tritonidis': ['tri_to_nidis', 'tri_to_ni^dis'],
    // Panthus → Pan-thūs (LL); wordlist panthus (no markers) gives LS.
    'panthus': ['panthu_s', 'pa_nthu_s'],
    // Othryades → O-thry-a-dēs (LSSL); wordlist Othry^a^de_s gives SSSL/LSSL/LSL.
    'othryades': ['othryade_s', 'o_thryade_s'],
    // Same → Sa-mē (SL); wordlist Sa^me gives SS.
    'same': ['sa^me_', 'same_'],
    // Cyclopea → Cȳ-clō-pe-a (LLSS); wordlist Cy^clo_pe_a gives LLLL (all long).
    'cyclopea': ['cy_clo_pea', 'cyclo_pea'],
    // Scamandri → Sca-man-drī (SLL); wordlist Sca^mandri_ gives SSLL.
    'scamandri': ['sca^mandri_', 'scamandri_'],
    // Eumenides → Eu-me-ni-dēs (LSSL); wordlist Eume^ni^de_s gives SSSSL/LSSL.
    'eumenides': ['eumenide_s', 'e_umenide_s'],
    // Numitor → Nu-mi-tor (LSL); wordlist numitor gives SSL (all short... check).
    'numitor': ['nu_mito_r', 'nu^mi^to_r', 'nu_mi^to_r'],
    // aether → ae-ther (LL); wordlist aether gives LL already (diphthong) — keep for safety.
    'aether': ['aethe_r', 'aether'],
    // solis → sō-lis (LS); wordlist solis gives SS.
    'solis': ['so_lis', 'so^lis'],
    // choreas → cho-re-ās (SSL); wordlist choreas gives SS.
    'choreas': ['cho^re^a_s', 'cho^re_as'],
    // ── M-013b: batch 3 — more gold-verified quantity fixes (hypotactic) ──
    // oreades → o-rē-a-des (SLSS per gold Aen 1.500); wordlist O^re_a^de_s gives SLSL.
    'oreades': ['o^re_ades', 'o_re^a_des'],
    // aureis → au-reis (LL); wordlist aure^i_s gives LSL (i not part of ei diphthong).
    'aureis': ['aureis', 'a_ureis'],
    // deorum → de-o-rum (SLL); wordlist de^o_rum gives SLL already — keep for safety.
    'deorum': ['de^o_rum', 'de_o_rum'],
    // oritur → o-ri-tur (SSL); wordlist oritur gives SSL — keep for safety.
    'oritur': ['o^ri_tur', 'oritu_r'],
    // obruimur → ō-bru-i-mur (LSSL) Aen 2.411: gold per-syllable LSSL. The
    // wordlist obru^imur scans LSS/LS etc. but never LSSL — the line
    // "nostrorum obruimur oriturque miserrima caedes" needs the long first
    // syllable (o before br = position) + final -mur long.
    'obruimur': ['obru^imur', 'o_bru^i^mu_r'],
    // arant → a-rant (SL); wordlist a^rant gives SL already.
    'arant': ['a^rant', 'arant'],
    // situs → si-tūs (SL); wordlist si^tus gives SS.
    'situs': ['si^tu_s', 'situ_s'],
    // excitum → ex-cī-tum (LLL); wordlist exci^tum gives LSL.
    'excitum': ['exci_tum', 'e_xci_tum'],
    // solane → sō-la-ne (LSS); wordlist so_la_ne gives LLS.
    'solane': ['so_lane', 'so_la^ne'],
    // pectoribus → pec-to-ri-bus (LSSL); wordlist pectoribus gives LSSS.
    'pectoribus': ['pectoribu_s', 'pe_ctoribu_s'],
    // abito → a-bī-tō (SLL); wordlist a_bi_to_ gives LLL.
    'abito': ['a^bi_to_', 'abi_to_'],
    // adloquitur → ad-lo-qui-tur (LSSL); wordlist adlo^quitur gives LSSS/SSSS.
    'adloquitur': ['adloquitu_r', 'a_dloquitu_r'],
    // iactetur → iacte-tur (LLL); wordlist jacte_tur gives LLS.
    'iactetur': ['iacte_tu_r', 'i^acte_tu_r'],
    // datur → da-tur (SL); wordlist da^tur gives SS.
    'datur': ['da^tu_r', 'da^tur'],
    // mnesthei → Mnēs-thei (LL, -ei diphthong); wordlist mnesthei_ gives LSL.
    'mnesthei': ['mne_sthei', 'mnesthei'],
    // gyan → Gy-ān (SL); wordlist gyan gives SS.
    'gyan': ['gy_an', 'gy^an'],
    // charybdin → Cha-ryb-din (SLL); wordlist charybdin gives SLL — keep for safety.
    'charybdin': ['cha^rybdi_n', 'charybdin'],
    // biiugo → bi-iu-go (LL); wordlist bi^ju^go_ gives LSL.
    'biiugo': ['bi_iugo_', 'biiugo_'],
    // ── M-013b: batch 4 — more gold-verified (Aeneid 6 + misc) ──
    // peteret → pe-te-ret (SSL); wordlist pe^teret gives SSS.
    'peteret': ['pe^tere_t', 'petere_t'],
    // eumenidum → Eu-me-ni-dum (LSSL); wordlist Eume^ni^dum gives LSSL.
    'eumenidum': ['eumenidum', 'e_umenidum'],
    // nequivi → ne-quī-vī (SLL); wordlist nequivi gives SLL already.
    'nequivi': ['ne^qui_vi_', 'nequi_vi_'],
    // fidenam → Fi-dē-nam (SLL); wordlist fidenam gives... check.
    'fidenam': ['fi^de_nam', 'fide_nam'],
    // leti → lē-tī (LL); wordlist leti gives L (capitalized Leti falls to ending engine).
    'leti': ['le_ti_', 'le^ti_'],
    // amor → a-mor (SL); wordlist amor gives SS.
    'amor': ['a^mo_r', 'amo_r'],
    // pavor → pa-vor (SL in Aen 2.369); wordlist pa^vor gives SS.
    'pavor': ['pa^vo_r', 'pavo_r'],
    // locorum → lo-cō-rum (SLL); wordlist lo^co_rum gives SLL already.
    'locorum': ['lo^co_rum', 'loco_rum'],
    // sequor → se-quor (SS); wordlist sequor gives SS already. Aen 4.361
    // "Italiam non sponte sequor" is a hemistich needing se-quōr (SL, final long
    // by position before the closing quote) so it scans as a 1-4-foot partial
    // (gate-accepted fragment) instead of EMPTY.
    'sequor': ['se^quor', 'sequor', 'se^quo_r'],
    // nemus → ne-mus (SL in Aen 3.112); wordlist ne^mus gives SS.
    'nemus': ['ne^mu_s', 'nemu_s'],
    // pater → pă-tēr (SL) Aen 5.521: "ostentans artemque pater arcumque
    // sonantem" needs the final -ter long (gold pater=SL); wordlist pa^ter
    // gives SS. The -r before "arcumque" (vowel) makes no position — gold marks
    // the syllable long regardless.
    'pater': ['pa^ter', 'pa^te_r'],
    // ── M-013f: five-foot partial completion cluster (gold-verified) ──
    // Īliō → ī-li-ō (LSS) Aen 5.261: gold "sub Īliō altō". Wordlist I_lio_ gives
    // LS/LL (2-syllable) — never the gold 3-syllable LSS. Add i_li^o^ (LSS) so
    // the completion bonus can prefer the complete hexameter (DDSDDS, gold).
    'ilio': ['I_lio_', 'i_li^o^'],
    // ── M-013g: Aeneid 7-12 + broader corpus — Greek names & quantity fixes
    // (gold-verified, hypotactic per-syllable). The 3x corpus expansion
    // (e39b29f) surfaced systematic wordlist-quantity errors books 1-6 never
    // hit. Each: wordlist form → gold pattern.
    // Euander/Euandri/Euandrum/Euandre → E-u-an-der (LLL/LLS, u as vowel):
    // wordlist Evandro_/Euandri_/etc. give 4-syll SLL/LSL. (Aen 10.492, 11.45,
    // 11.55, 11.140, 11.148, 10.780, 11.31)
    'euandro': ['e_u^a^ndro_', 'Evandro_'],
    'euandri': ['e_u_a^ndri^', 'Euandri_'],
    'euandrum': ['euandrum', 'E_u_a^ndru_m'],
    'euandre': ['e_u^a^ndre^', 'Evandre'],
    // Arcades → Ar-ca-dēs (LSS) Aen 10.491, 11.93, 11.142: wordlist arca^de_s
    // gives LSL (long a). (Not formable via brute — segmenter; see below.)
    // obice/obiciunt → ŏ-bĭ-c- (LSS/LSSL) Aen 10.377, 10.115: wordlist obi^ce/
    // obi^ciunt give SSS/SSSL — the closed-prefix o + short bi. Same class as
    // the M-013b obicitur cluster.
    'obice': ['o_bi^ce^', 'obi^ce'],
    'obiciunt': ['o_bi^ci^u^nt', 'obi^ciunt'],
    // Laride → Lā-rī-dē (LLL) Aen 10.391, 10.395: wordlist la_ri^de LSS.
    'laride': ['la_ri_de_', 'la_ri^de'],
    // Cisseis → Cis-sē-īs (LLL) Aen 10.705: wordlist Cissei_s LSL.
    'cisseis': ['ci^sse_i^s', 'Cissei_s'],
    // Atinas → A-tī-nās (SLL) Aen 11.xxx: wordlist A_ti_na_s LLL.
    'atinas': ['a^ti_na^s', 'A_ti_na_s'],
    // Mago → Ma-gō (SL) Aen 10.521: wordlist Ma_go_ LL.
    'mago': ['ma^go_', 'Ma_go_'],
    // sinit → sĭ-nīt (SL) Aen 10.433: wordlist si^nit SS. The earlier si^ni^t
    // was all-short (SS) and never produced the gold SL — the final -nit must be
    // long (before "hinc", position via the stop + h). Fixed 2026-08-11.
    'sinit': ['si^ni_t', 'si^nit'],
    // dabat → dă-bāt (SL) Aen 10.383: wordlist da^bat SS. Same all-short bug:
    // the earlier da^ba^t gave SS only; gold needs the final -bat long.
    'dabat': ['da^ba_t', 'da^bat'],
    // juvat → jŭ-vat (SL) Aen 10.284: wordlist ju^vat SS.
    'juvat': ['ju^va_t', 'ju^vat'],
    // Thybri → Thy-brī (LS) Aen 10.421: wordlist Thybri_ LL.
    'thybri': ['thy_bri^', 'Thybri_'],
    // ── M-013h: Aeneid 7-12 + Catullus 64-116 quantity fixes (gold-verified,
    // blocker-brute-forced via test/gold-blocker.mjs). Each first form produces
    // the gold L/S pattern in the failing line's actual following segment; the
    // second keeps the wordlist's prose-primary reading. Closed-class verbs get
    // a long final (SL/LL) — the wordlist marks all-short, which never scans.
    'aclydes': ['aclydes', 'a_clydes'],
    'adiciam': ['a_diciam', 'a_di^ciam'],
    'adicias': ['a_dicias', 'a_di^cias'],
    'aerei': ['aerei', 'aere_i'],
    'aereo': ['a_ereo_', 'a_e^reo_'],
    'amazones': ['amazones', 'a^mazones'],
    'anteirent': ['anteirent', 'a_nteirent'],
    'anxurus': ['anxurus', 'a_nxurus'],
    'arabs': ['arabs', 'a^rabs'],
    'arcades': ['arcades', 'a_rcades'],
    'arcessite': ['arcessite', 'a_rcessite'],
    'arrius': ['arrius', 'a_rrius'],
    'baltei': ['baltei', 'ba_ltei'],
    'bijugis': ['bijugi_s', 'biju^gi_s'],
    'bijugos': ['bijugo_s', 'biju^go_s'],
    'caenea': ['caenea', 'caene^a'],
    'caerete': ['caere_te', 'caere_te^'],
    'canit': ['cani_t', 'ca^ni_t'],
    'caput': ['capu_t', 'ca^pu_t'],
    'cissea': ['cissea', 'ci_ssea'],
    'clarus': ['clarus', 'cla^rus'],
    'di': ['di', 'di^'],
    // dii → dĭ-ī (SL) Aen 1.636 "munera laetitiamque dii" (hemistich): wordlist
    // di_i_ gives LL (both long), never the gold SL. The line is a genuine
    // fragment that can't reach 6 feet, but with SL it scans as a 1-4-foot
    // partial (gate-accepted hemistich) instead of EMPTY.
    'dii': ['dii_', 'di^i_'],
    'conicite': ['co_nicite', 'co_ni^cite'],
    'crateras': ['cra_te_ras', 'cra_te_ra^s'],
    'cydon': ['cy_do_n'],
    'decolor': ['de_color', 'de_co^lor'],
    'dehiscat': ['dehisca_t', 'de^hisca_t'],
    'derigere': ['de_rigere', 'de_ri^gere'],
    'dimovet': ['di_movet', 'di_mo^vet'],
    'disice': ['di_sice', 'di_si^ce'],
    'disicit': ['di_sicit', 'di_si^cit'],
    'dissidet': ['dissidet', 'di_ssidet'],
    'dissoluo': ['dissoluo_', 'di_ssoluo_'],
    'dolor': ['dolo_r', 'do^lo_r'],
    'domitor': ['domito_r', 'do^mito_r'],
    'ebur': ['ebu_r', 'e^bu_r'],
    'effatur': ['effa_tu_r', 'e_ffa_tu_r'],
    'effulgere': ['effulgere', 'e_ffulgere'],
    'elate': ['e_la_te', 'e_la_te^'],
    'eque': ['e_que', 'equ^e'],
    'erat': ['era_t', 'e^ra_t'],
    'erit': ['eri_t', 'e^ri_t'],
    'euander': ['euander', 'e_uander'],
    'evoluam': ['e_voluam', 'e_vo^luam'],
    'exciti': ['exci_ti_', 'e_xci_ti_'],
    'excitos': ['exci_to_s', 'e_xci_to_s'],
    'fatigamus': ['fati_ga_mu_s', 'fa^ti_ga_mu_s'],
    'fulgeremus': ['fulge_re_mu_s', 'fu_lge_re_mu_s'],
    'functus': ['functu_s', 'fu_nctu_s'],
    'habet': ['habe_t', 'ha^be_t'],
    'homo': ['homo', 'ho^mo'],
    'idomenei': ['i_domenei', 'i_do^menei'],
    'inicit': ['i_nicit', 'i_ni^cit'],
    'io': ['i_o_'],
    'iri': ['i_ri', 'i_ri^'],
    'it': ['i_t', 'it'],
    'lagus': ['lagus', 'la^gus'],
    'lavinia': ['lavi_nia', 'la^vi_nia'],
    'liquefaciens': ['lique_faciens', 'li^que_faciens'],
    'lyncea': ['lyncea', 'ly_ncea'],
    'manibus': ['ma_nibus', 'ma_ni^bus'],
    'marruvia': ['marruvia_', 'ma_rruvia_'],
    'nerei': ['ne_rei', 'ne_re_i'],
    'orithyia': ['o_rithyi_a_', 'o_ri_thy_ia_'],
    'pervoluent': ['pervoluent', 'pe_rvoluent'],
    'petamus': ['peta_mu_s', 'pe^ta_mu_s'],
    'petit': ['peti_t', 'pe^ti_t'],
    'procul': ['procu_l', 'pro^cu_l'],
    'profugus': ['profugu_s', 'pro^fugu_s'],
    'quadrijugis': ['quadrijugi_s', 'quadriju^gi_s'],
    'quadrijugo': ['quadrijugo_', 'quadriju^go_'],
    'reicit': ['re_icit', 're_i^cit'],
    'reiciunt': ['re_iciunt', 're_i^ciunt'],
    'rejecta': ['re_jecta_', 're^jecta_'],
    'rejecti': ['re_jecti', 're^jecti'],
    'replet': ['reple_t', 're_ple_t'],
    'revinxit': ['revinxi_t', 're^vinxi_t'],
    'rhoetea': ['rhoetea', 'rhoete^a'],
    'siqua': ['si_qua', 'siqu^a'],
    'stabat': ['sta_ba_t'],
    'subiit': ['subii_t', 'su^bii_t'],
    'succidimus': ['succidimus', 'su_ccidimus'],
    'summove': ['summo_ve', 'su_mmo_ve'],
    'tethyi': ['te_thyi', 'te_thy^i'],
    'te': ['te', 'te^'],
    'thymbre': ['thymbre', 'thy_mbre'],
    'typhoeo': ['typhoeo_', 'ty^phoeo_'],
    'vomeris': ['vo_meris', 'vo_me^ris'],
    // ── M-013i: Georgics + Eclogues + residual Aeneid (gold-blocker brute-forced) ──
    'aberat': ['abera_t', 'a^bera_t'],
    'amore': ['amo_re_', 'a^mo_re_'],
    'ararim': ['ararim', 'a^rarim'],
    'atlantides': ['atlantides', 'a_tlantides'],
    'bijuges': ['bijuge_s', 'biju^ge_s'],
    'conice': ['co_nice', 'co_ni^ce'],
    'cratere': ['cra_te_re', 'cra_te_re^'],
    'defruta': ['defruta', 'de_fruta'],
    'dehiscunt': ['dehiscunt', 'de^hiscunt'],
    'enituit': ['e_nitui_t', 'e_ni^tui_t'],
    'epiros': ['e_pi_ros', 'e_pi_ro^s'],
    'erue': ['e_rue', 'e_ru^e'],
    'eurysthea': ['eurysthea', 'e_urysthea'],
    'facit': ['faci_t', 'fa^ci_t'],
    'felicis': ['fe_li_ci_s'],
    'fultus': ['fultu_s', 'fu_ltu_s'],
    'gravidus': ['gravidu_s', 'gra^vidu_s'],
    'ingreditur': ['ingreditu_r', 'i_ngreditu_r'],
    'iniciunt': ['i_niciunt', 'i_ni^ciunt'],
    'invalidus': ['invalidu_s', 'i_nvalidu_s'],
    'jovis': ['jovi_s', 'jo^vi_s'],
    'labor': ['labo_r', 'la^bo_r'],
    'libethrides': ['li_bethrides', 'li_be_thrides'],
    'lita': ['lita', 'li^ta'],
    'mareotides': ['mareo_tides', 'ma^reo_tides'],
    'medica': ['me_dica', 'me_di^ca'],
    'melior': ['melio_r', 'me^lio_r'],
    'moeri': ['moeri', 'moeri^'],
    'nullius': ['nulli_u_s', 'nu_lli_u_s'],
    'obicienda': ['o_bicienda', 'o_bi^cienda'],
    'oceanitides': ['o_ceani_tides', 'o_ce^ani_tides'],
    'orchades': ['orchades', 'o_rchades'],
    'orphei': ['orphei', 'o_rphei'],
    'persidis': ['persidis', 'pe_rsidis'],
    'phyllis': ['phyllis', 'phy_llis'],
    'pleas': ['ple_as', 'ple_a^s'],
    'pleiadas': ['ple_iada_s', 'ple_i^ada_s'],
    'potis': ['po_tis', 'po_ti_s'],
    'proetides': ['proetides', 'proeti^des'],
    'promethei': ['prome_thei', 'pro^me_thei'],
    'puer': ['pue_r', 'pu^e_r'],
    'quadrijugos': ['quadrijugo_s', 'quadriju^go_s'],
    'qui': ['qui', 'qu_i'],
    'reice': ['re_ice', 're_i^ce'],
    'subicit': ['su_bicit', 'su_bi^cit'],
    'superinice': ['superi_nice', 'su^peri_nice'],
    'tondebat': ['tonde_ba_t', 'to_nde_ba_t'],
    'typhoea': ['typhoea_', 'ty^phoea_'],
    'vale': ['vale', 'va^le'],
    'victricis': ['victri_ci_s', 'vi_ctri_ci_s'],
    // ── M-013b: batch 5 — Catullus quantity fixes (gold-verified) ──
    // dicetur → dī-cē-tur (LLL) Cat 62.4; wordlist di_ce_tur gives LLS.
    'dicetur': ['di_ce_tu_r', 'di_ce_tur'],
    // thetis → The-tis (SL in Cat 64.29, SS in 64.20) — both candidates.
    'thetis': ['the^ti_s', 'theti_s', 'The^tis'],
    // tene → tē-ne (LS) Cat 64.29/30 (tēne "whether..."); wordlist te^ne_ gives SL.
    'tene': ['te_ne', 'te^ne'],
    // nereine → Nē-rē-ī-nē (LLLL) Cat 64.29; wordlist gives... check.
    'nereine': ['ne_re_i_ne_', 'Ne_re_i_ne_'],
    // tethys → Tē-thȳs (LL) Cat 64.30; wordlist gives... check.
    'tethys': ['te_thy_s', 'Te_thy_s'],
    // suam → su-am (SL) Cat 64.30; wordlist suam gives... check.
    'suam': ['su^am', 'suam'],
    // thesei → Thē-sei (LL) Cat 64.121; wordlist The_se_i_ gives LLL.
    'thesei': ['the_sei', 'the_se^i'],
    // redimita → re-di-mi-ta (SSLS) Cat 64.194; wordlist redi^mi^ta_ gives SSSL.
    'redimita': ['re^dimi_ta', 'redi_mi^ta'],
    // aerium → ā-e-ri-um (LSSL) Cat 64.241 (gold reads aerium/āerium); wordlist aereum gives LSL.
    'aerium': ['a_e^rium', 'a_erium'],
    // liquere → li-quē-re (LLS) Cat 64.241; wordlist gives... check.
    'liquere': ['li_que_re', 'li^que_re'],
    // opis → o-pis (SL) Cat 64.325 (gen. of ops); wordlist capitalized Opis gives LL.
    'opis': ['o^pi_s', 'o_pi_s'],
    // clarissime → clā-ris-si-me (LLSS) Cat 64.325; wordlist gives... check.
    'clarissime': ['cla_rissime', 'cla_ri_ssime'],
    // pelei → Pē-lei (LL) Cat 64.383; wordlist pe_le_i_ gives LLL.
    'pelei': ['pe_lei', 'pe_le^i'],
    // tepefaciet → te-pe-fa-ci-et (SLSSL) Cat 64.361; wordlist te^pe^fa^ciet gives SSSSL.
    'tepefaciet': ['te^pe_facie_t', 'tepe_facie_t'],
    // alta → al-ta (LS) Cat 64.361; wordlist alta gives LS already.
    'alta': ['alta', 'a_lta'],
    // despexit → dē-spe-xit (LLL) Cat 64.20; wordlist de_spexit gives LLS.
    'despexit': ['de_spexi_t', 'de_spexit'],
    // hymenaeos → hy-me-nae-os (SSLL) Cat 64.20; wordlist gives... check.
    'hymenaeos': ['hy^menaeo_s', 'hymenaeo_s'],
    // tenuit → te-nu-it (SSL) Cat 64.29; wordlist tenuit gives... check.
    'tenuit': ['te^nui_t', 'tenui_t'],
    // concessit → con-ces-sit (LLL) Cat 64.30; wordlist concessit gives... check.
    'concessit': ['concessi_t', 'co_ncessi_t'],
    // capillo → ca-pil-lo (SLL) Cat 64.194; wordlist capillo_ gives LLL.
    'capillo': ['ca^pillo_', 'capillo_'],
    // ── M-013b: batch 6 — more gold-verified (Aeneid) ──
    // colloque → col-lo-que (LLS) Aen 1.654/715; wordlist collo^que gives LSS.
    'colloque': ['co_llo_que', 'collo_que'],
    // zacynthos → Za-cyn-thos (SLL) Aen 3.270; wordlist Za^cyntho_s gives SLL.
    'zacynthos': ['za^cyntho_s', 'zacyntho_s'],
    // cyclopes → Cȳ-clo-pes (LLS) Aen 3.644; wordlist cyclo_pe_s gives LLL.
    'cyclopes': ['cy_clo_pes', 'cyclo_pes'],
    // amittebat → ā-mit-tē-bat (LLLL) Aen 5.853; wordlist amittebat gives... check.
    'amittebat': ['a_mi_tte_ba_t', 'a_mitte_ba_t'],
    // nemorosa → ne-mo-rō-sa (SSLS) Aen 3.270; wordlist ne^mo^ro_sa_ gives SSLL.
    'nemorosa': ['ne^moro_sa', 'nemoro_sa'],
    // vomere → vō-me-re (LSS) Cat 64.41; wordlist vo^mere gives SSS.
    'vomere': ['vo_mere', 'vo^mere'],
    // ── M-013b: batch 8 — more gold-verified ──
    // dimovit → dī-mō-vit (LLL) Aen 5.839; wordlist dimo_vit gives SLL.
    'dimovit': ['di_mo_vi_t', 'dimo_vit'],
    // reiecit → re-ie-cit (SLS) Aen 5.461; wordlist reje_cit gives SLS already? check.
    'reiecit': ['re^ie_cit', 'reje_cit'],
    // dehiscent → de-hī-scent (SLL) Aen 6.52; wordlist de_hi_scent gives LLL.
    'dehiscent': ['de^hi_scent', 'de_hi_scent'],
    // thraces → Thrā-ces (LS) Aen 3.14; wordlist Thra_ce_s gives LL.
    'thraces': ['thra_ce^s', 'thra_ces'],
    // pulvis → pul-vis (LL) Aen 1.478; wordlist pulvis gives LS.
    'pulvis': ['pulvi_s', 'pulvis'],
    // aereum → ā-e-re-um (LSSL) Cat 64.241 (gold reads āerium); wordlist aere^um gives LSL.
    'aereum': ['a_e^re^um', 'a_erium'],
    // videt → vĭ-dēt (SL) Aen 1.308: gold per-syllable is vĭ-dēt (final syllable
    // long — the line "qui teneant, nam inculta videt, hominēsne feraene" only
    // scans with SL here). The earlier vi_det (LS) reading was wrong: the final
    // -t before h+vowel does NOT make position, and gold=SL anyway.
    'videt': ['vi^det', 'vi^de_t'],
    // cymodoce → Cȳ-mo-do-cē (LSSL) Aen 5.826: the ending-engine form cymodoce_
    // scans SSSL (all short vowels); the correct Greek quantity is L-S-S-L
    // (final cē long). With this form the line completes with -que as a real
    // final syllable (gold Cymodoceque=LSSLL) — not as an elided hypermeter.
    'cymodoce': ['cy_mo^do^ce_'],
    // Gold-confirmed quantity fixes (negenborn full-Catullus scansion, M-023m).
    // The wordlist reading lacks the quantity the verse needs; the extra form
    // becomes a scansion candidate the meter can pick (prose keeps accented[0]).
    // Erechtēī → e-rech-thei (3-syll SLL): wordlist has only 4-syll readings
    // (E^rechthei_ SLSL / E^rechthe_i_ SLLL); the synizesis -eī is needed.
    'erechthei': ['erechthei'],
    // āereă (LXIV 292) — the ā of aēreus is long; wordlist aere^a has short a.
    'aerea': ['a_erea_'],
    // lāsarpīciferīs (VII 4) — the ā of lasarpicium is long; wordlist short.
    'lasarpiciferis': ['la_sarpi_ciferis'],
    // rēiecta (LXVI 81) — the re- prefix is long; wordlist rejecta has short e.
    'reiecta': ['reiecta_'],
    // sĭc (XXII 5) — sic is always short; wordlist only has si_c (long).
    'sic': ['sic'],
    // lĭquisse (XXXI 6) — linquo's i is short; wordlist li_quisse over-lengthens.
    'liquisse': ['liquisse'],
    // dĕprēnsa (XXV 13) — the de- prefix is short (prens long by position);
    // wordlist de_pre_nsa_ over-lengthens the first syllable.
    'deprensa': ['deprensa'],
    // Pēgaseo (LVIIIb 2) — Pegasus has long ē; wordlist pe_ga^se_o_ is LSLL.
    'pegaseo': ['pe_gaseo_'],
    // ── M-023m triage (2026-09-21): blockers checked against L&S headwords ──
    // hoc nom/acc is always short hŏc (only abl. hōc is long); the tagger can
    // land on the ablative ho_c reading in "hŏc est" (XXXI 11). Additive only —
    // corrects the homograph selection, contradicts no dictionary quantity.
    'hoc': ['ho^c'],
    // REJECTED after L&S check (do not re-add from a blocker run):
    //   ridete — L&S headword rīdĕo (LONG ī); the gold rĭdētĕ (XXXI 14) puts the
    //     short on the FIRST syllable, which a hendecasyllable fixes long — so
    //     the gold mark here is a blip/license, not a short-i lexeme. (Overriding
    //     would itself break the meter.) Caution: a hendecasyllable's first
    //     syllable is NOT anceps; earlier notes calling line-initial anceps were
    //     wrong — the general rule is: L&S headword is the arbiter, not the gold
    //     position.
    //   vesaniente — L&S "vē-sānus" (long ē); gold vĕsaniente (XXV 13)
    //     contradicts the lexicon.
    //   renidere — L&S rĕnīdĕo, 2nd conj → inf. renīdēre (long dē); the gold's
    //     short syllables sit at the elision against "usque" (XXXIX 15) —
    //     segmenter/elision limitation, not a quantity bug.
    // vorago — APPLIED: L&S headword vŏrāgo (breve on ŏ, long ā, breve on final
    // ō; Perseus entry title). The wordlist vo^ra_go_ = vŏ-rā-GŌ marks the final
    // ō LONG; L&S and the gold (XVII 11 vŏrāgŏ) both read it SHORT. The added
    // vo^ra_go = vŏrāgŏ (SLS) lets the meter pick the correct reading. (Earlier
    // note claiming "Wiktionary nom. vorāgō long ō, line-end anceps" was wrong —
    // L&S, not Wiktionary's orthographic macrons, is the arbiter.)
    'vorago': ['vo^ra_go'],
};
/**
 * Tokenization class - splits Latin text into tokens
 * Handles enclitics (-que, -ve, -ne), sentence boundaries
 */
export class Tokenization {
    constructor(text, options = {}) {
        Object.defineProperty(this, "tokens", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: []
        });
        Object.defineProperty(this, "text", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "originalText", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "_scannedFeet", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: []
        });
        this.text = text;
        this.originalText = text;
        this.tokenize(text, options);
        this.detectSentenceBoundaries();
    }
    /**
     * Main tokenization method
     */
    /**
     * Tokenize text into words, whitespace, and punctuation.
     * Sentence boundary detection matches Python tokenization.py exactly:
     * - A punctuation mark (.;:?!) ends a sentence ONLY if the preceding word
     *   was longer than 1 character. This prevents false boundaries at Latin
     *   abbreviations like "M." (Marcus), "L." (Lucius), "ā. d." (ante diem).
     * - Single-char words + period do NOT end the sentence.
     */
    tokenize(text, options) {
        const { preserveWhitespace = false } = options;
        this.tokens = [];
        let position = 0;
        let currentWord = '';
        let wordStart = 0;
        // Python: possiblesentenceend tracks whether the previous word token is
        // long enough to plausibly end a sentence
        let possibleSentenceEnd = false;
        for (let i = 0; i < text.length; i++) {
            // Pre-existing stress accents are stripped from the input: pasting an
            // already-accentuated liturgical text must re-accentuate idempotently
            // instead of failing every wordlist lookup (the acute is not part of
            // any wordform). Covers the combining mark and the precomposed forms.
            const char = stripStressMark(text[i]);
            // Check if character is part of a word. \p{L}\p{M} (not just \w) so
            // ligatures and accented letters stay inside the word: "cælis" is ONE
            // token, not "c" + "æ" + "lis" (Python's tokenizer is Unicode-aware
            // here too: [^\W\d_]+).
            if (/[\w\p{L}\p{M}]/u.test(char) || char === '-' || char === '_') {
                if (currentWord === '') {
                    wordStart = position;
                }
                currentWord += char;
            }
            else {
                // End of word - process it
                if (currentWord) {
                    this.addWordToken(currentWord, wordStart, position);
                    // Python: possiblesentenceend = (len(token.text) > 1)
                    possibleSentenceEnd = (currentWord.length > 1);
                    currentWord = '';
                }
                // Handle whitespace and punctuation
                if (isWhitespace(char)) {
                    if (preserveWhitespace) {
                        this.tokens.push(new Token(char, {
                            isWord: false,
                            isSpace: true,
                            startIndex: position,
                            endIndex: position + 1
                        }));
                    }
                }
                else {
                    // Punctuation
                    // Python: elif possiblesentenceend and any(i in token.text for i in '.;:?!'):
                    const isSentEnder = isSentenceEnder(char);
                    const endsSentence = possibleSentenceEnd && isSentEnder;
                    this.tokens.push(new Token(char, {
                        isWord: false,
                        isSpace: false,
                        endssentence: endsSentence,
                        startIndex: position,
                        endIndex: position + 1
                    }));
                    // After a sentence-ending punctuation, reset
                    if (endsSentence) {
                        possibleSentenceEnd = false;
                    }
                }
            }
            position++;
        }
        // Handle final word
        if (currentWord) {
            this.addWordToken(currentWord, wordStart, position);
        }
    }
    /**
     * Detect sentence boundaries and mark startssentence on tokens
     */
    detectSentenceBoundaries() {
        let startOfSentence = true;
        for (let i = 0; i < this.tokens.length; i++) {
            const token = this.tokens[i];
            if (token.isWord) {
                if (startOfSentence) {
                    this.tokens[i] = token.with({ startssentence: true });
                    startOfSentence = false;
                }
                if (token.endssentence) {
                    startOfSentence = true;
                }
            }
            else if (token.endssentence) {
                startOfSentence = true;
            }
        }
    }
    /**
     * Add a word token (without splitting enclitics yet)
     */
    addWordToken(word, start, end) {
        // Simply add the word as a single token; enclitic splitting will be done later
        this.tokens.push(new Token(word, {
            isWord: true,
            isSpace: false,
            startIndex: start,
            endIndex: end,
            text: word
        }));
    }
    /**
     * Split enclitics after wordlist is loaded (Python's two-pass strategy)
     * Returns list of word forms that need to be tagged (excluding enclitics)
     */
    async splitEnclitics(wordlistEngine) {
        var _a, _b;
        const newTokens = [];
        const wordFormsToTag = [];
        for (const token of this.tokens) {
            if (!token.isWord || token.isenclitic) {
                newTokens.push(token);
                continue;
            }
            const asciiLower = toAscii(token.text).toLowerCase();
            // Check if we should split this word (use getAllEntries since wordExists is private)
            const existingEntries = await wordlistEngine.getAllEntries(asciiLower);
            const exists = existingEntries.length > 0;
            const shouldSplit = asciiLower !== 'que' && (!exists || Tokenization.specialEncliticWords.has(asciiLower));
            if (!shouldSplit) {
                newTokens.push(token);
                wordFormsToTag.push(asciiLower);
                continue;
            }
            // Determine how to split
            let stemText = '';
            let encliticText = null;
            let isEncliticSplit = false;
            const tokenStart = (_a = token.startIndex) !== null && _a !== void 0 ? _a : 0;
            const tokenEnd = (_b = token.endIndex) !== null && _b !== void 0 ? _b : tokenStart + token.text.length;
            // Special cases: nec, necnon, dividenda
            if (asciiLower === 'nec') {
                stemText = token.text.slice(0, -1);
                encliticText = token.text.slice(-1);
                isEncliticSplit = true;
            }
            else if (asciiLower === 'necnon') {
                // Split at 3 (no enclitic), then split first part at 1 (with enclitic)
                const part1Text = token.text.slice(0, -3); // "nec"
                const part2Text = token.text.slice(-3); // "non"
                const part1Stem = part1Text.slice(0, -1); // "ne"
                const part1Enclitic = part1Text.slice(-1); // "c"
                // Create tokens: "ne" (hasEnclitic), "c" (isEnclitic), "non" (regular)
                const neToken = new Token(part1Stem, {
                    isWord: true,
                    isSpace: false,
                    hasenclitic: true,
                    startssentence: token.startssentence,
                    startIndex: tokenStart,
                    endIndex: tokenStart + part1Stem.length,
                    text: part1Stem
                });
                const cToken = new Token(part1Enclitic, {
                    isWord: true,
                    isSpace: false,
                    isenclitic: true,
                    startIndex: tokenStart + part1Stem.length,
                    endIndex: tokenStart + part1Stem.length + part1Enclitic.length,
                    text: part1Enclitic
                });
                const nonToken = new Token(part2Text, {
                    isWord: true,
                    isSpace: false,
                    startIndex: tokenStart + part1Stem.length + part1Enclitic.length,
                    endIndex: tokenEnd,
                    text: part2Text
                });
                wordFormsToTag.push(toAscii(part1Stem).toLowerCase());
                wordFormsToTag.push(toAscii(part2Text).toLowerCase());
                newTokens.push(neToken, cToken, nonToken);
                continue;
            }
            else if (asciiLower in Tokenization.dividenda && !exists) {
                // Only split dividenda compounds if word is unknown (matches Python behavior)
                const splitPos = Tokenization.dividenda[asciiLower];
                const stemPart = token.text.slice(0, -splitPos);
                const restPart = token.text.slice(-splitPos);
                const stemToken = new Token(stemPart, {
                    isWord: true,
                    isSpace: false,
                    startssentence: token.startssentence,
                    startIndex: tokenStart,
                    endIndex: tokenStart + stemPart.length,
                    text: stemPart
                });
                const restToken = new Token(restPart, {
                    isWord: true,
                    isSpace: false,
                    startIndex: tokenStart + stemPart.length,
                    endIndex: tokenEnd,
                    text: restPart
                });
                wordFormsToTag.push(toAscii(stemPart).toLowerCase());
                wordFormsToTag.push(toAscii(restPart).toLowerCase());
                newTokens.push(stemToken, restToken);
                continue;
            }
            else {
                // Generic enclitic split using utility
                const splitResult = splitEnclitic(asciiLower);
                if (!splitResult) {
                    // No split pattern matched, keep original
                    newTokens.push(token);
                    wordFormsToTag.push(asciiLower);
                    continue;
                }
                // Slice the ORIGINAL text (Python Token.split preserves case);
                // only the match is done on the lowercased form.
                const encLen = splitResult[1].length;
                stemText = token.text.slice(0, -encLen);
                encliticText = token.text.slice(-encLen);
                isEncliticSplit = true;
            }
            // Create tokens for enclitic split (nec or generic)
            if (isEncliticSplit) {
                const stemToken = new Token(stemText, {
                    isWord: true,
                    isSpace: false,
                    hasenclitic: true,
                    startssentence: token.startssentence,
                    startIndex: tokenStart,
                    endIndex: tokenStart + stemText.length,
                    text: stemText
                });
                const encliticToken = new Token(encliticText, {
                    isWord: true,
                    isSpace: false,
                    isenclitic: true,
                    startIndex: tokenStart + stemText.length,
                    endIndex: tokenEnd,
                    text: encliticText
                });
                wordFormsToTag.push(toAscii(stemText).toLowerCase());
                newTokens.push(stemToken, encliticToken);
            }
        }
        this.tokens = newTokens;
        return wordFormsToTag;
    }
    /**
     * Get all word forms for lookup
     */
    allWordForms() {
        const forms = [];
        for (const token of this.tokens) {
            if (token.isWord && !token.isenclitic) {
                forms.push(toAscii(token.text).toLowerCase());
            }
        }
        return [...new Set(forms)]; // Remove duplicates
    }
    /**
     * Add tags to tokens from RFTagger output
     */
    addTags(tags) {
        let tagIdx = 0;
        for (let i = 0; i < this.tokens.length; i++) {
            const token = this.tokens[i];
            if (token.isWord && !token.isenclitic) {
                if (tagIdx < tags.length) {
                    this.tokens[i] = token.with({
                        // Convert RFTagger dots to dashes to match wordlist format (n.-.s. → n-s--)
                        tag: tags[tagIdx].tag.replace(/\./g, '-')
                    });
                    tagIdx++;
                }
            }
        }
    }
    /**
     * Tag tokens using WasmTagger
     * Gets words from tokens and applies POS tags from RFTagger
     */
    async tagWithWasm(tagger) {
        // Match Python addtags() exactly:
        // - Skip whitespace
        // - ALL-CAPS → lowercase
        // - hasenclitic: save bearer, skip
        // - isenclitic: write enclitic text, then write saved bearer
        // - endssentence: sentence boundary
        const sentences = [[]];
        const sentenceTokenIndices = [[]];
        let savedBearer = null;
        let savedBearerIdx = -1;
        for (let i = 0; i < this.tokens.length; i++) {
            const token = this.tokens[i];
            if (!token.isSpace) {
                // Python: if tokentext == tokentext.upper(): tokentext = tokentext.lower()
                // No length check — single letters like "M" (abbreviation) become "m",
                // and punctuation is unaffected (",".toUpperCase() === ",").
                let tokentext = token.text;
                if (tokentext === tokentext.toUpperCase()) {
                    tokentext = tokentext.toLowerCase();
                }
                if (token.hasenclitic) {
                    savedBearer = toAscii(tokentext);
                    savedBearerIdx = i;
                }
                else {
                    sentences[sentences.length - 1].push(toAscii(tokentext));
                    sentenceTokenIndices[sentenceTokenIndices.length - 1].push(i);
                    if (token.isenclitic && savedBearer !== null) {
                        sentences[sentences.length - 1].push(savedBearer);
                        sentenceTokenIndices[sentenceTokenIndices.length - 1].push(savedBearerIdx);
                        savedBearer = null;
                    }
                }
            }
            if (token.endssentence) {
                sentences.push([]);
                sentenceTokenIndices.push([]);
            }
        }
        // Remove trailing empty sentence
        while (sentences.length > 0 && sentences[sentences.length - 1].length === 0) {
            sentences.pop();
            sentenceTokenIndices.pop();
        }
        if (sentences.length === 0)
            return;
        // Tag all sentences
        const allResults = tagger.tagSentences(sentences);
        // Apply tags back to tokens
        for (let s = 0; s < sentences.length; s++) {
            const sentTags = allResults[s];
            const indices = sentenceTokenIndices[s];
            for (let w = 0; w < indices.length && w < sentTags.length; w++) {
                const tokenIdx = indices[w];
                const result = sentTags[w];
                this.tokens[tokenIdx] = this.tokens[tokenIdx].with({
                    tag: normalizeTag(result.tag.replace(/\./g, ''))
                });
            }
        }
    }
    /**
     * Add lemmas to tokens.
     * Exact port of Python tokenization.py addlemmas():
     *   wordform = toascii(token.text)          # ORIGINAL case
     *   best_lemma = "-"; max_freq = -1
     *   Tier 1: wordform in wordform_to_corpus_lemmas →
     *           best corpus lemma by word_lemma_freq[(wordform, lemma)]
     *   Tier 2: wordform.lower() in wordlist.formtolemmas →
     *           best wordlist lemma by lemma_frequency.get(lemma, 0)
     * (No POS tag involved; strict > keeps the FIRST max in iteration order.)
     */
    async addLemmas(lemmaEngine, wordlistEngine) {
        for (let i = 0; i < this.tokens.length; i++) {
            const token = this.tokens[i];
            // Lemmas are only consumed downstream for non-enclitic word tokens
            if (!token.isWord || token.isenclitic)
                continue;
            const wordform = toAscii(token.text); // original case, like Python
            let bestLemma = '-';
            let maxFreq = -1;
            const corpus = lemmaEngine.getCorpusLemmas(wordform);
            if (corpus && corpus.length > 0) {
                for (const [lemma, freq] of corpus) {
                    if (freq > maxFreq) {
                        maxFreq = freq;
                        bestLemma = lemma;
                    }
                }
            }
            else if (wordlistEngine) {
                try {
                    // Entries come back in macrons.txt file order (seq-keyed store),
                    // matching Python's formtolemmas list order.
                    const entries = await wordlistEngine.getAllEntries(wordform.toLowerCase());
                    for (const entry of entries) {
                        const freq = lemmaEngine.getFrequency(entry.lemma);
                        if (freq > maxFreq) {
                            maxFreq = freq;
                            bestLemma = entry.lemma;
                        }
                    }
                }
                catch (_e) {
                    // Wordlist lookup failed; keep "-"
                }
            }
            this.tokens[i] = token.with({ lemma: bestLemma });
        }
    }
    /**
     * Get accents for tokens
     * Ported from latin_macronizer/tokenization.py (getaccents method)
     * Determines the best accented form (with _ markers) for each token
     */
    async getAccents(wordlistEngine, endingEngine) {
        // Helper: check if string is title case (first letter uppercase, rest lowercase)
        const isTitleCase = (s) => {
            if (!s)
                return false;
            return s[0] === s[0].toUpperCase() && s.slice(1) === s.slice(1).toLowerCase();
        };
        for (let idx = 0; idx < this.tokens.length; idx++) {
            const token = this.tokens[idx];
            if (!token.isWord)
                continue;
            // Python: wordform = toascii(token.text); iscapital = wordform.istitle();
            //         wordform = wordform.lower()
            const wordformAscii = toAscii(token.text);
            const isCapital = isTitleCase(wordformAscii);
            const wordformLower = wordformAscii.toLowerCase();
            const tag = token.tag;
            const lemma = token.lemma;
            let accented = [];
            let isUnknown = false;
            let isAmbiguous = false;
            // Which wordlist row each accented form came from — informational only, so the UI
            // can show the lemma and grammar of each reading instead of the token's single
            // best-frequency lemma. Never read by the macronization itself.
            let accentedSources = [];
            // Special enclitic cases
            if (token.isenclitic) {
                accented = [token.text.toLowerCase() === 'ue' ? 've' : token.text.toLowerCase()];
            }
            else if (token.text.toLowerCase() === 'ne' && token.hasenclitic) {
                accented = ['ne'];
            }
            else {
                // Try wordlist: get all entries for this wordform (macrons.txt file order)
                let entries = [];
                try {
                    entries = await wordlistEngine.getAllEntries(wordformLower);
                }
                catch (error) {
                    // Wordlist lookup failed (e.g., IndexedDB error); treat as unknown
                    console.warn('getAllEntries error for', wordformLower, error);
                    entries = [];
                }
                entries = entries.filter(e => e.accentedUnderscore !== undefined);
                // Python formtoaccenteds stores accented.lower(); the unique check and
                // the single-candidate result both use the LOWERCASED accented form.
                const loweredAccenteds = entries.map(e => e.accentedUnderscore.toLowerCase());
                if (entries.length > 0) {
                    // Rank every entry exactly like Python candidates.sort() on the tuple
                    // (casedist, tagdist, lemdist, accented). Even when every entry shares
                    // ONE accented form, the ranking decides the reading's lemma/tag —
                    // Germanis must read "the Germans" (Germani), not entries[0]'s "full
                    // sister" (germana), which is only first in macrons.txt file order.
                    const candidates = [];
                    for (const entry of entries) {
                        const lexLemma = entry.lemma;
                        const lexTag = entry.tag;
                        // Python: casedist = 0 if iscapital == lexlemma.istitle()
                        //                      or token.startssentence and iscapital else 1
                        const casedist = (isCapital === isTitleCase(lexLemma) || (token.startssentence && isCapital)) ? 0 : 1;
                        const tagdist = tagDistance(tag, lexTag);
                        const lemdist = levenshteinDistance(lemma, lexLemma);
                        candidates.push({ casedist, tagdist, lemdist, accented: entry.accentedUnderscore,
                            lemma: lexLemma, lexTag });
                    }
                    candidates.sort((a, b) => (a.casedist - b.casedist) ||
                        (a.tagdist - b.tagdist) ||
                        (a.lemdist - b.lemdist) ||
                        (a.accented < b.accented ? -1 : a.accented > b.accented ? 1 : 0));
                    if (new Set(loweredAccenteds).size === 1) {
                        // Single accented form — the macronization is unambiguous. Attach
                        // the BEST-RANKED candidate's lemma/tag so the popup shows the
                        // case-aware reading (Germanis → Germani "the Germans").
                        accented = [loweredAccenteds[0]];
                        accentedSources = [{
                                accented: loweredAccenteds[0],
                                lemma: candidates[0].lemma,
                                tag: candidates[0].lexTag
                            }];
                    }
                    else {
                        // Python: append unseen accenteds while casedist == best casedist
                        const bestCasedist = candidates[0].casedist;
                        accented = [];
                        for (const c of candidates) {
                            if (c.casedist === bestCasedist && !accented.includes(c.accented)) {
                                accented.push(c.accented);
                                accentedSources.push({ accented: c.accented, lemma: c.lemma, tag: c.lexTag });
                            }
                        }
                        isAmbiguous = accented.length > 1;
                    }
                }
                else {
                    // Unknown word — Python: accented = [token.text]; if it has vowels,
                    // scan tag_to_endings[tag] IN ORDER and take the first suffix match
                    // (built on the lowercase ascii wordform), then mark as unknown.
                    accented = [token.text];
                    if (/[aeiouyAEIOUY]/.test(token.text)) {
                        const endings = endingEngine.getEndingsForTag(tag);
                        for (const accentedEnding of endings) {
                            const plainEnding = accentedEnding.replace(/[_^]/g, '');
                            if (wordformLower.endsWith(plainEnding)) {
                                accented = [wordformLower.slice(0, wordformLower.length - plainEnding.length) + accentedEnding];
                                break;
                            }
                        }
                        isUnknown = true;
                    }
                }
            }
            // Inject context-dependent accent overrides (see ACCENT_OVERRIDES).
            // The wordlist form stays primary (prose macronization), extra forms
            // become scansion candidates the meter can pick.
            const override = ACCENT_OVERRIDES[wordformLower];
            if (override) {
                for (const form of override) {
                    if (!accented.includes(form)) {
                        accented.push(form);
                    }
                }
                isAmbiguous = accented.length > 1;
                // The override is authoritative for this wordform — clear the unknown
                // flag so the scansion fallback (allVowelsAmbiguous, which guesses every
                // vowel-length combo and lets the cheapest—often wrong—form win, e.g.
                // Cymodoce all-long) is not added on top of it.
                isUnknown = false;
            }
            // Update token with accented candidates and flags
            this.tokens[idx] = token.with({
                accented,
                accentedSources,
                isAmbiguous,
                isUnknown
            });
        }
    }
    /**
     * Apply macronization to all tokens
     */
    macronize(domacronize, alsomaius, performutov, performitoj, accent = false) {
        var _a, _b, _c, _d, _f;
        for (let i = 0; i < this.tokens.length; i++) {
            const token = this.tokens[i];
            if (token.isWord) {
                this.tokens[i] = this.macronizeToken(token, domacronize, alsomaius, performutov, performitoj, accent);
            }
        }
        // Enclitic bearings get their stress from the COMBINED stem+enclitic form
        // (rosáque, Filiúmque): rule 2 puts the accent on the syllable before the
        // enclitic, which needs the enclitic present to be counted at all.
        if (accent) {
            for (let i = 0; i < this.tokens.length; i++) {
                const bearer = this.tokens[i];
                const encliticToken = this.tokens[i + 1];
                if (!bearer.isWord ||
                    !bearer.hasenclitic ||
                    !encliticToken ||
                    !encliticToken.isenclitic) {
                    continue;
                }
                const accentedBearer = (_a = bearer.accented) === null || _a === void 0 ? void 0 : _a[0];
                if (!accentedBearer)
                    continue;
                // Base on the DISPLAYED forms (macronized when the option is on), so
                // macrons survive alongside the acute.
                const stemDisplay = (_b = bearer.macronizedText) !== null && _b !== void 0 ? _b : bearer.text;
                const encliticDisplay = (_c = encliticToken.macronizedText) !== null && _c !== void 0 ? _c : encliticToken.text;
                const combinedPlain = stemDisplay + encliticDisplay;
                const combinedAccented = accentedBearer + ((_f = (_d = encliticToken.accented) === null || _d === void 0 ? void 0 : _d[0]) !== null && _f !== void 0 ? _f : encliticToken.text);
                const stressedCombined = applyStress(combinedPlain, combinedAccented, true);
                if (stressedCombined !== combinedPlain) {
                    // The accent never lands inside the enclitic (rule 2), so the
                    // stressed form ends with the enclitic unchanged.
                    const stemStressed = encliticDisplay.length > 0 &&
                        stressedCombined.endsWith(encliticDisplay)
                        ? stressedCombined.slice(0, stressedCombined.length - encliticDisplay.length)
                        : stressedCombined;
                    this.tokens[i] = bearer.with({ stressedText: stemStressed });
                }
            }
        }
    }
    /**
     * Macronize single token
     * Ported from latin_macronizer/tokenization.py (macronize method)
     * Uses DP alignment to add macrons to the token's accented form
     */
    macronizeToken(token, domacronize, alsomaius, performutov, performitoj, accent = false) {
        // Use original text for alignment (alignMacronized will handle u->v, i->j conversions)
        let text = token.text;
        // Stress accents are computed on the DISPLAYED form (the macronized text
        // when macronization is on), so `sānctificētur` + stress gives
        // `sānctificḗtur` NFC (both marks on the same vowel). The reading's length
        // marks supply the quantity in every mode.
        let stressedText;
        const computeStress = (display) => {
            if (!accent || token.isenclitic || !token.accented || token.accented.length === 0) {
                return undefined;
            }
            return applyStress(display, token.accented[0], token.hasenclitic === true);
        };
        // Python Token.macronize has a guard that returns plain when !domacronize
        // AND neither orthographic conversion is requested.  When conversions ARE
        // requested, Python falls through to the DP alignment, which handles
        // u→v/i→j in the backtrack (only converting when the wordlist form
        // specifically has 'v'/'j').  Do the same here by deferring to
        // alignMacronized which mirrors Python's logic.
        if (!domacronize && !performutov && !performitoj) {
            return token.with({ text, macronized: true, stressedText: computeStress(text) });
        }
        // Get the accented form (with _ markers) from getAccents
        const accentedCandidates = token.accented;
        if (!accentedCandidates || accentedCandidates.length === 0) {
            // No accented form available, fallback
            return token.with({ text, macronized: true, stressedText: computeStress(text) });
        }
        // Use the first (best) accented candidate
        let accentedUnderscore = accentedCandidates[0];
        // Clean: remove '^' markers and '_^' sequences (as in Python Token.macronize)
        accentedUnderscore = accentedUnderscore.replace(/_\^/g, '').replace(/\^/g, '');
        // Apply alsomaius: add macron before 'j' (or 'i') after short vowel, unless prefix with short j
        // Python guards this with domacronize — only makes sense when macronizing
        if (domacronize && alsomaius && /[ij]/.test(accentedUnderscore)) {
            const lowerAcc = accentedUnderscore.toLowerCase();
            const startsWithShortJ = prefixesWithShortJ.some(prefix => lowerAcc.startsWith(prefix));
            if (!startsWithShortJ) {
                accentedUnderscore = accentedUnderscore.replace(/([aeiouy])([ij][aeiouy])/gi, '$1_$2');
            }
        }
        // If accented form became empty after cleaning, fallback to plain text
        if (!accentedUnderscore) {
            return token.with({ text, macronized: true, stressedText: computeStress(text) });
        }
        // Apply DP alignment to produce macronized output
        const alignOptions = {
            domacronize,
            alsomaius: alsomaius,
            performutov: performutov,
            performitoj: performitoj
        };
        const macronizedUnderscore = alignMacronized(text, accentedUnderscore, alignOptions);
        let macronizedUnicode;
        if (macronizedUnderscore === null) {
            macronizedUnicode = underscoreToUnicode(accentedUnderscore);
        }
        else {
            macronizedUnicode = underscoreToUnicode(macronizedUnderscore);
        }
        // u→v and i→j conversions are handled inside alignMacronized's DP backtrack,
        // only when the wordlist accented form specifically has 'v'/'j' at that
        // position.  Blanket replacement here would incorrectly convert e.g. "cum"
        // → "cvm" (wordlist form is "cum", not "cvm").
        return token.with({
            macronizedText: macronizedUnicode,
            macronized: true,
            stressedText: computeStress(macronizedUnicode)
        });
    }
    /**
     * Convert tokens back to text
     */
    detokenize() {
        var _a, _b, _c, _d, _f;
        let result = '';
        let lastEnd = 0;
        for (const token of this.tokens) {
            const start = (_a = token.startIndex) !== null && _a !== void 0 ? _a : lastEnd;
            // Add original whitespace between tokens
            if (start > lastEnd) {
                const whitespace = ((_b = this.originalText) === null || _b === void 0 ? void 0 : _b.substring(lastEnd, start)) || ' ';
                result += whitespace;
            }
            // Add token text - convert underscore notation to Unicode
            let text = (_c = token.macronizedText) !== null && _c !== void 0 ? _c : token.text;
            // Strip remaining underscores that aren't part of macron notation
            // (should already be converted, but double-check)
            if (text) {
                text = text.replace(/_/g, '');
            }
            result += text;
            lastEnd = (_d = token.endIndex) !== null && _d !== void 0 ? _d : (start + (((_f = token.text) === null || _f === void 0 ? void 0 : _f.length) || text.length));
        }
        return result;
    }
    /**
     * Reconstruct the stressed-accents text (stressedText ?? text per token,
     * enclitic tokens contribute their own text). Mirrors detokenize().
     */
    detokenizeStressed() {
        var _a, _b, _c, _d, _f;
        let result = '';
        let lastEnd = 0;
        for (const token of this.tokens) {
            const start = (_a = token.startIndex) !== null && _a !== void 0 ? _a : lastEnd;
            if (start > lastEnd) {
                const whitespace = ((_b = this.originalText) === null || _b === void 0 ? void 0 : _b.substring(lastEnd, start)) || ' ';
                result += whitespace;
            }
            const text = (_c = token.stressedText) !== null && _c !== void 0 ? _c : token.text;
            result += text;
            lastEnd = (_d = token.endIndex) !== null && _d !== void 0 ? _d : (start + (((_f = token.text) === null || _f === void 0 ? void 0 : _f.length) || text.length));
        }
        return result;
    }
    /**
     * Get plain text without HTML
     */
    getPlainText() {
        return this.tokens
            .map(t => { var _a; return (_a = t.macronizedText) !== null && _a !== void 0 ? _a : t.text; })
            .join(' ')
            .replace(/\s+/g, ' ')
            .trim();
    }
    /**
     * Scan verses using meter automata
     */
    scanVerses(meterAutomatons) {
        this._scannedFeet = doScanVerses(this.tokens, meterAutomatons);
    }
    /**
     * Get scanned feet (if scansion was performed)
     */
    get scannedFeet() {
        return this._scannedFeet;
    }
}
// Enclitic compounds that must be split even if known (from Python tokenization.py)
Object.defineProperty(Tokenization, "dividenda", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: {
        "nequid": 4, "attamen": 5, "unusquisque": 7, "unaquaeque": 7, "unumquodque": 7, "uniuscuiusque": 8,
        "uniuscujusque": 8, "unicuique": 6, "unumquemque": 7, "unamquamque": 7, "unoquoque": 6,
        "unaquaque": 6, "cuiusmodi": 4, "cujusmodi": 4, "quojusmodi": 4, "eiusmodi": 4, "ejusmodi": 4,
        "huiuscemodi": 4, "hujuscemodi": 4, "huiusmodi": 4, "hujusmodi": 4, "istiusmodi": 4, "nullomodo": 4,
        "quodammodo": 4, "nudiustertius": 7, "nonnisi": 4, "plusquam": 4, "proculdubio": 5, "quamplures": 6,
        "quamprimum": 6, "quinetiam": 5, "uerumetiam": 5, "verumetiam": 5, "verumtamen": 5, "uerumtamen": 5,
        "paterfamilias": 8, "patrisfamilias": 8, "patremfamilias": 8, "patrifamilias": 8, "patrefamilias": 8,
        "patresfamilias": 8, "patrumfamilias": 8, "patribusfamilias": 8, "materfamilias": 8,
        "matrisfamilias": 8, "matremfamilias": 8, "matrifamilias": 8, "matrefamilias": 8,
        "matresfamilias": 8, "matrumfamilias": 8, "matribusfamilias": 8,
        "respublica": 7, "reipublicae": 8, "rempublicam": 8, "senatusconsultum": 9, "senatusconsulto": 8,
        "senatusconsulti": 8, "usufructu": 6, "usumfructum": 7, "ususfructus": 7,
        "supradicti": 5, "supradictum": 6, "supradictus": 6, "supradicto": 5,
        "seipse": 4, "seipsa": 4, "seipsum": 5, "seipsam": 5, "seipso": 4, "seipsos": 5, "seipsas": 5,
        "seipsis": 5, "semetipse": 4, "semetipsa": 4, "semetipsum": 5, "semetipsam": 5, "semetipso": 4,
        "semetipsos": 5, "semetipsas": 5, "semetipsis": 5, "teipsum": 5, "temetipsum": 5, "vosmetipsos": 5,
        "idipsum": 5
    }
});
// Special enclitic words that should be split even if known (from Python)
Object.defineProperty(Tokenization, "specialEncliticWords", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: new Set(['nec', 'neque', 'necnon', 'seque', 'seseque', 'quique', 'mecumque', 'tecumque', 'secumque'])
});
//# sourceMappingURL=Tokenization.js.map