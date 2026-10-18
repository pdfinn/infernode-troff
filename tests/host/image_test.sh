#!/bin/sh
#
# image_test.sh — -mbook's .image given less than its size, the rest the
# image's own (troff's .imgsize reads it from the image's header):
#
#	.imgsize: a PNG's size and resolution (pHYs), a JPEG's (SOF, JFIF);
#	.image f w: the height by the image's proportions; .image f "" h:
#	the width; .image f: its size at its resolution, 72 to the inch if
#	it says none; and no wider than the line;
#	book2tex: \includegraphics with what was given;
#	an image in running text below the line above it, its descenders
#	cleared; tr2img (troffpage, the document views) paints it where
#	tr2pdf puts it.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "image_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/book2tex.dis" ] || { echo "image_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "image_test: SKIP (no python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/image.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

python3 -I - "$tmp" <<'PY'
import struct, zlib, sys
d = sys.argv[1]
def chunk(t, b):
    return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
def png(w, h, ppm=None):
    rows = b''.join(b'\x00' + b'\x80' * (3 * w) for y in range(h))
    p = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    if ppm:
        p += chunk(b'pHYs', struct.pack('>IIB', ppm, ppm, 1))
    return p + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')
open(d + '/a.png', 'wb').write(png(300, 100))		# no resolution: 72 to the inch
open(d + '/b.png', 'wb').write(png(300, 150, 5906))	# 150 to the inch
open(d + '/c.png', 'wb').write(png(3000, 1000))	# wider than the line at 72
# a JPEG's header: JFIF at 200 to the inch, a frame 400 by 300 (no data needed)
j = b'\xff\xd8' + b'\xff\xe0' + struct.pack('>H', 16) + b'JFIF\x00\x01\x02\x01' + struct.pack('>HH', 200, 200) + b'\x00\x00'
j += b'\xff\xc0' + struct.pack('>HBHHB', 11, 8, 300, 400, 1) + b'\x01\x11\x00' + b'\xff\xd9'
open(d + '/d.jpg', 'wb').write(j)
rows = b''.join(b'\x00' + b'\xd0\x20\x20' * 40 for y in range(20))
open(d + '/red.png', 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 40, 20, 8, 2, 0, 0, 0)) +
    chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))
PY
cat >"$tmp/r.ms" <<'MS'
.chapter "Images" im
A paragraph of words above the image, set as a line or two of text so that
there is something just above it to compare against.
.alt "red"
.image red.png 2i
Words below.
MS
cat >"$tmp/t.ms" <<'MS'
.imgsize a.png
.tm A \n[imgw] \n[imgh] \n[imgres]
.imgsize b.png
.tm B \n[imgw] \n[imgh] \n[imgres]
.imgsize d.jpg
.tm D \n[imgw] \n[imgh] \n[imgres]
.imgsize none.png
.tm N \n[imgw] \n[imgh] \n[imgres]
.alt "a"
.image a.png 3i
.tm L \n[.l]
.alt "a"
.image a.png "" 2i
.alt "a"
.image a.png
.alt "b"
.image b.png
.alt "d"
.image d.jpg
.alt "c"
.image c.png
MS
with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; troff -mbook t.ms > t.out >[2] t.err; book2tex -o t.tex t.ms >[2] tex.err; troff -mbook r.ms > r.out >[2] r.err; tr2img -r 300 r.out > r.ppm; tr2pdf r.out > r.pdf" </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY'
import re, sys
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:300]))
    fail |= not ok
err = open(d + '/t.err').read()
got = dict((l.split()[0], l.split()[1:]) for l in err.split('\n') if re.match(r'^[ABDNL] ', l))
L = int(got.get('L', ['0'])[0])	# the line's length, -mbook's
check(got.get('A') == ['300', '100', '0'] and got.get('B') == ['300', '150', '150'] and
      got.get('D') == ['400', '300', '200'] and got.get('N') == ['0', '0', '0'],
      '.imgsize: a PNG, its resolution, a JPEG, its JFIF density; none of a file not there', got)
im = [(f, int(w), int(h)) for f, w, h in re.findall(r'x X image (\S+) (\d+) (\d+)', open(d + '/t.out').read())]
i = 7200	# troff's units an inch
want = [('a.png', 3 * i, i), ('a.png', L, L // 3), ('a.png', 300 * i // 72, 100 * i // 72),
        ('b.png', 2 * i, i), ('d.jpg', 2 * i, 3 * i // 2), ('c.png', L, L // 3)]
check(len(im) == 6 and all(a[0] == b[0] and abs(a[1] - b[1]) < 12 and abs(a[2] - b[2]) < 12 for a, b in zip(im, want)),
      '.image: the size not given by the proportions, neither its own at its resolution, no wider than the line', im)
tex = open(d + '/t.tex').read()
check('\\includegraphics[width=3in]{a.png}' in tex and '\\includegraphics[height=2in]{a.png}' in tex and
      '\\includegraphics{a.png}' in tex, 'book2tex: \\includegraphics with what was given',
      re.findall(r'\\includegraphics[^\n]*', tex))
# the image painted by tr2img where tr2pdf puts it, below the text above
def redbox(rgb, w, h):
    red = [(i % w, i // w) for i in range(w * h) if rgb[3 * i] > 180 and rgb[3 * i + 1] < 80]
    dark = [i // w for i in range(w * h) if sum(rgb[3 * i:3 * i + 3]) < 300 and not (rgb[3 * i] > 180 and rgb[3 * i + 1] < 80)]
    if not red:
        return None
    xs = [x for x, y in red]; ys = [y for x, y in red]
    top = min(ys)
    above = [y for y in dark if y < top]
    return (min(xs), top, max(xs), max(ys), max(above) if above else -1)
def ppm(path):
    b = open(path, 'rb').read()
    m = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', b)
    return int(m.group(1)), int(m.group(2)), b[m.end():]
try:
    w, h, px = ppm(d + '/r.ppm')
    v = redbox(px, w, h)
except Exception as e:
    v = None
check(v and abs((v[2] - v[0] + 1) - 600) < 6 and abs((v[3] - v[1] + 1) - 300) < 6 and v[1] > v[4],
      'tr2img: the image painted, 2 inches by 1, below the text above it', v)
import shutil, subprocess
if shutil.which('pdftoppm'):
    subprocess.run(['pdftoppm', '-r', '300', '-f', '1', '-l', '1', '-png', d + '/r.pdf', d + '/rp'], check=False)
    import glob
    try:
        from PIL import Image
        f = glob.glob(d + '/rp*.png')[0]
        im = Image.open(f).convert('RGB')
        p = redbox(im.tobytes(), im.width, im.height)
        check(v and p and all(abs(a - b) < 3 for a, b in zip(v[:4], p[:4])), 'tr2img paints it where tr2pdf puts it', (v, p))
    except ImportError:
        pass
sys.exit(fail)
PY
