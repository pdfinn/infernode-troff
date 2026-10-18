#!/bin/sh
#
# pdffigure_test.sh — a PDF as -mbook's .image, its first page a figure
# of vectors (a Form XObject in tr2pdf's output), from a PDF as pdfTeX,
# LuaTeX and Ghostscript write them:
#
#	its objects in an object stream, found by a cross-reference
#	stream (compressed, PNG-predicted); its page in a tree of pages,
#	its media box and resources inherited, its media box not at 0 0,
#	its contents two streams; a reference in an array in its resources
#	copied;
#	.imgsize: its size, 720 to the inch; .image f w: its height by its
#	proportions, .image f: its own size;
#	tr2img (troffpage, the document views) paints it where tr2pdf
#	puts it, each its corner square where it is.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "pdffigure_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2img.dis" ] || { echo "pdffigure_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "pdffigure_test: SKIP (no python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/pdffig.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

python3 -I - "$tmp" <<'PY'
import struct, zlib, sys
d = sys.argv[1]
# a page 72 by 36 points, its box at 100 200: red, a blue square of 12
# in its top right corner, drawn by a second stream through a graphics
# state whose font is a reference in an array
objs = {
    1: b'<< /Type /Catalog /Pages 2 0 R >>',
    2: b'<< /Type /Pages /Kids [3 0 R] /Count 1 /MediaBox [100 200 172 236] >>',
    3: b'<< /Type /Pages /Parent 2 0 R /Kids [4 0 R] /Count 1 /Resources << /ExtGState << /G 7 0 R >> >> >>',
    4: b'<< /Type /Page /Parent 3 0 R /Contents [5 0 R 6 0 R] >>',
    7: b'<< /Type /ExtGState /ca 1 /Font [9 0 R 12] >>',
    9: b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
}
streams = {5: zlib.compress(b'1 0 0 rg 100 200 72 36 re f\n'), 6: zlib.compress(b'/G gs 0 0 1 rg 160 224 12 12 re f\n')}
out = bytearray(b'%PDF-1.5\n%\xe2\xe3\xcf\xd3\n')
where = {}
for n, z in streams.items():
    where[n] = (1, len(out), 0)
    out += b'%d 0 obj\n<< /Length %d /Filter /FlateDecode >>\nstream\n' % (n, len(z)) + z + b'\nendstream\nendobj\n'
# the object stream
head = b''
body = b''
for i, (n, o) in enumerate(sorted(objs.items())):
    head += b'%d %d ' % (n, len(body))
    body += o + b'\n'
    where[n] = (2, 10, i)
z = zlib.compress(head + body)
where[10] = (1, len(out), 0)
out += b'10 0 obj\n<< /Type /ObjStm /N %d /First %d /Length %d /Filter /FlateDecode >>\nstream\n' % (len(objs), len(head), len(z)) + z + b'\nendstream\nendobj\n'
# the cross-reference stream, PNG-predicted (Up) as pdfTeX's
where[11] = (1, len(out), 0)
rows = []
for n in range(12):
    t, a, b = where.get(n, (0, 0, 0))
    rows.append(struct.pack('>BHH', t, a, b))
prev = bytes(5)
data = b''
for r in rows:
    data += b'\x02' + bytes((r[i] - prev[i]) & 255 for i in range(5))
    prev = r
z = zlib.compress(data)
xref = len(out)
out += (b'11 0 obj\n<< /Type /XRef /Size 12 /W [1 2 2] /Root 1 0 R /Length %d /Filter /FlateDecode'
        b' /DecodeParms << /Columns 5 /Predictor 12 >> >>\nstream\n' % len(z)) + z + b'\nendstream\nendobj\n'
out += b'startxref\n%d\n%%%%EOF\n' % xref
open(d + '/fig.pdf', 'wb').write(out)
PY
cat >"$tmp/t.ms" <<'MS'
.imgsize fig.pdf
.tm S \n[imgw] \n[imgh] \n[imgres]
.alt "a"
.image fig.pdf
MS
cat >"$tmp/r.ms" <<'MS'
.chapter "Figures" fig
A paragraph of words above the figure, set as a line or two of text so
that there is something just above it to compare against.
.alt "A red box, a blue square in its corner"
.image fig.pdf 2i
Words below.
MS
with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; troff -mbook t.ms > t.out >[2] t.err; troff -mbook r.ms > r.out >[2] r.err; tr2img -r 300 r.out > r.ppm; tr2pdf r.out > r.pdf >[2] pdf.err" </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY'
import re, sys, zlib
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:300]))
    fail |= not ok
err = open(d + '/t.err').read()
s = re.findall(r'^S (.*)', err, re.M)
check(s == ['720 360 720'], '.imgsize: a compressed PDF\'s page, 72 points by 36 (in its object stream, its box inherited)', (s, err[-300:]))
im = re.findall(r'x X image (\S+) (\d+) (\d+)', open(d + '/t.out').read())
check(im == [('fig.pdf', '7200', '3600')], '.image: a PDF at its own size', im)
pdf = open(d + '/r.pdf', 'rb').read()
forms = re.findall(rb'/Subtype /Form.*?/Matrix \[([^\]]*)\]', pdf, re.S)
objs = set(int(n) for n in re.findall(rb'(?m)^(\d+) 0 obj', pdf))
refs = set(int(n) for n in re.findall(rb'(\d+) 0 R', pdf))
check(len(forms) == 1 and b'/Font [' in pdf and refs <= objs, 'tr2pdf: the page a Form, every reference in it (one in an array) copied',
      (forms, sorted(refs - objs), open(d + '/pdf.err').read()))
def ppm(path):
    b = open(path, 'rb').read()
    m = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', b)
    return int(m.group(1)), int(m.group(2)), b[m.end():]
def boxes(w, h, px):
    red = []; blue = []; dark = []
    for i in range(w * h):
        r, g, b = px[3 * i], px[3 * i + 1], px[3 * i + 2]
        if r > 180 and g < 80 and b < 80:
            red.append(i)
        elif b > 180 and r < 80 and g < 80:
            blue.append(i)
        elif r + g + b < 300:
            dark.append(i // w)
    def bb(l):
        if not l:
            return None
        xs = [i % w for i in l]; ys = [i // w for i in l]
        return (min(xs), min(ys), max(xs), max(ys))
    rb = bb(red + blue)
    above = [y for y in dark if rb and y < rb[1]]
    return rb, bb(blue), max(above) if above else -1
try:
    v = boxes(*ppm(d + '/r.ppm'))
except Exception as e:
    v = (None, None, str(e))
ok = v[0] and v[1] and abs(v[0][2] - v[0][0] + 1 - 600) < 6 and abs(v[0][3] - v[0][1] + 1 - 300) < 6
# the blue square, 12 of 72 points: 100 pixels, in the top right corner
ok = ok and abs(v[1][2] - v[0][2]) < 4 and abs(v[1][1] - v[0][1]) < 4 and abs(v[1][2] - v[1][0] + 1 - 100) < 6
check(ok and v[0][1] > v[2], 'tr2img: the figure painted, 2 inches by 1, its square in its corner, below the text', v)
import shutil, subprocess
if shutil.which('pdftoppm'):
    subprocess.run(['pdftoppm', '-r', '300', '-f', '1', '-l', '1', d + '/r.pdf', d + '/rp'], check=False)
    import glob
    f = glob.glob(d + '/rp*.ppm')
    p = boxes(*ppm(f[0])) if f else (None, None, -1)
    check(v[0] and p[0] and p[1] and all(abs(a - b) < 3 for a, b in zip(v[0] + v[1], p[0] + p[1])),
          'tr2pdf puts it where tr2img paints it (its box\'s corner at the place, not 100 200 off)', (v, p))
sys.exit(fail)
PY
