#!/bin/sh
#
# floats_test.sh — a book's figures and tables float (-mbook's .figure
# and .table, as LaTeX's figure and table environments):
#
#	one written between paragraphs, with room for it, set there;
#	one written in a paragraph, with room, set after the paragraph
#	(LaTeX's [h], as near as a paragraph not broken for it allows);
#	one written in a paragraph, too tall for the room left, set at the
#	top of the next page, the paragraph unbroken where it was written;
#	one still waiting when its chapter ends set before the next begins;
#	numbered in their chapters (1.1, 1.2, 2.1), tables apart from
#	figures, a caption above a table and below a figure;
#	a label's \*[ref] the number, its \*[pageref] the page it is set on;
#	the lists of figures and tables, each entry its page and a link to
#	its caption, a long caption filled under its first line;
#	tagged: each a Div holding its Caption and its Figure or Table, and,
#	where veraPDF is (verapdf, or $VERAPDF), PDF/UA-1;
#	its pages still flush at the foot;
#	book2tex writes them as LaTeX's figure and table environments, a
#	caption and label each, and the lists; where LuaLaTeX is, it sets
#	them without an error, numbered as the book numbers them.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "floats_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] && [ -f "$ROOT/dis/pic.dis" ] && [ -f "$ROOT/dis/tbl.dis" ] ||
    { echo "floats_test: SKIP (dis not built)"; exit 77; }
command -v pdftotext >/dev/null 2>&1 || { echo "floats_test: SKIP (no pdftotext)"; exit 77; }
python3 -c 'import pypdf' 2>/dev/null || { echo "floats_test: SKIP (no pypdf)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/floats.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

python3 -I - "$tmp/f.ms" <<'PY'
import sys
para = ("Considerable administrative responsibility accompanies the establishment of international organizations.\n"
        "Representatives from participating governments negotiate extraordinarily complicated agreements concerning jurisdiction.\n"
        "Notwithstanding considerable disagreement, the commissioners ultimately recommended comprehensive reorganization.\n")
def fig(lab, h, what):
    return ('.figure %s\n.alt "A box"\n.PS\nbox wid 3 ht %s "%s"\n.PE\n.caption "%s"\n.endfigure\n' %
            (lab, h, what, what))
tab = ('.table nums\n.caption "Some numbers, in a table whose caption is long enough that it is filled over two lines '
       'in the list of tables as well as under the table"\n.TS\ncenter box;\nc c\nn n.\nYear\tValue\n' +
       ''.join('%d\t%d\n' % (1990 + i, i * i) for i in range(12)) + '.TE\n.endtable\n')
out = ['.title "Floats"', '.author "Test"', '.maketitle', '.frontmatter', '.contents', '.listoffigures',
       '.listoftables', '.mainmatter', '.chapter "One" one', '', para + 'Firstword ends here.', '',
       fig('small', '1.0', 'Small box'), '',
       'Secondword begins here, after the small figure.', 'See \\*[ref big] on page \\*[pageref big].', '']
out += [para] * 2
# a paragraph with a tall figure in it, where it cannot fit
out += [para, para + 'Alphaword', fig('big', '5.5', 'Big box').rstrip('\n'), 'omegaword goes on.', '']
out += [para] * 3 + [tab] + [para] * 4
# the chapter's last, too tall for what is left of its page
out += [para, fig('last', '6', 'Last box')]
# a small figure written in a paragraph, with room: after the paragraph
out += ['.chapter "Two" two', '', 'A short paragraph, its Midword', fig('mid', '0.6', 'Box in a paragraph').rstrip('\n'),
        'endword ends it.', '', 'Nextword begins the next.', '']
out += ['', para, '', fig('twobox', '1.0', 'Box of two'), '', para]
open(sys.argv[1], 'w').write('\n'.join(out) + '\n')
PY
with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; book -f f.ms >[2]f.err; book2tex -o t.tex f.ms >[2]t.err" </dev/null >"$tmp/emu.log" 2>&1
if [ ! -s "$tmp/f.pdf" ]; then
    echo "FAIL: no PDF: $(cat "$tmp/f.err" "$tmp/emu.log")"
    exit 1
fi
pdftotext -bbox "$tmp/f.pdf" "$tmp/f.html" 2>/dev/null
pdftotext -layout "$tmp/f.pdf" "$tmp/fl.txt" 2>/dev/null

python3 -I - "$tmp" <<'PY' || fail=1
import sys, re, html
import pypdf
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok

r = pypdf.PdfReader(d + '/f.pdf')
labels = list(r.page_labels)
pages = [[(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
          re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
         for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/f.html', encoding='utf-8').read(), re.S)]
def find(w, after=0):
    for i, p in enumerate(pages):
        if i >= after:
            for b in p:
                if b[4] == w:
                    return i, b
    return None, None
def caption(n):
    for i, p in enumerate(pages):
        for a, b in zip(p, p[1:]):
            if a[4] in ('Figure', 'Table') and b[4] == n + '.' and i > 4:
                return i, a
    return None, None
body = lambda p: [b for b in p if 12 < b[3] - b[1] < 13]

# between paragraphs, with room: there
pf, first = find('Firstword', 5)
ps, second = find('Secondword', 5)
pc, cap = caption('1.1')
check(pf == ps == pc and first[3] < cap[1] < second[1], 'a figure with room for it set where it is written',
      (pf, ps, pc, first, cap, second))

# in a paragraph, without room: the next page's top, the paragraph whole
pa, alpha = find('Alphaword', 5)
po, omega = find('omegaword', 5)
pc, cap = caption('1.2')
together = pa == po and (abs(alpha[3] - omega[3]) < 1 and omega[0] > alpha[2] or
                         omega[1] > alpha[3] and omega[0] < alpha[0])
top = pc == pa + 1 and pages[pc] and all(cap[1] < b[1] for b in body(pages[pc]) if b[4] not in ('Figure', '1.2.', 'Big', 'box'))
check(together, 'the paragraph it was written in goes on unbroken', (alpha, omega))
check(top, 'a figure without room for it set at the next page\'s top', (pa, pc, cap))

# in a paragraph, with room: after it, before the next
pm, mid = find('Midword', 5)
pe, end = find('endword', 5)
pn, nxt = find('Nextword', 5)
pc, cap = caption('2.1')
check(pm == pe == pn == pc and end[3] < cap[1] < nxt[1], 'a figure written in a paragraph, with room, set after it',
      (pm, pe, pn, pc, end, cap, nxt))

# the chapter's last: set before the next chapter
pl, cap = caption('1.3')
ph, two = find('Two', 5)
check(pl is not None and ph is not None and pl < ph, 'a float still waiting at its chapter\'s end set in it', (pl, ph))

# numbers: in their chapters, tables apart; a table's caption above it
pt, tcap = caption('1.1')
pt = [i for i, p in enumerate(pages) if any(a[4] == 'Table' and b[4] == '1.1.' for a, b in zip(p, p[1:]))]
p2, c2 = caption('2.1')
check(pt and p2 is not None and c2 and any(b[4] == 'Box' for b in pages[p2]), 'numbered in their chapters, tables apart', (pt, p2))
if pt:
    t = pt[0]
    tc = [a for a, b in zip(pages[t], pages[t][1:]) if a[4] == 'Table' and b[4] == '1.1.'][0]
    year = [b for b in pages[t] if b[4] == 'Year']
    check(year and tc[3] < year[0][1], 'a table\'s caption above it', (tc, year[:1]))

# references: the number and the page
txt = open(d + '/fl.txt', encoding='utf-8').read()
m = re.search(r'See (\S+) on page (\S+)\.', txt)
pc, cap = caption('1.2')
check(m and m.group(1) == '1.2' and pc is not None and m.group(2) == labels[pc], '\\*[ref] and \\*[pageref] its number and page',
      (m and m.groups(), pc is not None and labels[pc]))

# the lists: each entry's page where its caption is, a link to it
heading = lambda t: re.search(r'\n\s*' + t + r'\s*\n', txt).end()
lof = txt[heading('List of Figures'):heading('List of Tables')]
ents = re.findall(r'^\s*(\d\.\d)\s+.*?(\S+)\s*$', lof, re.M)
want = []
for n in ('1.1', '1.2', '1.3', '2.1', '2.2'):
    p, c = caption(n)
    want.append((n, labels[p] if p is not None else None))
check(ents == want, 'the list of figures: each entry its page', (ents, want))
lot = txt[heading('List of Tables'):]
lot = lot[:lot.find('\f')]
ll = [l for l in lot.split('\n') if l.strip()]
ind = lambda l: len(l) - len(l.lstrip())
check(len(ll) >= 3 and re.match(r'\s*1\.1\s+Some numbers', ll[0]) and ind(ll[1]) > ind(ll[0]) and
      re.search(r'\.\s+\S+\s*$', ll[-2]) and not re.search(r'\.\s+\S+\s*$', ll[0]),
      'a long caption filled in its list, under its first line', ll)
links = 0
for i in range(len(r.pages)):
    if 'List of Figures' in (r.pages[i].extract_text() or ''):
        for a in r.pages[i].get('/Annots', []) or []:
            a = a.get_object()
            if a.get('/Subtype') == '/Link':
                links += 1
check(links >= 4, 'each entry in the list of figures a link', links)

# tagged: a Div of its Caption and its Figure or Table
cat = r.trailer['/Root']
divs = []
def walk(e):
    e = e.get_object()
    k = e.get('/K')
    ks = k if isinstance(k, list) else [k] if k is not None else []
    ks = [x.get_object() for x in ks]
    kids = [x for x in ks if hasattr(x, 'get') and '/S' in x]
    if e.get('/S') == '/Div':
        divs.append(sorted(set(str(x['/S']) for x in kids)))
    for x in kids:
        walk(x)
walk(cat['/StructTreeRoot'])
check(divs.count(['/Caption', '/Figure']) == 5 and divs.count(['/Caption', '/Table']) == 1,
      'each a Div of its Caption and its Figure or Table', divs)

# pages flush at the foot: those with text, but each chapter's last
text = [i for i, p in enumerate(pages) if i > 7 and len(body(p)) > 20]
chap = [i for i, p in enumerate(pages) if [b[4] for b in p[:1]] == ['Chapter']] + [len(pages)]
last = [max(i for i in text if i < c) for c in chap[1:]]
feet = [round(max(b[3] for b in body(pages[i])), 1) for i in text if i not in last]
check(len(feet) >= 4 and max(feet) - min(feet) < 0.5, 'its pages flush at the foot', feet)
sys.exit(fail)
PY

# as LaTeX
python3 -I - "$tmp/t.tex" <<'PY' || fail=1
import sys, re
t = open(sys.argv[1], encoding='utf-8').read()
envs = re.findall(r'\\begin\{(figure|table)\}\[tbp\]\n\\centering\n(?:.*\n)*?\\caption\{([^}]*)\}\n\\label\{(\w+)\}\n(?:.*\n)*?\\end\{\1\}', t)
ok = [(e, l) for e, c, l in envs] == [('figure', 'small'), ('figure', 'big'), ('table', 'nums'), ('figure', 'last'), ('figure', 'mid'), ('figure', 'twobox')]
ok = ok and '\\listoffigures' in t and '\\listoftables' in t and '\\begin{center}' not in t
print(('PASS: ' if ok else 'FAIL: ') + 'book2tex: figure and table environments, captioned and labelled, and the lists' +
      ('' if ok else ': ' + str(envs)[:300]))
sys.exit(not ok)
PY
if command -v lualatex >/dev/null 2>&1; then
    if (cd "$tmp" && lualatex -interaction=nonstopmode -halt-on-error t.tex >/dev/null 2>&1 &&
        lualatex -interaction=nonstopmode -halt-on-error t.tex >/dev/null 2>&1); then
        n=$(pdftotext -layout "$tmp/t.pdf" - | sed -n '/List of Figures/,/List of Tables/p' | grep -oE '^ *[12]\.[0-9]' | tr -d ' ' | tr '\n' ' ')
        [ "$n" = "1.1 1.2 1.3 2.1 2.2 " ] && echo "PASS: LuaLaTeX sets them, numbered as the book" ||
            { echo "FAIL: LuaLaTeX's list of figures: $n"; fail=1; }
    else
        echo "FAIL: LuaLaTeX: $(grep -A3 '^!' "$tmp/t.log" | head -8)"
        fail=1
    fi
fi

# PDF/UA-1, where veraPDF is
vera=${VERAPDF:-$(command -v verapdf 2>/dev/null)}
if [ -n "$vera" ] && [ -x "$vera" ]; then
    if "$vera" --flavour ua1 --format text "$tmp/f.pdf" 2>/dev/null | grep -q '^PASS'; then
        echo "PASS: veraPDF: PDF/UA-1"
    else
        echo "FAIL: veraPDF: $("$vera" --flavour ua1 --format text "$tmp/f.pdf" 2>&1 | tail -5)"
        fail=1
    fi
fi

exit $fail
