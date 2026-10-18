#!/bin/sh
#
# chess_test.sh — chess(1), the chess diagrams' preprocessor:
#
#	the input copied, each board between .CB and .CE set as a picture
#	(.PS height width ... .PE), troff's line numbers kept after it;
#	each piece its figure in CH, a white one its outline over its
#	filled figure set white; flip turning the board (a1 at the top
#	right); nocoords leaving the files and ranks unnamed;
#	a position read out as the figure's description (King e1, ...,
#	White to move), unless .alt gave one;
#	a bad position, an unknown setting or a board with no .CE reported
#	with its file and line, and chess failing;
#	book(1) running it on a book with a board, the PDF's Figure
#	described by the position, a figure in its text (♔d3) set in CH,
#	not in the fallback (DejaVu Sans, which has them too);
#	tr2img painting the board: its dark squares grey, a piece's ink on
#	its square and none on an empty one.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "chess_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/chess.dis" ] && [ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2img.dis" ] ||
    { echo "chess_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "chess_test: SKIP (no python3)"; exit 77; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/chess.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# the opening position, words before and after it
cat >"$tmp/start.ms" <<'MS'
Before.
.CB
fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w
.CE
After.
MS
# a rook alone on a1, as White sees it and turned
cat >"$tmp/a1.ms" <<'MS'
.CB
fen 8/8/8/8/8/8/8/R7
nocoords
.CE
.CB
fen 8/8/8/8/8/8/8/R7
nocoords
flip
.CE
MS
cat >"$tmp/alt.ms" <<'MS'
.alt "My own words"
.CB
fen 4k3/8/8/8/8/8/8/4K3 b
.CE
MS
cat >"$tmp/bad.ms" <<'MS'
Words.
.CB
fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPP/RNBQKBNR
.CE
.CB
fen 8/8/8/8/8/8/8/X7
size 2i
colour red
.CE
.CB
fen 8/8/8/8/8/8/8/8
MS
# a book: words, then a board with a king and a pawn each
cat >"$tmp/b.ms" <<'MS'
.chapter "Kings and pawns" kp
The opposition decides it: after 1.\fB♔d3\fP White keeps it.
.CB
fen 8/8/4k3/8/4P3/4K3/8/8 w
.CE
MS
SDL_VIDEODRIVER=dummy with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; chess start.ms > start.pre >[2] start.err; echo status \$status > start.st;
     chess a1.ms > a1.pre; chess < alt.ms > alt.pre;
     chess bad.ms > bad.pre >[2] bad.err; echo status \$status > bad.st;
     troff -mbook start.pre > start.out >[2] troff.err; tr2img -r 100 start.out > start.ppm >[2] img.err;
     book b.ms > book.log >[2] book.err" </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY'
import re, sys, zlib
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok
def read(f):
    try:
        return open(d + '/' + f, encoding='utf-8').read()
    except Exception as e:
        return ''
pre = read('start.pre')
lines = pre.split('\n')
check(lines[0] == 'Before.' and re.search(r'(?m)^\.PS [\d.]+i [\d.]+i$', pre) and '.PE\n.lf 5\nAfter.' in pre
      and read('start.st').strip() == 'status',
      'chess: the words copied, the board a picture, the line after it numbered', (pre[:200], pre[-60:], read('start.err')))
filled = '♚♛♜♝♞♟'
outline = '♔♕♖♗♘♙'
nf = sum(pre.count(c) for c in filled)
no = sum(pre.count(c) for c in outline)
# 32 pieces: each a filled figure (twice: its width, to centre it), the
# 16 white ones under their outlines
check(nf == 64 and no == 16 and pre.count('\\m[white]') == 16 and pre.count('\\f[CH]') == 32,
      'chess: each piece its figure in CH, a white one outlined over white', (nf, no, pre.count('\\f[CH]')))
check(all(c in pre for c in 'abcdefgh') and re.search(r"\\s\[8\]\\h'-\\w'8'", pre),
      'chess: the files and ranks named', pre[-400:])
alt = re.search(r"(?m)^\.if '\\\*\[book-alt\]'' \.ds book-alt (.*)$", pre)
want = ('Chess diagram. White: King e1, Queen d1, Rooks a1 and h1, Bishops c1 and f1, Knights b1 and g1, '
        'Pawns a2, b2, c2, d2, e2, f2, g2 and h2. Black: King e8, Queen d8, Rooks a8 and h8, Bishops c8 and f8, '
        'Knights b8 and g8, Pawns a7, b7, c7, d7, e7, f7, g7 and h7. White to move.')
check(alt and alt.group(1) == want, 'chess: the position read out as its description, unless .alt gave one', alt and alt.group(1))
a1 = read('a1.pre')
boards = a1.split('.PE')
def rook(b):
    m = re.search(r"\\v'([\d.]+)i'\\h'([\d.]+)i'\\f\[CH\]", b)
    return (float(m.group(1)), float(m.group(2))) if m else None
r, f = rook(boards[0]), rook(boards[1]) if len(boards) > 1 else None
check(r and f and r[0] > 1.5 and r[1] < 0.5 and f[0] < 0.5 and f[1] > 1.5 and not re.search(r"\\s\[8\]", a1),
      'chess: a1 at the bottom left, turned at the top right; nocoords naming none', (r, f))
check('.ds book-alt' in read('alt.pre') and read('alt.pre').startswith('.alt "My own words"\n.if'),
      'chess: from its standard input, a board after .alt left to it', read('alt.pre')[:120])
err = read('bad.err')
want = ['chess: bad.ms:3: fen: rank 2 has 7 squares',
        'chess: bad.ms:2: a board with no fen',
        'chess: bad.ms:6: fen: X is not a piece',
        'chess: bad.ms:8: unknown setting colour',
        'chess: bad.ms:5: a board with no fen',
        'chess: bad.ms:10: .CB with no .CE']
check(err.split('\n')[:len(want)] == want and read('bad.st').strip() != 'status' and read('bad.pre').startswith('Words.\n'),
      'chess: each error with its file and line, chess failing', (err, read('bad.st')))
pdf = b''
try:
    pdf = open(d + '/b.pdf', 'rb').read()
except Exception:
    pass
text = pdf
for m in re.finditer(rb'stream\r?\n(.*?)endstream', pdf, re.S):
    try:
        text += zlib.decompress(m.group(1))
    except Exception:
        pass
desc = b'Chess diagram. White: King e3, Pawn e4. Black: King e6. White to move.'
check(b'/S /Figure' in text and desc in text, 'book: chess run, the PDF\'s Figure described by the position',
      (len(pdf), read('book.err')[-300:]))
fonts = set(re.findall(rb'/BaseFont /[A-Z]{6}\+([^\s/]+)', pdf))
check(b'CH' in fonts and not any(b'DejaVu' in f for f in fonts),
      'book: a figure in the text (♔d3) from CH, not the fallback\'s', fonts)
try:
    b = open(d + '/start.ppm', 'rb').read()
    m = re.match(rb'P6\s+(\d+)\s+(\d+)\s+255\s', b)
    w, h, px = int(m.group(1)), int(m.group(2)), b[m.end():]
    # the dark squares: grey, solid (not a letter's grey edge)
    g = [all(abs(px[3 * i + k] - 0xc8) < 12 for k in range(3)) for i in range(w * h)]
    grey = [(i % w, i // w) for i in range(w * (h - 8)) if g[i] and i % w < w - 8 and g[i + 8] and g[i + 8 * w] and g[i + 8 * w + 8]]
    x0, y0 = min(p[0] for p in grey), min(p[1] for p in grey)
    x1, y1 = max(p[0] for p in grey) + 8, max(p[1] for p in grey) + 8
    s = (x1 - x0 + 1) / 8
    def ink(f, r):
        n = 0
        for y in range(int(y0 + (8 - r) * s + 3), int(y0 + (9 - r) * s - 3)):
            for x in range(int(x0 + f * s + 3), int(x0 + (f + 1) * s - 3)):
                i = 3 * (y * w + x)
                n += px[i] + px[i + 1] + px[i + 2] < 150
        return n
    e1, e8, e4, d5 = ink(4, 1), ink(4, 8), ink(4, 4), ink(3, 5)
    v = (round(s, 1), e1, e8, e4, d5)
    check(abs(s - 25) < 2 and e1 > 10 and e8 > 30 and e4 == 0 and d5 == 0,
          'tr2img: the board painted, its squares grey, the kings on e1 and e8, e4 and d5 empty', v)
except Exception as e:
    check(False, 'tr2img: the board painted', (e, read('img.err')))
sys.exit(fail)
PY
