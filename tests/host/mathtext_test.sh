#!/bin/sh
#
# mathtext_test.sh — mathematics in running text and displays aligned,
# set by book(1) from tests/eqn/text.ms as XeLaTeX sets book2tex's LaTeX
# of it:
#
#	an inline lim's limits beside it, as TeX's in text (lim's eqnrc
#	definition braced, so that from is an operator's);
#	an inline sum the math font's, not the text font's glyph of the
#	same name (Libertinus Serif's summation);
#	the paragraph after .p indented, text having followed the heading;
#	displays lined up (eqn's lineup) a baseline and TeX's \jot apart,
#	as align's lines, their signs one above the other;
#	less space above and below a display after a short line (TeX's
#	\abovedisplayshortskip, \belowdisplayshortskip);
#	book2tex: those displays one align, each line its \tag; the hard
#	displays' aligned matrix (matrix -100 { rcol ... lcol ... }) as
#	aligned; eqnrc's names (nabla, oiint) as LaTeX's.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "mathtext_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/eqn.dis" ] && [ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/book2tex.dis" ] ||
    { echo "mathtext_test: SKIP (dis not built)"; exit 77; }
command -v pdftotext >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1 ||
    { echo "mathtext_test: SKIP (no pdftotext or python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/mathtext.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cp tests/eqn/text.ms tests/eqn/hard.ms "$tmp/"
# a maths italic letter alone: a glyph with no name of its
# own (troff's GID=u1D465), which the document views find by
# its id
printf '.EQ\nx\n.EN\n' >"$tmp/ital.ms"
cat >"$tmp/disp.ms" <<'MS'
.chapter "Displays" d
Thus before:
.EQ
x = 1
.EN
after1.
.p
A line that passes the display,\h'2.5i'here:
.EQ
x = 1
.EN
after2.
MS

with_timeout 180 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; book text.ms >[2] book.err; book2tex -o text.tex text.ms >[2] tex.err; book2tex -o hard.tex hard.ms >[2] hard.err; book disp.ms >[2] disp.err; cat /lib/troff/eqnrc ital.ms | eqn | troff -ms > ital.out; tr2img -r 300 ital.out > ital.ppm" \
    </dev/null >"$tmp/emu.log" 2>&1
if [ ! -s "$tmp/text.pdf" ]; then
    echo "FAIL: no PDF: $(cat "$tmp/book.err" | head -3)"
    exit 1
fi
pdftotext -bbox "$tmp/text.pdf" "$tmp/text.html" 2>/dev/null
pdftotext -bbox "$tmp/disp.pdf" "$tmp/disp.html" 2>/dev/null

python3 -I - "$tmp" <<'PY'
import sys, re, html, unicodedata
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:300]))
    fail |= not ok
words = [(float(a), float(b), float(c), float(e), unicodedata.normalize('NFKC', html.unescape(w))) for a, b, c, e, w in
         re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<',
                    open(d + '/text.html', encoding='utf-8').read())]
tr = open(d + '/text.out', encoding='utf-8').read()

# the inline lim: n→∞ beside it, not under it
lim = [w for w in words if w[4] == 'lim']
nl = [w for w in words if w[4].startswith('n→∞')]
check(lim and nl and nl[0][0] >= lim[0][2] - 0.5 and nl[0][1] < lim[0][3],
      "an inline lim's limits beside it", (lim[:1], nl[:1]))

# the inline sum's glyph from the math font (S)
fonts = dict(re.findall(r'(?m)^x font (\d+) (\S+)$', tr))
cur = None
sumf = []
for l in tr.split('\n'):
    m = re.match(r'^f(\d+)$', l)
    if m:
        cur = fonts.get(m.group(1))
    elif l.startswith('CGID=summation'):
        sumf.append(cur)
check(sumf and all(f == 'S' for f in sumf), 'an inline sum from the math font', sumf)

# the paragraph after .p indented: its first word in from the margin
lm = min(w[0] for w in words if 11 < w[3] - w[1] < 13.5)
num = [w for w in words if w[4] == 'Numbered']
check(num and num[0][0] > lm + 8, 'the paragraph after .p indented', (num[:1], lm))

# the lined-up displays: (1.3) to (1.5) a baseline and 3 points apart,
# their signs one above the other
labs = {w[4]: w for w in words if re.match(r'^\(1\.[345]\)$', w[4])}
eqs = sorted([w for w in words if w[4] in ('=', '≥') and labs and min(abs(w[3] - l[3]) for l in labs.values()) < 2],
             key=lambda w: w[1])
gaps = [labs['(1.4)'][3] - labs['(1.3)'][3], labs['(1.5)'][3] - labs['(1.4)'][3]] if len(labs) == 3 else []
check(gaps and all(14 < g < 19.5 for g in gaps) and len(eqs) >= 3 and max(w[0] for w in eqs[-3:]) - min(w[0] for w in eqs[-3:]) < 1,
      "displays lined up a baseline and \\jot apart, aligned", (gaps, [(w[4], w[0]) for w in eqs]))

# a display after a short line closer to it than one after a line
# reaching past its left edge (TeX's \abovedisplayshortskip), the line
# after it too (\belowdisplayshortskip)
dw = [(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
      re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<',
                 open(d + '/disp.html', encoding='utf-8').read())]
def at(t):
    return [w[3] for w in dw if w[4] == t or (t == '=' and '=' in w[4])]
try:
    (b1,), (h2,), (e1, e2), (a1,), (a2,) = at('before:'), at('here:'), at('='), at('after1.'), at('after2.')
    above = (e1 - b1, e2 - h2)
    below = (a1 - e1, a2 - e2)
except ValueError:
    above = below = (0, 0)
check(above[0] and above[0] < above[1] - 4 and below[0] < below[1] - 1,
      'less space above and below a display after a short line', (above, below))

# tr2img (troffpage, Xenith's view): a maths italic letter painted
try:
    b = open(d + '/ital.ppm', 'rb').read()
    m = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', b)
    px = b[m.end():]
    ink = sum(1 for i in range(0, len(px), 3) if px[i] < 128)
except Exception as e:
    ink = str(e)
check(isinstance(ink, int) and ink > 40, 'the document views paint a maths italic letter (a glyph by its id)', ink)

# book2tex
tex = open(d + '/text.tex', encoding='utf-8').read()
al = re.search(r'\\begin\{align\}(.*?)\\end\{align\}', tex, re.S)
check(al and al.group(1).count('&') == 3 and al.group(1).count('\\tag{') == 3,
      'book2tex: the lined-up displays one align, each its \\tag', al.group(1) if al else tex[-400:])
hard = open(d + '/hard.tex', encoding='utf-8').read()
err = open(d + '/hard.err').read()
check('\\begin{aligned}' in hard and '\\nabla' in hard and '\\oiint' in hard and 'out of place' not in err,
      "book2tex: an aligned matrix as aligned; nabla, oiint", err[:200])
sys.exit(fail)
PY
