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
. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "drawline_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/pic.dis" ] && [ -f "$ROOT/dis/tr2img.dis" ] ||
    { echo "drawline_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "drawline_test: SKIP (no python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/drawline.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

printf '.ps 10\n.PS\nline right 2i\nline down 1i\n.PE\n' >"$tmp/l.ms"
with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; pic l.ms | troff > l.out >[2] l.err; tr2img -r 72 l.out > l72.ppm; tr2img -r 144 l.out > l144.ppm; tr2img -r 288 l.out > l288.ppm; tr2img -r 576 l.out > l576.ppm" </dev/null >"$tmp/emu.log" 2>&1

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
sys.exit(fail)
PY
