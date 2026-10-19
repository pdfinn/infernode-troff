#!/bin/sh
#
# article_test.sh — -marticle and -mmemo, the classes on -mbook's macros,
# refer's numbered style, and troff's .if d:
#
#	troff: .if d name true of a macro, a string and a diversion, false
#	of a name never defined;
#	refer -S numeric: [n] in the line, before the punctuation it ends
#	with, numbered in the order works are first cited, a work cited
#	again its own number, [n, p.~5] at a page, [n, ch. 17] as given,
#	two works [1], [2]; the references in that order, each hung from
#	its label (.]be "[n]");
#	book -m article on examples/article.ms: two pages; the title a
#	heading (H1) across the page, the authors side by side; the text
#	in two columns below it; the note at the foot of its column; the
#	figure across both columns at the top of the next page, above both
#	columns' text; the first page's columns flush at their foot; the
#	last page's balanced; numbered references; the PDF claiming PDF/UA-1;
#	a generated article of six pages (notes, figures in both columns
#	and across them, a table across them) and the same in one column:
#	no word overlapping another, none outside the margins (the notes'
#	numbers, hung, and folios aside); one column's measure narrower;
#	book -m memo on examples/memo.ms: one page, the head's subject at
#	the left, date, from and TM: at the right, the kind of memorandum
#	below; .kind report its title centred.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "article_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] && [ -f "$ROOT/dis/refer/numeric.dis" ] ||
    { echo "article_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 && command -v pdftotext >/dev/null 2>&1 ||
    { echo "article_test: SKIP (no python3 or poppler)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/article.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

ex="$(cd "$(dirname "$0")/../.." && pwd)/examples"
[ -f "$ex/article.ms" ] || ex="$ROOT/examples"
cp "$ex/article.ms" "$ex/memo.ms" "$ex/works.bib" "$tmp/"
sed 's/^\.org.*/.kind report/' "$ex/memo.ms" >"$tmp/report.ms"

printf '.de mac\nx\n..\n.ds str y\n.di div\nz\n.br\n.di\n.if d mac .tm D mac\n.if d str .tm D str\n.if d div .tm D div\n.if d never .tm D never\n.if !d never .tm N never\n' >"$tmp/d.tr"
cat >"$tmp/num.tr" <<'EOF'
A first work.
.cite knuth1984
A second, at a page,
.cite kernighan1975 5
and the first again, at a chapter:
.cite knuth1984 ch. 17
two at once
.cite gauss1809; bringhurst2004
.bibliography
EOF

python3 -I - "$tmp" <<'PY'
import random, sys
d = sys.argv[1]
random.seed(7)
words = "the quick brown fox jumps over a lazy dog while typesetters measure every line and column carefully before each page is printed with care".split()
def para(n):
    return ' '.join(random.choice(words) for _ in range(n)).capitalize() + '.'
out = ['.title "A Long Test of Columns"']
for i, (n, a) in enumerate([('One Writer', 'A Place'), ('Two Writer', 'Elsewhere'), ('Three Writer', 'Third'), ('Four Writer', 'Fourth')]):
    out += ['.author "%s"' % n, '.affil "%s"' % a]
out += ['.abstract', para(60), '.endabstract', '.keywords "columns, tests"']
nf = 0
for sec in range(1, 9):
    out.append('.section "Section %d" s%d' % (sec, sec))
    for p in range(5):
        if p:
            out.append('.p')
        t = para(random.randint(40, 120))
        if random.random() < 0.3:
            out += [t + '\\*[fnmark]', '.fn', para(random.randint(15, 50)), '.fe']
        else:
            out.append(t)
        if random.random() < 0.15:
            nf += 1
            out += ['.figure f%d' % nf, '.alt "A box"', '.PS', 'box wid 2 ht %s "fig %d"' % (random.choice(['0.5', '1', '1.5']), nf), '.PE', '.caption "Figure in a column, number %d."' % nf, '.endfigure']
        if random.random() < 0.08:
            nf += 1
            out += ['.figure* w%d' % nf, '.alt "A wide box"', '.PS', 'box wid 6 ht 1 "wide %d"' % nf, '.PE', '.caption "A figure across both columns, number %d."' % nf, '.endfigure*']
    if sec == 4:
        out += ['.table* tw', '.TS', 'center;', 'l l l l l.', 'a\tb\tc\td\te', '_', '1\t2\t3\t4\t5', '.TE', '.caption "A table across both columns."', '.endtable*']
open(d + '/long.ms', 'w').write('\n'.join(out) + '\n')
open(d + '/one.ms', 'w').write('.columns 1\n' + '\n'.join(out) + '\n')
PY

SDL_VIDEODRIVER=dummy with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; troff d.tr > d.out >[2] d.err; refer -p works.bib -S numeric < num.tr > num.out >[2] num.err;
     book -m article -S numeric -p works.bib article.ms >[2] article.err;
     book -m article long.ms >[2] long.err; book -m article one.ms >[2] one.err;
     book -m memo memo.ms >[2] memo.err; book -m memo report.ms >[2] report.err" </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY'
import re, subprocess, sys, zlib
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:500]))
    fail |= not ok
def read(f):
    try:
        return open(d + '/' + f, encoding='utf-8').read()
    except Exception:
        return ''
err = read('d.err')
check(re.findall(r'^D (\w+)', err, re.M) == ['mac', 'str', 'div'] and 'N never' in err, 'troff: .if d of a macro, a string, a diversion; not of a name never defined', err)

n = read('num.out')
want = ['A first work\\~[1].', 'A second, at a page\\~[2, p.\\~5],', 'and the first again, at a chapter\\~[1, ch. 17]:', 'two at once\\~[3], [4]']
check(all(w in n for w in want), 'refer -S numeric: [n] before the punctuation, numbered as first cited, a page, a chapter, two works', n[:400])
labs = re.findall(r'^\.\]be "(\[\d+\])"\n(.*)', n, re.M)
check([l for l, _ in labs] == ['[1]', '[2]', '[3]', '[4]'] and labs[0][1].startswith('D. E. Knuth, \\fIThe') and
      labs[1][1].startswith('B. W. Kernighan and L. L. Cherry, “A System for Typesetting Mathematics,” \\fICommunications of the ACM\\fP, vol. 18, no. 3, pp.\\~151–157'),
      'refer -S numeric: the references in that order, labelled, initials, vol., no., pp.', labs)

def words(pdf):
    x = subprocess.run(['pdftotext', '-bbox', d + '/' + pdf, '-'], capture_output=True, text=True).stdout
    pages = []
    for p in re.split(r'<page ', x)[1:]:
        W, H = map(float, re.search(r'width="([\d.]+)" height="([\d.]+)"', p).groups())
        ws = [(float(a), float(b), float(c), float(e), t) for a, b, c, e, t in
              re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)</word>', p)]
        pages.append((W, H, ws))
    return pages
def problems(pdf, margin):
    bad = []
    for pn, (W, H, ws) in enumerate(words(pdf), 1):
        for w in ws:
            if w[4].isdigit() and len(w[4]) <= 3:
                continue
            # (the last line's descenders below the margin)
            if w[0] < margin * 72 - 2 or w[2] > W - margin * 72 + 2 or w[1] < margin * 72 - 2 or w[3] > H - margin * 72 + 4:
                bad.append((pn, 'outside', w))
        for i in range(len(ws)):
            for j in range(i + 1, len(ws)):
                a, b = ws[i], ws[j]
                if min(a[2], b[2]) - max(a[0], b[0]) > 1 and min(a[3], b[3]) - max(a[1], b[1]) > 2:
                    bad.append((pn, 'overlap', a, b))
    return bad
def pdfall(pdf):
    try:
        b = open(d + '/' + pdf, 'rb').read()
    except Exception:
        return b''
    t = b
    for m in re.finditer(rb'stream\r?\n(.*?)endstream', b, re.S):
        try:
            t += zlib.decompress(m.group(1))
        except Exception:
            pass
    return t

pg = words('article.pdf')
check(len(pg) == 2, 'article: two pages', (len(pg), read('article.err')[-300:]))
if len(pg) == 2:
    W, H, ws = pg[0]
    mid = W / 2
    title = [w for w in ws if w[4] in ('Setting', 'Whole')]
    check(len(title) == 2 and abs((title[0][0] + title[1][2]) / 2 - mid) < 10, 'article: the title centred across the page', title)
    au = [w for w in ws if w[4] in ('Typesetter', 'Compositor')]
    check(len(au) == 2 and abs(au[0][1] - au[1][1]) < 1 and au[0][2] < mid < au[1][0], 'article: the authors side by side', au)
    intro = [w for w in ws if w[4] == 'Introduction']
    top = intro[0][1] if intro else 0
    body = [w for w in ws if w[1] > top - 2 and w[3] < H - 0.5 * 72]
    left = [w for w in body if w[2] < mid - 5]
    right = [w for w in body if w[0] > mid + 5]
    span = [w for w in body if w[0] < mid - 5 and w[2] > mid + 5]
    check(len(left) > 200 and len(right) > 200 and not span, 'article: the text in two columns below the title', (len(left), len(right), span[:3]))
    note = [w for w in ws if w[4] == 'handful']
    check(note and note[0][2] < mid and note[0][1] > H - 2 * 72, 'article: the note at the foot of its column', note)
    # flush: the columns' last lines of text (the note's aside) level
    lastl = max(w[3] for w in left if w[1] < (note[0][1] - 30 if note else H))
    lastr = max(w[3] for w in right)
    check(abs(lastr - (H - 0.75 * 72)) < 4, 'article: the first page\'s second column flush at the foot', (lastr, H - 54))
    W, H, ws = pg[1]
    cap = [w for w in ws if w[4] == 'pipeline']
    fig = [w for w in ws if w[4] == 'tr2pdf']
    l2 = [w for w in ws if w[2] < mid - 5 and w[1] > 150]
    r2 = [w for w in ws if w[0] > mid + 5 and w[1] > 150]
    check(fig and fig[0][0] > mid and cap and all(w[1] > cap[0][3] for w in l2 + r2 if w[4] not in ('2',)),
          'article: the figure across both columns at the top of the next page, above the text', (fig[:1], cap[:1]))
    if l2 and r2:
        bl, br = max(w[3] for w in l2), max(w[3] for w in r2)
        check(abs(bl - br) <= 26, 'article: the last page\'s columns balanced', (bl, br))
    # the labels: at the left of the column the references are in
    rx = min((w[0] for w in r2), default=0)
    refs = [w[4] for w in ws if re.match(r'\[\d\]$', w[4]) and abs(w[0] - rx) < 3]
    check(refs == ['[1]', '[2]', '[3]', '[4]'], 'article: the references numbered', refs)
t = pdfall('article.pdf')
check(b'pdfuaid' in t and b'/S /H1' in t and b'/S /Figure' in t, 'article: tagged, its title a heading, its figures Figures, claiming PDF/UA-1')
check(not problems('article.pdf', 0.7), 'article: no word overlapping another or outside the margins', problems('article.pdf', 0.7)[:3])
lg = words('long.pdf')
check(len(lg) >= 5 and not problems('long.pdf', 0.7), 'article: six generated pages, notes and floats in and across columns, nothing overlapping', (len(lg), problems('long.pdf', 0.7)[:3], read('long.err')[-200:]))
on = words('one.pdf')
xs = [w[0] for p in on for w in p[2] if w[1] > 200 and not (w[4].isdigit() and len(w[4]) <= 3)]
check(on and not problems('one.pdf', 1.0) and xs and min(xs) >= 1.3 * 72, 'article: one column, its measure narrower, nothing overlapping', (min(xs) if xs else None, problems('one.pdf', 1.0)[:3]))

mp = words('memo.pdf')
check(len(mp) == 1, 'memo: one page', (len(mp), read('memo.err')))
if mp:
    W, H, ws = mp[0]
    lab = {w[4]: w for w in ws if w[4] in ('subject:', 'date:', 'from:', 'TM:', 'MEMORANDUM')}
    ok = len(lab) == 5 and lab['subject:'][0] < W / 3 and lab['date:'][0] > W / 2 and lab['date:'][1] < lab['from:'][1] < lab['TM:'][1] < lab['MEMORANDUM'][1]
    check(ok, 'memo: subject at the left; date, from, TM: at the right; the kind of memorandum below', lab)
rp = words('report.pdf')
if rp:
    W, H, ws = rp[0]
    t = [w for w in ws if w[4] in ('Balancing', 'Article')]
    check(len(t) == 2 and abs((t[0][0] + t[1][2]) / 2 - W / 2) < 10 and not [w for w in ws if w[4] == 'subject:'],
          'memo: .kind report, the title centred, no memorandum head', t)
else:
    check(False, 'memo: .kind report', read('report.err'))
sys.exit(fail)
PY
