#!/bin/sh
#
# logos_test.sh — TeX's and LaTeX's logos, \*[TeX] and \*[LaTeX]
# (lib/tmac/tmac.logos), under -mbook and -ms:
#
#	set as plain.tex and latex.ltx set them: TeX's E lowered half an ex
#	between kerns of a sixth and an eighth of an em; LaTeX's A at seven
#	tenths of the size, raised until its top is the T's, after a kern of
#	.36 em and before one of .15; in a heading's size as in the text's;
#	read as the words they spell (tr2pdf's x X text, a marked-content
#	ActualText): pdftotext gives TeX and LaTeX, and a heading's bookmark
#	does too;
#	written by book2tex as LaTeX's \TeX{} and \LaTeX{}.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "logos_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] && [ -f "$ROOT/dis/book2tex.dis" ] ||
    { echo "logos_test: SKIP (dis not built)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/logos.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pass() { echo "PASS: $1"; }
failed() { echo "FAIL: $1"; fail=1; }

cat >"$tmp/l.ms" <<'EOF'
.chapter "Typesetting with \*[TeX] and \*[LaTeX]"

Knuth wrote \*[TeX]; Lamport, \*[LaTeX].
EOF
printf '.LP\nThe word \\*[LaTeX] in -ms.\n' >"$tmp/s.ms"
with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff -mbook l.ms > l.out >[2] l.err; tr2pdf l.out > l.pdf; troff -ms s.ms > s.out; tr2pdf s.out > s.pdf; book2tex -o l.tex l.ms >[2] tex.err" </dev/null >"$tmp/emu.log" 2>&1

# troff's output: each logo's glyphs, their sizes and places
if command -v python3 >/dev/null 2>&1; then
    if python3 -I - "$tmp/l.out" "$tmp/s.out" <<'PY'
import re, sys
def glyphs(path):
    d = open(path, encoding='utf-8', errors='replace').read()
    res = 720; s = 10; h = v = 0; out = []
    for m in re.finditer(r'x res (\d+)|s(\d+)|H(-?\d+)|V(-?\d+)|h(-?\d+)|v(-?\d+)|c(.)|\n', d):
        if m.group(1): res = int(m.group(1))
        elif m.group(2): s = int(m.group(2))
        elif m.group(3): h = int(m.group(3))
        elif m.group(4): v = int(m.group(4))
        elif m.group(5): h += int(m.group(5))
        elif m.group(6): v += int(m.group(6))
        elif m.group(7): out.append((m.group(7), s, h, v))
    return res, out
bad = []
for path in sys.argv[1:]:
    res, g = glyphs(path)
    txt = ''.join(c for c, *_ in g)
    for i in [m.start() for m in re.finditer('LATEX', txt)]:
        L, A, T, E, X = g[i:i + 5]
        size = L[1]
        em = size * res / 7200 if size > 200 else size * res / 72   # (devutf's hundredths of a point)
        if abs(A[1] / size - 0.7) > 0.01: bad.append('%s: the A at %d of %d' % (path, A[1], size))
        if abs((L[3] - A[3]) - 0.192 * em) > 0.02 * em: bad.append('%s: the A raised %d, not %.0f' % (path, L[3] - A[3], 0.192 * em))
        if abs((E[3] - T[3]) - 0.2145 * em) > 0.02 * em: bad.append('%s: the E lowered %d' % (path, E[3] - T[3]))
        if not (L[3] == T[3] == X[3]): bad.append('%s: L, T, X not on one baseline' % path)
    if 'LATEX' not in txt: bad.append(path + ': no LaTeX set')
    if path.endswith('l.out') and txt.count('TEX') < 4: bad.append(path + ': TeX set %d times' % txt.count('TEX'))
for b in bad: print('    ' + b)
sys.exit(1 if bad else 0)
PY
    then pass "set as their logos: the A at seven tenths, raised to the T's top; the E lowered half an ex"
    else failed "the logos' glyphs"; fi
fi

# read as the words they spell
if command -v pdftotext >/dev/null 2>&1; then
    t=$(pdftotext "$tmp/l.pdf" - 2>/dev/null | tr '\n' ' ')
    s=$(pdftotext "$tmp/s.pdf" - 2>/dev/null | tr '\n' ' ')
    case "$t$s" in
    *"Typesetting with TeX and LaTeX"*"Knuth wrote TeX; Lamport, LaTeX."*"The word LaTeX in -ms."*)
        pass "read as TeX and LaTeX (ActualText), in a heading and the text, under -mbook and -ms" ;;
    *) failed "read as: $t | $s" ;;
    esac
fi
if command -v python3 >/dev/null 2>&1 && python3 -c 'import pypdf' 2>/dev/null; then
    o=$(python3 -c 'import pypdf,sys; print([x.title for x in pypdf.PdfReader(sys.argv[1]).outline if not isinstance(x, list)])' "$tmp/l.pdf")
    case "$o" in
    *"Typesetting with TeX and LaTeX"*) pass "the heading's bookmark reads TeX and LaTeX" ;;
    *) failed "the bookmark: $o" ;;
    esac
fi

# LaTeX's own
if grep -q 'Typesetting with \\TeX{} and \\LaTeX{}' "$tmp/l.tex" && grep -q 'Knuth wrote \\TeX{}; Lamport, \\LaTeX{}\.' "$tmp/l.tex" &&
    [ ! -s "$tmp/tex.err" ]; then
    pass "book2tex writes \\TeX{} and \\LaTeX{}"
else failed "book2tex: $(grep -n 'TeX' "$tmp/l.tex" | head -3) $(cat "$tmp/tex.err")"; fi

exit $fail
