#!/bin/sh
#
# quality_test.sh — a book as it goes to press (book -f) set as well as
# LaTeX sets it:
#
#	its paragraphs broken whole (.ad p), their spaces able to shrink
#	(.ssh), hyphens costly (.hycost): of a page of prose in long words,
#	few lines end in a hyphen and never three in a row, and one space
#	follows a sentence ending a line of the source, not two;
#	a section's number before its title, as the contents give it, and
#	none in the front matter;
#	the bibliography in the Manual's order: a work by an author alone
#	before those with others, those by the others' names;
#	mathematics with Libertinus Math's parameters (eqnrc): a function's
#	name apart from what is before it (a cos, not acos), scripts 80%
#	of the text's size (9 points of 11), an integral's limits beside
#	it, as TeX sets them.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "quality_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] && [ -f "$ROOT/dis/eqn.dis" ] ||
    { echo "quality_test: SKIP (dis not built)"; exit 77; }
command -v pdftotext >/dev/null 2>&1 || { echo "quality_test: SKIP (no pdftotext)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "quality_test: SKIP (no python3)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/quality.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/works.bib" <<'EOF'
@book{solo, author = {Dubois, Gil}, title = {Zeal and Its Uses}, publisher = {Haddad Press}, year = 1990}
@book{withh, author = {Dubois, Gil and Haddad, Ann}, title = {Another Account}, publisher = {Haddad Press}, year = 1991}
@book{witha, author = {Dubois, Gil and Ahlberg, Eun}, title = {Yet Another}, publisher = {Haddad Press}, year = 1992}
EOF

# prose in long words, a sentence a line, as troff's sources are written
python3 -I - "$tmp/q.ms" <<'PY'
import sys
prose = """Considerable administrative responsibility accompanies the establishment of international organizations.
Representatives from participating governments negotiate extraordinarily complicated agreements concerning jurisdiction, compensation and accountability.
Notwithstanding considerable disagreement, the commissioners ultimately recommended comprehensive institutional reorganization.
Contemporaneous correspondence demonstrates characteristically meticulous preparation by the secretariat.
Unquestionably, the implementation of these recommendations necessitated substantial expenditure, unprecedented cooperation and remarkable determination.
Philosophical considerations, particularly regarding responsibility and representation, complicated otherwise straightforward administrative arrangements.
Nevertheless, the organization's establishment represented an extraordinary accomplishment, and historians consistently characterize the negotiations as transformative."""
out = ['.title "Quality"', '.author "Test"', '.EQ', 'delim $$', '.EN', '.maketitle', '.frontmatter',
       '.contents', '.chapter* "Preface"', '.section "A Note on the Text"', '', 'Unnumbered, being in the front matter.',
       '.mainmatter', '.chapter "Prose" prose', '.section "The Organization" org', '']
for i in range(6):
    out += prose.split('\n') + ['']
out += ['Mathematics: $a cos theta + b sin theta$ and $x sup 2$.', '.EQ', 'int from 0 to inf e sup {-x} dx = 1', '.EN',
        '', 'Cited.\\c', '.cite solo 1', 'Again.\\c', '.cite withh 2', 'And again.\\c', '.cite witha 3',
        '.backmatter', '.bibliography']
open(sys.argv[1], 'w').write('\n'.join(out) + '\n')
# the same as -mbook set it before: line by line, spaces only stretching,
# hyphens free, two spaces after a sentence
old = ['.de book-fill', '.ad b', '.ssh 0', '.hycost 0 0 0', '.hlm 0', '.ss 12 12', '..']
open(sys.argv[1].replace('q.ms', 'o.ms'), 'w').write('\n'.join(old + out) + '\n')
PY
with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; book -f -p works.bib q.ms >[2]q.err; book -f -p works.bib o.ms >[2]o.err" </dev/null >"$tmp/emu.log" 2>&1
if [ ! -s "$tmp/q.pdf" ] || [ ! -s "$tmp/o.pdf" ]; then
    echo "FAIL: no PDF: $(cat "$tmp/q.err" "$tmp/emu.log")"
    exit 1
fi
for f in q o; do
    pdftotext "$tmp/$f.pdf" "$tmp/$f.txt" 2>/dev/null
    pdftotext -layout "$tmp/$f.pdf" "$tmp/${f}l.txt" 2>/dev/null
    pdftotext -bbox "$tmp/$f.pdf" "$tmp/$f.html" 2>/dev/null
done

python3 -I - "$tmp" <<'PY' || fail=1
import sys, re, html
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok

text = open(d + '/q.txt', encoding='utf-8').read()

# the prose: its lines ending in a hyphen, and the most in a row
def hyphens(f):
    lines = [l.rstrip() for l in open(d + '/' + f, encoding='utf-8').read().split('\n')]
    body = [l for l in lines if len(l.split()) >= 6 and not re.search(r'\.\s*\.\s*\.', l)]
    hy = [l.endswith('-') or l.endswith('\u2010') for l in body]
    run = best = 0
    for h in hy:
        run = run + 1 if h else 0
        best = max(best, run)
    return sum(hy), len(body), best
new, old = hyphens('ql.txt'), hyphens('ol.txt')
check(new[1] > 60 and new[0] * 3 < old[0] * 2 and new[2] <= 3 and new[2] < old[2],
      'fewer lines hyphenated than set line by line, never four in a row (%d of %d, %d in a row; before, %d of %d, %d)' %
      (new + old), (new, old))

# section numbers: in the heading as in the contents; none in the front matter
check(len(re.findall(r'1\.1\s+The Organization', text)) >= 2 and
      not re.search(r'\d\.\d\s+A Note on the Text', text) and 'A Note on the Text' in text,
      "a section's number before its title, as the contents give it; none in the front matter",
      re.findall(r'.{0,8}(?:The Organization|A Note on the Text)', text))

# the bibliography: alone first, then by the others' names
b = text[text.rfind('Bibliography'):]
order = [b.find(s) for s in ('Zeal and Its Uses', 'Yet Another', 'Another Account')]
check(min(order) >= 0 and order == sorted(order), "the bibliography in the Manual's order", order)

# the words' boxes
def boxes(f):
    return [(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
            re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<',
                       open(d + '/' + f, encoding='utf-8').read())]
words = boxes('q.html')
ws = [w[4] for w in words]

# one space after a sentence: the gap after a full stop, in its line, as
# the line's others (its median); two, as before, about twice
ends = ('organizations.', 'accountability.', 'reorganization.', 'secretariat.', 'determination.', 'arrangements.')
def sentgap(words):
    rows = {}
    for w in words:
        rows.setdefault(round(w[3]), []).append(w)
    ratios = []
    for r in rows.values():
        r.sort()
        gaps = [(b[0] - a[2], a[4]) for a, b in zip(r, r[1:])]
        other = sorted(g for g, t in gaps if not t.endswith('.'))
        if len(r) >= 6 and other and other[len(other) // 2] > 0:
            med = other[len(other) // 2]
            ratios += [g / med for g, t in gaps if t in ends and 0 < g < 4 * med]
    ratios.sort()
    return ratios[len(ratios) // 2] if ratios else 0, len(ratios)
new, old = sentgap(words), sentgap(boxes('o.html'))
check(new[1] >= 5 and new[0] < 1.25 and old[0] > 1.5, 'one space after a sentence, not two', (new, old))

# the mathematics
check('cos' in ws and 'sin' in ws and 'acos' not in ws and 'bsin' not in ws,
      "a function's name apart from what comes before it", [w for w in ws if 'cos' in w or 'sin' in w])
x = [w for w in words if w[4].startswith('x')]
two = [w for w in words if w[4] == '2' and x and abs(w[0] - min(x, key=lambda v: abs(v[2] - w[0]))[2]) < 2]
ratio = (two[0][3] - two[0][1]) / (x[0][3] - x[0][1]) if two and x else 0
check(0.75 < ratio < 0.9, "a superscript 80% of the text's size", (ratio, two[:1], x[:1]))
integ = [w for w in words if w[4] == '∫']
zero = [w for w in words if w[4] == '0']
inf = [w for w in words if w[4] == '∞']
beside = integ and zero and inf and zero[-1][0] > integ[-1][2] - 1 and inf[-1][0] > integ[-1][2] - 1
check(bool(beside), "an integral's limits beside it", (integ, zero[-1:], inf[-1:]))
sys.exit(fail)
PY

exit $fail
