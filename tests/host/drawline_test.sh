#!/bin/sh
#
# drawline_test.sh — the lines troffpage paints (tr2img, Xenith's view
# of a document) are as thick as the PDF's, a twentieth of an em, at
# every resolution:
#
#	a pic line at 10 points, painted at 72, 144, 288 and 576 to the
#	inch, is a pixel wide where a twentieth of an em is a pixel or
#	less, and within a pixel of it where it is more.  Draw's line is
#	1+2r pixels wide for a radius r; the radius was a twentieth of an
#	em halved and rounded up, so a line was three pixels at 72 and at
#	144 alike, heavy beside the text and not following the scale.
#
#	a line drawn after \D't 3p' is 3 points wide at each resolution
#	(3 pixels at 72, 6 at 144, ...), and after \D't 0' lines are back
#	to a twentieth of an em; a thickness set before a page break is
#	the next page's too, as troff and tr2pdf have it.  troffpage took
#	no notice of D t, so pic's thick lines and a document's \D't'
#	were thick in the PDF and at the default weight on the screen.
. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "drawline_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/pic.dis" ] && [ -f "$ROOT/dis/tr2img.dis" ] ||
    { echo "drawline_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "drawline_test: SKIP (no python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/drawline.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

printf '.ps 10\n.PS\nline right 2i\nline down 1i\n.PE\n' >"$tmp/l.ms"
cat >"$tmp/t.tr" <<'EOF'
.ps 10
\D'l 2i 0'
.sp 1i
\D't 3p'\D'l 2i 0'
.sp 1i
\D't 0'\D'l 2i 0'
.sp 1i
\D't 3p'
.bp
\D'l 2i 0'
EOF
with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; pic l.ms | troff > l.out >[2] l.err; tr2img -r 72 l.out > l72.ppm; tr2img -r 144 l.out > l144.ppm; tr2img -r 288 l.out > l288.ppm; tr2img -r 576 l.out > l576.ppm; troff t.tr > t.out >[2] t.err; tr2img -r 72 t.out > t72.ppm; tr2img -p 2 -r 72 t.out > t72.2.ppm; tr2img -r 144 t.out > t144.ppm; tr2img -p 2 -r 144 t.out > t144.2.ppm; tr2img -r 288 t.out > t288.ppm; tr2img -p 2 -r 288 t.out > t288.2.ppm; tr2img -r 576 t.out > t576.ppm; tr2img -p 2 -r 576 t.out > t576.2.ppm" </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY'
import re, sys
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:300]))
    fail |= not ok
def ppm(path):
    b = open(path, 'rb').read()
    m = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', b)
    return int(m.group(1)), int(m.group(2)), b[m.end():]
for dpi in (72, 144, 288, 576):
    try:
        w, h, px = ppm('%s/l%d.ppm' % (d, dpi))
    except Exception as e:
        check(False, 'tr2img at %d' % dpi, e)
        continue
    dark = lambda x, y: sum(px[3 * (y * w + x):3 * (y * w + x) + 3]) < 384
    # the horizontal line: the dark rows in the column a quarter of the way along it
    rows = {}
    for x in range(w):
        for y in range(h):
            if dark(x, y):
                rows.setdefault(y, 0)
                rows[y] += 1
    long = [y for y, n in rows.items() if n > dpi]	# the 2-inch line's rows
    em = 10 * dpi / 72 / 20		# a twentieth of an em, in pixels
    want = 1 if em <= 1 else em
    got = len(long)
    check(got > 0 and abs(got - want) <= 1 and (em > 1 or got == 1),
          'a line at %d to the inch: %d pixels wide (a twentieth of an em is %.2f)' % (dpi, got, em),
          (got, sorted(long)))

# the D t document: the bands of rows the 2-inch lines make, in order
def bands(path, dpi):
    w, h, px = ppm(path)
    rows = []
    for y in range(h):
        if px.count(b'\xff', 3 * y * w, 3 * (y + 1) * w) == 3 * w:
            continue	# a white row
        n = 0
        for x in range(w):
            i = 3 * (y * w + x)
            if px[i] + px[i + 1] + px[i + 2] < 384:
                n += 1
        if n > dpi:
            rows.append(y)
    b = []
    for y in rows:
        if b and y == b[-1][1] + 1:
            b[-1][1] = y
        else:
            b.append([y, y])
    return [y1 - y0 + 1 for y0, y1 in b]
def near(got, want):
    return abs(got - want) <= 1 and (want > 1 or got == 1)
for dpi in (72, 144, 288, 576):
    em = 10 * dpi / 72 / 20
    deflt = 1 if em <= 1 else em
    thick = 3 * dpi / 72
    try:
        b1 = bands('%s/t%d.ppm' % (d, dpi), dpi)
        b2 = bands('%s/t%d.2.ppm' % (d, dpi), dpi)
    except Exception as e:
        check(False, 'tr2img of the D t document at %d' % dpi, e)
        continue
    check(len(b1) == 3 and near(b1[0], deflt),
          'at %d to the inch, a line before D t: %s pixels wide (the default %.2f)' % (dpi, b1[:1], deflt), b1)
    check(len(b1) == 3 and near(b1[1], thick),
          'at %d to the inch, a line after D t 3p: %s pixels wide (3 points are %.2f)' % (dpi, b1[1:2], thick), b1)
    check(len(b1) == 3 and near(b1[2], deflt),
          'at %d to the inch, a line after D t 0: %s pixels wide (the default %.2f)' % (dpi, b1[2:3], deflt), b1)
    check(len(b2) == 1 and near(b2[0], thick),
          'at %d to the inch, a line on the next page after D t 3p: %s pixels wide (3 points are %.2f)' % (dpi, b2, thick), b2)
sys.exit(fail)
PY
