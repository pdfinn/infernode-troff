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
#	the letters maths italic, and f's italic correction before (;
#	an accent the math font's (f hat);
#	scripts at 8.8 and 6.6 points, as TeX's;
#	a fraction in an exponent in scriptscript size (TeX's styles for a
#	fraction's parts);
#	braces over and under, of the font's sizes and pieces;
#	the 23 displays on 23 pages, nothing said on the standard error;
#	a continued fraction's levels apart by their numerators' struts;
#	n choose k in parentheses of TeX's delim1 (2.39 ems), a wide hat
#	the font's variant;
#	book2tex: root, overbrace, underbrace, displaystyle, choose and strut
#	as LaTeX's.

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
import sys, re, html, unicodedata
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok
raw = open(d + '/hard.html', encoding='utf-8').read()
# (maths italic letters, 𝑥, as the letters they are)
pages = [[(float(a), float(b), float(c), float(e), unicodedata.normalize('NFKC', html.unescape(w))) for a, b, c, e, w in
          re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
         for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/hard.html', encoding='utf-8').read(), re.S)]
err = ''.join(open(d + '/' + f).read() for f in ('eqn.err', 'troff.err', 'pdf.err'))
tr = open(d + '/hard.tr', encoding='utf-8').read()
def pg(n):
    return pages[n - 1] if len(pages) >= n else []
def h(w):
    return w[3] - w[1]

check(len(pages) == 23 and not err, 'the 23 displays on 23 pages, nothing said', (len(pages), err[:200]))

# 5: root 3 {...}: its degree small, its bottom above the base line's
p = pg(5)
x = [w for w in p if w[4] in ('x', 'x=')]	# (pdftotext may join x and =)
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

# digits from the math font, as unicode-math's (math_upright)
cur = None
dig = []
for line in tr.split('\n'):
    if re.match(r'^f\d+$', line):
        cur = fonts.get(line[1:])
    else:
        dig += [cur for c in re.findall(r'c([0-9])', line)]
check(dig and all(f == 'S' for f in dig), 'digits from the math font', sorted(set(dig)))

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

# the letters maths italic (U+1D44E on), as TeX's, the PDF's text saying
# so; f's italic correction (a third of its width) before its (
check('GID=u1D465' in tr and '𝑥' in raw and 'GID=uniFFFD' not in tr, 'letters in maths italic, their text too',
      sorted(set(re.findall(r'GID=u1D4[0-9A-F]+', tr)))[:5])
ic = re.findall(r'CGID=u1D453\nf\d+\nh(\d+)h(\d+)', tr)
check(ic and all(int(b) >= 0.34 * int(a) for a, b in ic), "f's italic correction before (", ic[:3])

# 7: f hat, the font's accent (U+0302), not troff's ^
check('GID=uni0302' in tr, "an accent the math font's", sorted(set(re.findall(r'GID=uni03[0-9A-F]+[.a-z0-9]*', tr))))

# 2: the continued fraction, its numerators strutted (\\cfrac's): from
# the top of q^(1/5) to the foot of 1 + ... as XeLaTeX's (87 points)
p = pg(2)
span = max(w[3] for w in p) - min(w[1] for w in p) if p else 0
check(84 < span < 92, "a continued fraction's levels apart as \\cfrac's", span)

# 23: n choose k, its parentheses of the font's sizes at least 2.39 ems
# (a size variant); xyz's hat the font's wider variant
p23 = tr[tr.find('\np23\n'):] if '\np23\n' in tr else ''
check(re.search(r'GID=parenleft\.size[2-9]', p23) and re.search(r'GID=parenright\.size[2-9]', p23) and
      re.search(r'GID=uni0302\.size[1-9]', p23), "n choose k's parentheses, a wide hat",
      sorted(set(re.findall(r'GID=(?:paren|uni0302)[.a-z0-9]*', p23))))

# scripts at TeX's 8.8 points and scriptscripts at 6.6 (scaled_sizes;
# devutf's sizescale 100), not 9 and 7
if re.search(r'(?m)^sizescale 100', open('lib/troff/devutf/DESC').read()):
    check(re.search(r'(?m)^s880$', tr) and re.search(r'(?m)^s660$', tr), 'scripts at 8.8 and 6.6 points',
          sorted(set(re.findall(r'(?m)^s\d+$', tr))))

# book2tex: the same in LaTeX's
tex = open(d + '/hard.tex', encoding='utf-8').read() if __import__('os').path.exists(d + '/hard.tex') else ''
check('\\sqrt[3]{' in tex and re.search(r'\\underbrace\{.*\}_\{', tex) and re.search(r'\\overbrace\{.*\}\^\{', tex) and
      '\\displaystyle' in tex and '\\binom{n}{k}' in tex and '\\strut' in tex, 'book2tex: root, braces, displaystyle, choose and strut as LaTeX\'s',
      [l for l in tex.split('\n') if 'brace' in l or 'sqrt[' in l][:3])
sys.exit(fail)
PY
