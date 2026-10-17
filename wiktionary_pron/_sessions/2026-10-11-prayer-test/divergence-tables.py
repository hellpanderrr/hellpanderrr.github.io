"""Two tables from the full-corpus run, with the same scoring as corpus-analyze.py:

  divergences.md/.csv  every token where our page and Accenteur 91823fe disagree
                       on the accent (or one of them has no answer), grouped by
                       (corpus word, ours, Accenteur) with counts
  errors.md/.csv       every token where ours or Accenteur 91823fe misses the
                       corpus, grouped the same way, each tool's miss classified

Accenteur master (live demo) is shown as an extra column for reference.
Marks: ✓ right; ✗ real error; ✗cap capital-initial convention (Solesmes Option 2);
✗inc the books contradict their own majority form here; ✗unk no answer / a
different word shown.

Usage: python -I divergence-tables.py [OUT_DIR]   (default F:/temp/lea/corpus-run)
"""
import csv
import importlib.util
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('ca', os.path.join(HERE, 'corpus-analyze.py'))
ca = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ca)  # loads the records from OUT_DIR (argv[1] or default)
recs, idx, judge = ca.recs, ca.idx, ca.judge

MARK = {None: '✓', 'real': '✗', 'capital': '✗cap', 'inconsistent': '✗inc', 'unknown': '✗unk'}
show = lambda s: s if s is not None else '—'


def answer(r, key):
    """Accent position as the tool answered it; 'none' when there is no usable answer."""
    if judge(r, key) == 'unknown':
        return 'none'
    return idx(r[key])


def group(rows):
    g = defaultdict(lambda: {'n': 0, 'sections': Counter(), 'r': None})
    for r in rows:
        k = (r['gold'], show(r['ours']), show(r['pinF']), show(r['livF']))
        g[k]['n'] += 1
        g[k]['sections'][r['section']] += 1
        g[k]['r'] = r
    return sorted(g.items(), key=lambda kv: (-kv[1]['n'], kv[0][0].lower()))


def winner(r):
    o, a = judge(r, 'ours') is None, judge(r, 'pinF') is None
    return 'ours' if o and not a else 'Accenteur' if a and not o else 'both' if o else 'neither'


def write(name, title, intro, grouped, cols):
    header = ['#', 'Corpus', 'Ours', 'Accenteur 91823fe', 'Accenteur live'] + cols + ['Sections']
    md = [f'# {title}', '', intro, '',
          '| ' + ' | '.join(header) + ' |',
          '|---:|' + '---|' * (len(header) - 1)]
    rows_csv = []
    for (gold, ours, pin, liv), v in grouped:
        r = v['r']
        extra = [winner(r)] if 'Matches corpus' in cols else []
        secs = ', '.join(f'{s} {n}' if len(v['sections']) > 1 else s for s, n in v['sections'].most_common(3))
        cells = [str(v['n']), gold,
                 f"{ours} {MARK[judge(r, 'ours')]}", f"{pin} {MARK[judge(r, 'pinF')]}",
                 f"{liv} {MARK[judge(r, 'livF')]}"] + extra + [secs]
        md.append('| ' + ' | '.join(cells) + ' |')
        rows_csv.append(cells)
    open(os.path.join(HERE, name + '.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(md) + '\n')
    with open(os.path.join(HERE, name + '.csv'), 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f)
        w.writerow(['count', 'corpus', 'ours', 'accenteur_91823fe', 'accenteur_live'] + [c.lower() for c in cols] + ['sections'])
        w.writerows(rows_csv)


# ---- table 1: divergences between the tools ----
div = [r for r in recs if answer(r, 'ours') != answer(r, 'pinF')]
win = Counter(winner(r) for r in div)
write('divergences', 'Where our page and Accenteur 91823fe disagree',
      f'{len(div)} of {len(recs)} tokens ({100 * len(div) / len(recs):.2f}%): the corpus sides with '
      f'ours {win["ours"]}, with Accenteur {win["Accenteur"]}, with neither {win["neither"]}. '
      'Disagreement = different accent position, or one tool has no answer. Spelling (ae/oe) ignored.',
      group(div), ['Matches corpus'])

# ---- table 2: errors against the corpus ----
err = [r for r in recs if judge(r, 'ours') is not None or judge(r, 'pinF') is not None]
oc, ac = Counter(judge(r, 'ours') for r in err), Counter(judge(r, 'pinF') for r in err)
both = sum(1 for r in err if judge(r, 'ours') is not None and judge(r, 'pinF') is not None)
write('errors', 'Where our page or Accenteur 91823fe misses the corpus',
      f'{len(err)} tokens. Ours misses {sum(v for k, v in oc.items() if k)} '
      f'(capital {oc["capital"]}, books-inconsistent {oc["inconsistent"]}, no answer/other word {oc["unknown"]}, real {oc["real"]}); '
      f'Accenteur 91823fe misses {sum(v for k, v in ac.items() if k)} '
      f'(books-inconsistent {ac["inconsistent"]}, no answer {ac["unknown"]}, real {ac["real"]}); both miss {both}.',
      group(err), [])

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    print(f'divergences: {len(div)} tokens, {len(group(div))} rows; corpus sides with {dict(win)}')
    print(f'errors: {len(err)} tokens, {len(group(err))} rows; ours {dict(oc)}; accenteur {dict(ac)}; both miss {both}')
    print('wrote divergences.md/.csv and errors.md/.csv next to this script')
