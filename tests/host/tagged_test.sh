#!/bin/sh
#
# tagged_test.sh — a book's PDF tagged, for those who hear it read or
# reflow it (PDF/UA-1): book(1) on tests/book/book.ms, with
# tests/book/latex.ms's mathematics, tables and picture (described by
# .alt) after it, and its index:
#
#	the catalogue marked (MarkInfo), its language (en), its title shown
#	(DisplayDocTitle), its metadata claiming PDF/UA-1 with its title;
#	every glyph set and every line drawn marked: an element's (MCID)
#	or an artifact's, never in a text object (BT) nor across one;
#	each page's MCIDs its elements in the parent tree, each MCID's
#	element marking it on that page;
#	the structure the book's: a heading for the title, each chapter
#	(H1) and section (H2), the contents a TOC of entries each a link;
#	the notes (Note), each with its own ID, a quotation (BlockQuote);
#	the equations (Formula) described by their eqn, as written (its
#	characters beyond ASCII whole, troff's \& left out);
#	the tables (Table) in rows (TR) of the same cells (TD, a heading's
#	TH spanning two: ColSpan, Scope), a text block in its own cell, a
#	note at the foot of a page a table breaks across not in it; the
#	picture (Figure) described by its .alt; the index (Index);
#	every link annotation in a Link element, an object of it, described
#	by its text;
#	the running heads and folios artifacts: not in the structure;
#	poppler reads it without complaint;
#	where veraPDF is (verapdf, or $VERAPDF), it conforms to PDF/UA-1;
#	troff's output with no x X tag, a PDF with no structure, as before,
#	and tr2pdf -c (Neatpost's) one with none whatever it is given;
#	a picture with no .alt said, and the PDF not claiming PDF/UA-1.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "tagged_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] && [ -f "$ROOT/dis/eqn.dis" ] ||
    { echo "tagged_test: SKIP (dis not built)"; exit 77; }
python3 -c 'import pypdf' 2>/dev/null || { echo "tagged_test: SKIP (no pypdf)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tagged.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

pass() { echo "PASS: $1"; }
failed() { echo "FAIL: $1"; fail=1; }

inferno() {
    with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c "$1" </dev/null >"$tmp/emu.log" 2>&1
}

# the book, then the mathematics, tables, picture and index, then its
# back matter
python3 -I - tests/book/book.ms tests/book/latex.ms "$tmp" <<'PY'
import sys
book = open(sys.argv[1], encoding='utf-8').read().split('\n.backmatter')[0]
alt = '.alt "A box labelled start, an arrow, then a circle labelled end"\n'
# (not its line of LaTeX's special characters: its $ an equation begun,
# never ended)
maths = ''.join((alt if l.startswith('.PS') else '') + l + '\n'
                for l in open(sys.argv[2], encoding='utf-8').read().split('\n')
                if l and not l.startswith('.printindex') and not l.startswith('Done:'))
# a table broken across a page whose foot has a note
long = ('.chapter "Long Tables" long\n\nIn logic, $\u2200 x ( p \u2192 roman \\&in )$.\n\nA note on the table\\c\n.fn\nThe note.\n.fe\nthat follows.\n'
        '.TS\nbox;\nl n.\nWork\tYear\n_\nA power\t$x sup {2 k}$\n' + ''.join('Row %d\t%d\n' % (i, 1900 + i) for i in range(60)) + '.TE\n')
end = '.backmatter\n.notes\n.bibliography\n.printindex\n'
open(sys.argv[3] + '/t.ms', 'w', encoding='utf-8').write(book + '\n' + maths + long + end)
# the same, its picture not described
open(sys.argv[3] + '/noalt.ms', 'w', encoding='utf-8').write(book + '\n' + maths.replace(alt, '') + long + end)
PY
cp tests/book/works.bib "$tmp/"
inferno "cd '#U*$tmp'; book -f -p works.bib t.ms >[2]t.err; book -p works.bib noalt.ms >[2]noalt.err"
if [ ! -s "$tmp/t.pdf" ]; then
    failed "no PDF: $(cat "$tmp/t.err" "$tmp/emu.log")"
    exit 1
fi

# poppler, where there is one, reads it without complaint
if command -v pdftotext >/dev/null 2>&1; then
    e=$(pdftotext "$tmp/t.pdf" /dev/null 2>&1; pdftoppm -r 10 -f 1 -l 40 "$tmp/t.pdf" "$tmp/pp" 2>&1)
    [ -z "$e" ] && pass "poppler reads it without complaint" || failed "poppler: $e"
    # an equation in a numeric column, which tbl splits at its last
    # digit: its description on one line, none of it set as text
    if pdftotext "$tmp/t.pdf" - 2>/dev/null | grep -q 'end power'; then
        failed "an equation in a numeric column: its description set as text"
    else
        pass "an equation in a numeric column: its description not set as text"
    fi
fi

python3 -I - "$tmp/t.pdf" "$tmp/t.ms" <<'PY' || fail=1
import sys, re, collections
import pypdf
from pypdf.generic import ContentStream, IndirectObject
pdf, src = sys.argv[1:3]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok

r = pypdf.PdfReader(pdf)
cat = r.trailer['/Root']
# a page's operators (a content stream is a dictionary, and false when empty)
def pageops(p):
    c = p.get_contents()
    return ContentStream(c, r).operations if c is not None else []
meta = cat['/Metadata'].get_object().get_data().decode('utf-8')
check(cat.get('/MarkInfo', {}).get('/Marked') == True and cat.get('/Lang') == 'en' and
      cat.get('/ViewerPreferences', {}).get('/DisplayDocTitle') == True and
      '<pdfuaid:part>1</pdfuaid:part>' in meta and 'A Study of Virtue' in meta,
      'the catalogue marked, its language, its title shown, PDF/UA-1 claimed', (dict(cat), meta[:300]))

# the elements, and each one's parent
root = cat['/StructTreeRoot']
elems = []
parent = {}
def walk(ref, par):
    e = ref.get_object()
    elems.append(e)
    parent[id(e)] = par
    k = e.get('/K')
    for x in (k if isinstance(k, list) else [k] if k is not None else []):
        o = x.get_object() if isinstance(x, IndirectObject) else x
        if isinstance(o, dict) and '/S' in o:
            walk(x, e)
walk(root['/K'], None)
types = collections.Counter(e['/S'][1:] for e in elems)
kids = lambda e: [x.get_object() for x in (e['/K'] if isinstance(e.get('/K'), list) else [e['/K']] if '/K' in e else [])]
child = lambda e: [k for k in kids(e) if '/S' in k]

# every glyph and every line marked: an element's or an artifact's, not in a text object
pageobj = {p.indirect_reference.idnum: i for i, p in enumerate(r.pages)}
mcids = {}
bad = []
for i, p in enumerate(r.pages):
    ops = pageops(p)
    mc = []
    bt = 0
    ids = set()
    for args, op in ops:
        if op == b'BT':
            bt = 1
        elif op == b'ET':
            bt = 0
        elif op in (b'BDC', b'BMC'):
            if bt:
                bad.append((i, 'marked content in a text object'))
            mc.append(args[0])
            if op == b'BDC' and '/MCID' in args[1]:
                ids.add(args[1]['/MCID'])
        elif op == b'EMC':
            if bt:
                bad.append((i, 'marked content ended in a text object'))
            if mc:
                mc.pop()
        elif op in (b'TJ', b'Tj', b"'", b'"', b'S', b's', b'f', b'F', b'f*', b'B', b'B*', b'b', b'b*', b'Do'):
            if not mc:
                bad.append((i, 'unmarked ' + op.decode()))
    mcids[i] = ids
nmc = sum(len(v) for v in mcids.values())
check(nmc > 200 and not bad, 'every glyph and line marked, as an element or an artifact, outside text objects',
      (nmc, bad[:5]))

# the parent tree: each page's MCIDs their elements, which mark them on it
nums = root['/ParentTree']['/Nums']
pt = {nums[i]: nums[i + 1] for i in range(0, len(nums), 2)}
wrong = []
for i, p in enumerate(r.pages):
    if not mcids[i]:
        continue
    arr = pt.get(p['/StructParents'])
    if arr is None or len(arr) != len(mcids[i]):
        wrong.append((i, 'parent tree'))
        continue
    for m, ref in enumerate(arr):
        e = ref.get_object()
        if not any(k.get('/Type') == '/MCR' and k['/MCID'] == m and k.raw_get('/Pg').idnum == p.indirect_reference.idnum
                   for k in kids(e)):
            wrong.append((i, m, e['/S']))
check(not wrong, "each page's MCIDs in the parent tree, each its element's", wrong[:5])

# the structure the book's
chapters = sum(1 for l in open(src, encoding='utf-8') if re.match(r'\.chapter\*? ', l))
sections = sum(1 for l in open(src, encoding='utf-8') if l.startswith('.section '))
# the title, the contents, notes, bibliography and index besides the chapters
check(types['H1'] == chapters + 5 and types['H2'] >= sections, 'a heading for the title, each chapter and section',
      (types['H1'], chapters, types['H2'], sections))
toc = [e for e in elems if e['/S'] == '/TOC']
toci = child(toc[0]) if toc else []
check(len(toc) == 1 and len(toci) >= chapters + sections and
      all(e['/S'] == '/TOCI' and any(k['/S'] == '/Link' for k in child(e)) for e in toci),
      'the contents a TOC, each entry a link', [e['/S'] for e in toci][:5])
notes = [e for e in elems if e['/S'] == '/Note']
nids = [e.get('/ID') for e in notes]
check(len(notes) >= 27 + 6 + 1 and None not in nids and len(set(nids)) == len(nids),
      'the notes, each with its own ID', (len(notes), nids[:5]))
check(types['BlockQuote'] >= 1 and types['P'] > 50 and types['Index'] == 1,
      'quotations, paragraphs and the index', types)
forms = [e for e in elems if e['/S'] == '/Formula']
alts = [str(e.get('/Alt')) for e in forms]
check(len(forms) == 8 and 'x squared plus y sub i squared' in alts and 'alpha over beta' in alts and
      'the square root of a plus b, end root' in alts and
      'the sum from i equals 1 to n of x sub i equals the integral from 0 to infinity of '
      'e raised to the power minus x squared, end power, d x' in alts and
      any('the limit as x approaches 0 of the fraction with numerator sin x and denominator x, equals 1' in a
          for a in alts),
      'each equation a Formula, described in words', alts)
tables = [e for e in elems if e['/S'] == '/Table']
rows = [[c for c in child(tr)] for t in tables for tr in child(t)]
def span(c):
    a = c.get('/A')
    return a.get('/ColSpan', 1) if a else 1
widths = [[sum(span(c) for c in row) for row in child_rows] for child_rows in
          [[child(tr) for tr in child(t)] for t in tables]]
th = [c for row in rows for c in row if c['/S'] == '/TH']
check(len(tables) == 3 and all(len(set(w)) == 1 and w[0] == 2 for w in widths) and len(th) == 3 and
      th[0]['/A']['/ColSpan'] == 2 and th[0]['/A']['/Scope'] == '/Column' and len(child(tables[2])) == 62,
      'the tables in rows of cells, the heading spanning two', (widths, [(c['/S'], c.get('/A')) for c in th]))
# a table's kids its rows, a row's its cells: a note set at a page's foot
# between two rows is the table's neighbour
check(all(tr['/S'] == '/TR' and all(c['/S'] in ('/TD', '/TH') for c in child(tr)) for t in tables for tr in child(t)),
      "a table's kids its rows, a row's its cells, a page's notes falling between rows",
      [(t['/S'], [k['/S'] for k in child(t)][:8]) for t in tables])
figs = [e for e in elems if e['/S'] == '/Figure']
check(len(figs) == 1 and figs[0].get('/Alt') == 'A box labelled start, an arrow, then a circle labelled end',
      'the picture a Figure, described by its .alt', [f.get('/Alt') for f in figs])

# every link annotation in a Link, its object, described by its text
links = 0
wrong = []
for i, p in enumerate(r.pages):
    for a in p.get('/Annots') or []:
        o = a.get_object()
        links += 1
        e = pt.get(o.get('/StructParent'))
        e = e.get_object() if e is not None else None
        if (e is None or e['/S'] != '/Link' or
                not any(k.get('/Type') == '/OBJR' and k.raw_get('/Obj').idnum == a.idnum for k in kids(e)) or
                not o.get('/Contents')):
            wrong.append((i, o.get('/Contents')))
check(links > 50 and not wrong, 'every link a Link, its annotation its object, described by its text', wrong[:5])
contents = [a.get_object()['/Contents'] for a in r.pages[2].get('/Annots') or []]
check(any(re.fullmatch(r'1\. On Virtue +1', c) for c in contents), "a contents line's link described as read", contents[:4])

# the running heads and folios not in the structure
art = 0
for i, p in enumerate(r.pages):
    for args, op in pageops(p):
        if op == b'BMC' and args[0] == '/Artifact':
            art += 1
check(art >= len(r.pages) - 4, 'running heads and folios artifacts', (art, len(r.pages)))
sys.exit(fail)
PY

# veraPDF, where there is one
vera=${VERAPDF:-$(command -v verapdf 2>/dev/null)}
if [ -n "$vera" ]; then
    out=$($vera -f ua1 --format text "$tmp/t.pdf" 2>&1)
    case "$out" in
    PASS*) pass "veraPDF: PDF/UA-1" ;;
    *) failed "veraPDF: $out" ;;
    esac
fi

# a picture with no .alt said, and no PDF/UA claimed
grep -q 'a picture with no .alt' "$tmp/noalt.err" &&
    ! LC_ALL=C grep -aq 'pdfuaid:part' "$tmp/noalt.pdf" &&
    LC_ALL=C grep -aq '/MarkInfo' "$tmp/noalt.pdf" &&
    pass "a picture with no .alt said, the PDF tagged but not claiming PDF/UA-1" ||
    failed "no .alt: $(cat "$tmp/noalt.err")"

# with no x X tag, no structure; with -c, none whatever is given
printf 'Plain text, no tags.\n' >"$tmp/plain.tr"
inferno "cd '#U*$tmp'; troff plain.tr | tr2pdf >plain.pdf; troff -mbook plain.tr | tr2pdf -c >compat.pdf"
if [ -s "$tmp/plain.pdf" ] && [ -s "$tmp/compat.pdf" ] &&
    ! LC_ALL=C grep -aq 'StructTreeRoot\|MarkInfo' "$tmp/plain.pdf" &&
    ! LC_ALL=C grep -aq 'StructTreeRoot\|MarkInfo\|/MCID' "$tmp/compat.pdf"; then
    pass "no x X tag, no structure; -c, none"
else
    failed "untagged: $(cat "$tmp/emu.log")"
fi

exit $fail
