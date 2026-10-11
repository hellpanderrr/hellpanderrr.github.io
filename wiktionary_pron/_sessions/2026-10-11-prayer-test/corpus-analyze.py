"""Analyze corpus-run.mjs output: accuracy per tool and section, and every
miss classified.

Tools: 'ours page' = the word the page displays; 'ours engine' = the engine's
own stressedText (marks aligned onto the typed letters) for the same token;
Accenteur at 91823fe (the revision the corpus repo links) and master (live demo).

Classes (first match wins):
  capital       gold bare, word capitalized, tool put the acute on the first
                letter (Solesmes Option 2 — the corpus leaves those unmarked)
  inconsistent  the books contradict their own majority for this word, and the
                tool wrote the majority form (no tool can match both)
  unknown       tool produced nothing (Accenteur's red words) or, for ours, a
                different word than the text
  real          everything else

Usage: python -I corpus-analyze.py [OUT_DIR]   (default F:/temp/lea/corpus-run)
"""
import glob
import json
import os
import sys
import unicodedata as U
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding='utf-8')  # -I ignores PYTHONIOENCODING
OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else 'F:/temp/lea/corpus-run'
TOOLS = [('ours page', 'ours'), ('ours engine', 'engine'), ('acc 91823fe', 'pinF'), ('acc live', 'livF')]
ACUTE = '\u0301'
LIGATURES = ('\u00e6', '\u0153')  # ae, oe


def idx(s):
    """Acute positions in ligature-expanded coordinates. Walks the NFD string
    so a combining acute attaches to the base letter BEFORE it: oe+acute has no
    precomposed form, and per-code-point scanning credited its acute to the
    next letter (an earlier version did, wrongly failing 'oboediens')."""
    out, i, last = [], 0, None
    for ch in U.normalize('NFD', (s or '').lower()):
        if U.combining(ch):
            if ch == ACUTE and last is not None:
                out.append(last)
            continue
        last = i
        i += 2 if ch in LIGATURES else 1
    return tuple(out)


def base(s):
    s = U.normalize('NFC', U.normalize('NFD', s or '').replace(ACUTE, ''))
    return s.lower().replace(LIGATURES[0], 'ae').replace(LIGATURES[1], 'oe').replace('j', 'i')


def section(rel):
    parts = rel.split('/')
    if parts[0] in ('missal', 'psalms'):
        return '/'.join(parts[:2])
    if parts[0] == 'various':
        return 'various/' + os.path.splitext(parts[1])[0]
    return parts[0]


recs = []
unaligned = 0
for f in sorted(glob.glob(os.path.join(OUT_DIR, '*.json'))):
    d = json.load(open(f, encoding='utf-8'))
    unaligned += d['mismatchedLines']
    for r in d['records']:
        r['section'] = section(d['file'])
        r['file'] = d['file']
        recs.append(r)

# Majority accent pattern per word, over the tested corpus itself.
patterns = defaultdict(Counter)
for r in recs:
    patterns[base(r['gold'])][idx(r['gold'])] += 1


def majority(word):
    c = patterns[base(word)].most_common(2)
    if not c or (len(c) == 2 and c[0][1] == c[1][1]):
        return None
    return c[0][0]


def judge(r, key):
    """Return None if correct, else the miss class."""
    out = r.get(key)
    g = idx(r['gold'])
    if out is None:
        return 'unknown'
    if key in ('ours', 'engine') and base(out) != base(r['gold']):
        return 'unknown'  # a different word was displayed
    o = idx(out)
    if len(o) > 1:
        return 'real'
    if o == g:
        return None
    if g == () and r['gold'][:1].isupper() and o == (0,):
        return 'capital'  # first: 'Omnia' bare vs majority 'ómnia' is this, not a slip
    maj = majority(r['gold'])
    if maj is not None and g != maj and o == maj:
        return 'inconsistent'
    return 'real'


N = len(recs)
print(f'tokens scored: {N} in {len({r["file"] for r in recs})} files; lines left unaligned: {unaligned}')
print(f'tokens Accenteur 91823fe does not know: {sum(r["pinF"] is None for r in recs)}; '
      f'ours flagged unknown (guessed): {sum(r["oursUnknown"] for r in recs)}')
print()
verdict = {k: [judge(r, k) for r in recs] for _, k in TOOLS}
print(f'{"":14s}{"correct":>18s}{"capital":>9s}{"inconsistent":>14s}{"unknown":>9s}{"real":>7s}{"unknown+real":>14s}')
for name, k in TOOLS:
    c = Counter(verdict[k])
    print(f'{name:14s}{c[None]:>8d} = {100 * c[None] / N:6.2f}%{c["capital"]:>9d}{c["inconsistent"]:>14d}'
          f'{c["unknown"]:>9d}{c["real"]:>7d}{100 * (c["unknown"] + c["real"]) / N:>13.2f}%')

print('\nif a tool followed the capital-initial convention (Option 2):')
for name, k in TOOLS:
    c = Counter(verdict[k])
    print(f'  {name:14s} {100 * (c[None] + c["capital"]) / N:6.2f}%')

same = sum(1 for r in recs if r['ours'] is not None and r['pinF'] is not None and idx(r['ours']) == idx(r['pinF']))
print(f'\nsame output, ours page vs Accenteur 91823fe: {same}/{N} = {100 * same / N:.2f}%')
any_ok = sum(1 for r in recs if any(idx(c) == idx(r['gold']) for c in r['pinA']))
print(f'Accenteur 91823fe if the user picks right at every "?": {any_ok}/{N} = {100 * any_ok / N:.2f}%')

print('\nper section (correct %):')
for s in sorted({r['section'] for r in recs}):
    ids = [i for i, r in enumerate(recs) if r['section'] == s]
    line = f'  {s:30s} {len(ids):>6d} tok'
    for name, k in TOOLS:
        ok = sum(verdict[k][i] is None for i in ids)
        line += f' | {name} {100 * ok / len(ids):6.2f}%'
    print(line)

for name, k in TOOLS:
    print(f'\n{name}: most frequent REAL + UNKNOWN misses (gold -> output, count):')
    c = Counter()
    for r, v in zip(recs, verdict[k]):
        if v in ('real', 'unknown'):
            c[(r['gold'], r.get(k) if r.get(k) is not None else '—', v)] += 1
    for (g, o, v), n in c.most_common(40):
        print(f'    {n:>3d}  {g} -> {o}{"  [unknown]" if v == "unknown" else ""}')
    print(f'    ... {len(c)} distinct (gold, output) pairs, {sum(c.values())} tokens')

summary = {name: dict(Counter(verdict[k])) for name, k in TOOLS}
json.dump({'N': N, 'classes': {n: {str(a): b for a, b in v.items()} for n, v in summary.items()}},
          open(os.path.join(os.path.dirname(OUT_DIR.rstrip('/\\')), 'corpus-summary.json'), 'w', encoding='utf-8'),
          indent=1)
