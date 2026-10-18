#!/bin/sh
#
# maths_test.sh — eqn with /lib/troff/eqnrc against displays known to be
# hard to set (tests/eqn/hard.ms), set beside XeLaTeX's in Libertinus
# Math; each check where TeX's rules (and the font's MATH table) put
# what is checked:
#
#	a root's degree small, raised, before its radical (root n x);
#	an integral's lower limit under its tail (its italic correction),
#	the upper at its right;
#	a matrix's columns each as wide as its widest cell, not all as wide
#	as the widest;
#	a relation after {} spaced as one (TeX's {} an ordinary atom);
#	capital Greek upright, as TeX's;
#	a fraction in an exponent in scriptscript size (TeX's styles for a
#	fraction's parts);
#	braces over and under, of the font's sizes and pieces;
#	the 22 displays on 22 pages, nothing said on the standard error;
#	book2tex: root, overbrace, underbrace and displaystyle as LaTeX's.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "maths_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/eqn.dis" ] && [ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] ||
    { echo "maths_test: SKIP (dis not built)"; exit 77; }
command -v pdftotext >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1 ||
    { echo "maths_test: SKIP (no pdftotext or python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/maths.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; eqn /lib/troff/eqnrc /tests/eqn/hard.ms > hard.eq >[2] eqn.err; troff hard.eq > hard.tr >[2] troff.err; tr2pdf hard.tr > hard.pdf >[2] pdf.err; book2tex -o hard.tex /tests/eqn/hard.ms >[2] tex.err" \
    </dev/null >"$tmp/emu.log" 2>&1
if [ ! -s "$tmp/hard.pdf" ]; then
    echo "FAIL: no PDF: $(cat "$tmp/eqn.err" "$tmp/troff.err" "$tmp/pdf.err" 2>/dev/null | head -5)"
    exit 1
fi
pdftotext -bbox "$tmp/hard.pdf" "$tmp/hard.html" 2>/dev/null

python3 -I - "$tmp" <<'PY'
import sys, re, html
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok
pages = [[(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
          re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
         for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/hard.html', encoding='utf-8').read(), re.S)]
err = ''.join(open(d + '/' + f).read() for f in ('eqn.err', 'troff.err', 'pdf.err'))
tr = open(d + '/hard.tr', encoding='utf-8').read()
def pg(n):
    return pages[n - 1] if len(pages) >= n else []
def h(w):
    return w[3] - w[1]

check(len(pages) == 22 and not err, 'the 22 displays on 22 pages, nothing said', (len(pages), err[:200]))

# 5: root 3 {...}: its degree small, its bottom above the base line's
p = pg(5)
x = [w for w in p if w[4] == 'x']
three = [w for w in p if w[4] == '3' and x and h(w) < 0.75 * h(x[0])]	# (not p³'s)
check(x and len(three) == 2 and all(t[3] < x[0][3] - 2 for t in three),
      "a root's degree small and raised", (x[:1], three))

# 7: the integral's lower limit under its tail, the upper at its right
p = pg(7)
integ = [w for w in p if w[4] == '∫']
low = [w for w in p if w[4] == '−∞']
up = [w for w in p if w[4] == '∞']
check(integ and low and up and (integ[0][0] + integ[0][2]) / 2 < low[0][0] < integ[0][2] - 1 and
      up[0][0] > integ[0][2] - 1,
      "an integral's lower limit under its tail, the upper at its right", (integ, low, up))

# 9: the Vandermonde matrix: its first column (of 1s) as narrow as a 1
p = pg(9)
ones = sorted([w for w in p if w[4] in ('1', '⎛1')], key=lambda w: w[1])	# (the bracket and 1 one word)
x1 = [w for w in p if w[4] == 'x' and ones and abs(w[1] - ones[0][1]) < 3]
gap = min(w[0] for w in x1) - ones[0][2] if ones and x1 else 99
check(gap < 13, "a matrix's columns each as wide as its widest", (gap, ones[:2], x1[:1]))	# (an em apart: 11; the widest's width: 20)

# 11: {} = 0 in the aligned equations: the 0 a thick space after =
p = pg(11)
eqs = [w for w in p if w[4] == '=']
zero = [w for w in p if w[4] == '0']
sp = [z[0] - e[2] for e in eqs for z in zero if abs(z[3] - e[3]) < 2 and z[0] > e[2]]
check(sp and min(sp) > 2, 'a relation after {} spaced as one', (sp, eqs[:2], zero[:2]))

# 12: Λ upright: set in the roman font (or the math font), not italic
fonts = {}
for m in re.finditer(r'x font (\d+) (\S+)', tr):
    fonts[m.group(1)] = m.group(2)
cur = None
lam = []
for line in tr.split('\n'):
    if re.match(r'^f\d+$', line):
        cur = fonts.get(line[1:])
    elif 'cΛ' in line or 'CΛ' in line:
        lam.append(cur)
check(lam and all(f in ('R', 'S') for f in lam), 'capital Greek upright', lam)

# 16: the Gaussian's exponent: a fraction in a superscript, its parts in
# scriptscript size (60%)
p = pg(16)
fx = [w for w in p if w[4].startswith('f')]
num = [w for w in p if '−μ' in w[4] or '-μ' in w[4]]
check(fx and num and h(num[0]) < 0.7 * h(fx[0]), "a fraction in an exponent in scriptscript size",
      (fx[:1], num[:1]))

# 18: braces over and under, the font's (a size, or its pieces)
check(re.search(r'GID=uni23DF', tr) and re.search(r'GID=uni23DE', tr), 'braces over and under',
      sorted(set(re.findall(r'GID=uni23D[EF][.a-z0-9]*', tr))))

# book2tex: the same in LaTeX's
tex = open(d + '/hard.tex', encoding='utf-8').read() if __import__('os').path.exists(d + '/hard.tex') else ''
check('\\sqrt[3]{' in tex and re.search(r'\\underbrace\{.*\}_\{', tex) and re.search(r'\\overbrace\{.*\}\^\{', tex) and
      '\\displaystyle' in tex, 'book2tex: root, braces and displaystyle as LaTeX\'s',
      [l for l in tex.split('\n') if 'brace' in l or 'sqrt[' in l][:3])
sys.exit(fail)
PY
