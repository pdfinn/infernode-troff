#!/bin/sh
#
# manuscript_test.sh — what a thesis set by -mbook needs, as a real one
# (a dissertation from LaTeX) asked of it:
#
#	the page by name (.papersize a4), a bad size refused and said;
#	the text double spaced, the notes single (book-nvs) and the
#	contents single (book-tvs);
#	a note's number full size, hung in the margin (as Bringhurst sets
#	them), its text at the text's margin;
#	the text's last line clear of the notes' rule on every page;
#	three letters at least after a hyphen;
#	the contents: a long title filled short of the page's number and
#	hung after its number, no entry past the margin, its leaders apart
#	from its title (run to the page's number's box), a subsection
#	further in than a section; .subsubsection neither numbered nor in
#	the contents;
#	lists (.list, .item, .endlist), numbered and not, nested, their
#	marks hung, tagged L, LI, Lbl and LBody;
#	images (.image): a JPEG as it is, a PNG's colour and its alpha a
#	soft mask, each at the size asked;
#	a chapter's short title its running head; a running head too long
#	for its page's number, the chapter's number instead, and said;
#	LaTeX's house style: book-plain, no running heads and the page's
#	number at the foot of every page; book-chlatex, a chapter headed
#	as LaTeX's book class heads it, Chapter 1 and its title bold, at
#	the left;
#	one-sided (book-oneside): the binding margin on every page's left,
#	every page headed by its chapter, its number at the right; ragged
#	right (book-adj pl);
#	where veraPDF is (verapdf, or $VERAPDF), PDF/UA-1;
#	book2tex: lists, images, \subsubsection, \chapter[short]{long}.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "manuscript_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] || { echo "manuscript_test: SKIP (dis not built)"; exit 77; }
command -v pdftotext >/dev/null 2>&1 && command -v pdfimages >/dev/null 2>&1 ||
    { echo "manuscript_test: SKIP (no poppler)"; exit 77; }
python3 -c 'import pypdf' 2>/dev/null || { echo "manuscript_test: SKIP (no pypdf)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/manuscript.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

python3 -I - "$tmp" <<'PY'
import sys, base64, zlib, struct
d = sys.argv[1]
# a JPEG, 40 by 20, half blue and half red
open(d + '/a.jpg', 'wb').write(base64.b64decode(
 '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA0JCgsKCA0LCgsODg0PEyAVExISEyccHhcgLikxMC4pLSwzOko+MzZGNywtQFdBRkxOUlNSMj5aYVpQYEpRUk//'
 '2wBDAQ4ODhMREyYVFSZPNS01T09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0//wAARCAAUACgDASIAAhEBAxEB/8QA'
 'HwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkK'
 'FhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXG'
 'x8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC'
 'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE'
 'hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDjqKKK+xOc'
 'tWX8f4VaqrZfx/hVqvjs1/3ufy/JH1WW/wC6x+f5sKKKK847zLooor9CPhi1Zfx/hVqiivjs1/3ufy/JH1WW/wC6x+f5sKKKK847z//Z'))
# a PNG, 30 by 10, RGBA: an opaque green left half, a transparent right
def chunk(t, b):
    return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
rows = b''
for y in range(10):
    rows += b'\x00' + b''.join(b'\x20\xa0\x40\xff' if x < 15 else b'\x00\x00\x00\x00' for x in range(30))
png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 30, 10, 8, 6, 0, 0, 0)) +
       chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))
open(d + '/b.png', 'wb').write(png)
para = ('Considerable administrative responsibility accompanies the establishment of international organizations. '
        'Representatives from participating governments negotiate extraordinarily complicated agreements concerning '
        'jurisdiction, compensation and accountability. Notwithstanding considerable disagreement, the commissioners '
        'ultimately recommended comprehensive institutional reorganization.')
note = ('Contemporaneous correspondence demonstrates characteristically meticulous preparation by the secretariat, '
        'and historians consistently characterize the negotiations as transformative.')
out = ['.papersize 0 0', '.papersize a4', '.margins 0.7i 0.8i 1.4i 1.4i', '.nr book-recto 0',
       '.nr book-ps 12', '.nr book-vs 24p', '.nr book-nvs 12p', '.nr book-tvs 14p',
       '.title "Manuscript"', '.author "Test"', '.maketitle', '.frontmatter', '.contents', '.mainmatter',
       '.chapter "A Chapter Whose Title Is Far Too Long To Be Set As A Running Head Beside Its Page Number" long',
       '.section "First"', '']
for i in range(10):
    out += [para + ' Notedword\\c', '.fn', note, '.fe', '']
out += ['.section "A Section Whose Title Is Long Enough That Its Entry In The Contents Must Be Filled Over Two Lines" ls', '']
# subsections' titles from one line with room for leaders to two: one
# between, filled to a line only as its spaces shrink, its page's number
# at the margin still
for k in range(1, 15):
    out += ['.subsection "Growing word word word word word word word %s"' % 'abcdefghijklmnop'[:k], '', 'Short.', '']
out += ['.subsection "Sub"', '', para, '', '.subsubsection "Deeper"', '', para, '',
        'A list follows.', '.list 1', '.item', 'Firstitem of the list.', '.item', 'Seconditem, with', '.list bullet', '.item',
        'Nesteditem.', '.endlist', '.item', 'Thirditem.', '.endlist', '',
        '.alt "Two halves, blue and red"', '.image a.jpg 2i 1i', '', para, '',
        '.alt "A green half"', '.image b.png 3i 1i', '', para, '',
        '.chapter "Second" two "Short Head"', ''] + [para, ''] * 16
open(d + '/m.ms', 'w').write('\n'.join(out) + '\n')
# LaTeX's house style
p = ['.margins 1i 1i 1i 1i', '.nr book-recto 0', '.nr book-plain 1', '.nr book-chlatex 1', '.title "Plain"', '.maketitle', '.mainmatter', '.chapter "Plainchapter"', '']
for i in range(12):
    p += [para, '']
open(d + '/p.ms', 'w').write('\n'.join(p) + '\n')
# one-sided, ragged right
o = ['.margins 1i 1i 1.5i 0.5i', '.nr book-oneside 1', '.ds book-adj pl', '.title "Onesided"', '.maketitle',
     '.mainmatter', '.chapter "Lopsided"', '']
for i in range(12):
    o += [para, '']
open(d + '/o.ms', 'w').write('\n'.join(o) + '\n')
PY
with_timeout 300 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; book -f m.ms >[2]m.err; book2tex -o t.tex m.ms >[2]t.err; book p.ms >[2]p.err; book o.ms >[2]o.err" </dev/null >"$tmp/emu.log" 2>&1
if [ ! -s "$tmp/m.pdf" ]; then
    echo "FAIL: no PDF: $(cat "$tmp/m.err" "$tmp/emu.log")"
    exit 1
fi
pdftotext -bbox "$tmp/m.pdf" "$tmp/m.html" 2>/dev/null
pdftotext -layout "$tmp/m.pdf" "$tmp/ml.txt" 2>/dev/null
pdfimages -list "$tmp/m.pdf" >"$tmp/images" 2>/dev/null
pdftotext -bbox "$tmp/p.pdf" "$tmp/p.html" 2>/dev/null
pdftotext -bbox "$tmp/o.pdf" "$tmp/o.html" 2>/dev/null

python3 -I - "$tmp" <<'PY' || fail=1
import sys, re, html
import pypdf
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:400]))
    fail |= not ok

err = open(d + '/m.err', encoding='utf-8').read()
r = pypdf.PdfReader(d + '/m.pdf')
box = r.pages[0].mediabox
check(abs(float(box.width) - 595) < 1 and abs(float(box.height) - 842) < 1 and 'not a page\'s size' in err,
      'the page by name (a4), a bad size refused and said', (box, err[:200]))

pages = [[(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
          re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
         for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/m.html', encoding='utf-8').read(), re.S)]
def rows(ws):
    r = {}
    for w in ws:
        r.setdefault(round(w[3]), []).append(w)
    return sorted(r)
# the text (12 points) double spaced, the notes (10) single
text = [w for p in pages for w in p if 13 < w[3] - w[1] < 15]
notes = [w for p in pages for w in p if 10.5 < w[3] - w[1] < 12.5]
tp = [p for p in pages if any('Notedword' in w[4] for w in p)]
gap = lambda ys: sorted(round(b - a, 1) for a, b in zip(ys, ys[1:]))
tg = gap(rows([w for w in tp[0] if 13 < w[3] - w[1] < 15]))
ng = gap(rows([w for w in tp[0] if 10.5 < w[3] - w[1] < 12.5]))
check(tg and ng and abs(tg[len(tg) // 2] - 24) < 0.6 and abs(ng[0] - 12) < 0.6,
      'the text double spaced, its notes single', (tg[:5], ng[:5]))

# a note's number in the margin, full size, its text at the margin
left = min(w[0] for w in text)
nums = [w for p in tp for w in p if re.match(r'^\d+$', w[4]) and 10.5 < w[3] - w[1] < 12.5]
check(nums and all(w[2] < left - 2 for w in nums) and
      min(w[0] for w in notes if not re.match(r'^\d+$', w[4])) > left - 1,
      "a note's number full size, hung in the margin", (left, nums[:3]))

# the text's last line clear of the notes, a line at least, on every page
clear = []
for p in tp:
    t = [w for w in p if 13 < w[3] - w[1] < 15]
    n = [w for w in p if 10.5 < w[3] - w[1] < 12.5 and w[1] > max(x[3] for x in t) - 1]
    if t and n:
        clear.append(round(min(w[1] for w in n) - max(w[3] for w in t), 1))
check(clear and min(clear) > 14, "the text's last line clear of its notes' rule", clear)

# three letters at least after a hyphen
lay = open(d + '/ml.txt', encoding='utf-8').read().split('\n')
short = []
for a, b in zip(lay, lay[1:]):
    if re.search(r'[a-z]-$', a.rstrip()) and b.strip():
        m = re.match(r'([a-z]+)', b.strip())
        if m and len(m.group(1)) < 3:
            short.append((a[-12:], b.strip()[:8]))
check(not short, 'three letters at least after a hyphen', short)

# the contents
cont = [p for p in pages if any(w[4] == 'Contents' for w in p)][0]
right = max(w[2] for p in pages if p is not cont for w in p if 13 < w[3] - w[1] < 15)	# the text's margin
nums = [w for w in cont if re.match(r'^\d+$', w[4])]
long = [w for w in cont if w[4] in ('Filled', 'Over')]
sec = [w for w in cont if w[4] == '1.1']
sub = [w for w in cont if w[4] == '1.2.15']
toc = ' '.join(w[4] for w in cont)
# leaders apart from the title they follow (a dot against its last word
# reads as a full stop), as LaTeX's run to its page's box
glued = [w[4] for w in cont if re.search(r'[A-Za-z]\.$', w[4])]
check(nums and max(w[2] for w in nums) <= right + 1 and not glued and len(set(round(w[3]) for w in long)) >= 1 and
      sub and sec and sub[0][0] > sec[0][0] + 5 and 'Deeper' not in toc and 'Sub' in toc,
      'the contents: long titles filled, none past the margin, leaders apart from titles, subsections further in, no subsubsections',
      (right, nums[-3:], glued, sec[:1], sub[:1], toc[:200]))
check(any(w[4] == 'Deeper' for p in pages for w in p) and not re.search(r'\d\.\d\.\d\s+Deeper', '\n'.join(lay)),
      'a subsubsection not numbered', '')

# lists: marks hung; tagged L LI Lbl LBody
items = {}
for p in pages:
    for a, b in zip(p, p[1:]):
        if b[4].strip(',.') in ('Firstitem', 'Seconditem', 'Thirditem', 'Nesteditem'):
            items[b[4].strip(',.')] = (a, b)
ok = len(items) == 4 and all(a[2] < b[0] for a, b in items.values()) and \
     items['Nesteditem'][1][0] > items['Firstitem'][1][0] + 10 and \
     items['Firstitem'][0][4] == '1.' and items['Thirditem'][0][4] == '3.' and items['Nesteditem'][0][4] == '•'
check(ok, 'lists numbered and not, nested, their marks hung', {k: (v[0][4], round(v[1][0])) for k, v in items.items()})
types = []
def walk(e):
    e = e.get_object()
    k = e.get('/K')
    ks = k if isinstance(k, list) else [k] if k is not None else []
    for x in ks:
        x = x.get_object()
        if hasattr(x, 'get') and '/S' in x:
            types.append(str(x['/S']))
            walk(x)
walk(r.trailer['/Root']['/StructTreeRoot'])
check(types.count('/L') == 2 and types.count('/LI') == 4 and types.count('/Lbl') == 4 and types.count('/LBody') == 4,
      'lists tagged L, LI, Lbl and LBody', [t for t in types if t[1] == 'L'])

# images
im = [l.split() for l in open(d + '/images').read().split('\n')[2:] if l.strip()]
jpeg = [l for l in im if l[2] == 'image' and l[8] == 'jpeg']
png = [l for l in im if l[2] == 'image' and l[8] == 'image']
smask = [l for l in im if l[2] == 'smask']
# 40 pixels across 2 inches, 30 across 3
check(jpeg and png and smask and abs(float(jpeg[0][12]) - 20) < 1 and abs(float(png[0][12]) - 10) < 1,
      'images: a JPEG as it is, a PNG and its alpha, at the size asked', im)

# running heads
heads = [p[0][4] for p in pages if p and p[0][1] < 50]
check(any(h.startswith('Chapter') for h in heads) and 'running head too wide' in err and
      any('Short' in ' '.join(w[4] for w in p if w[1] < 50) for p in pages),
      'a short title its running head; one too long the chapter\'s number, said', (heads, err[:200]))

# LaTeX's house style: no heads, the folio centred at the foot; the
# chapter's head bold, at the left, Chapter 1 above its title
pp = [[(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
       re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
      for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/p.html', encoding='utf-8').read(), re.S)]
body = [p for p in pp if any('Considerable' in w[4] for w in p)]
tops = [min(w[1] for w in p) for p in body]
foots = [max(p, key=lambda w: w[3]) for p in body]
lm = min(w[0] for p in body for w in p if 11 < w[3] - w[1] < 13.5)
ch = [w for p in body for w in p if w[4] in ('Chapter', 'Plainchapter')]
check(all(t > 60 for t in tops) and all(re.match(r'^\d+$', f[4]) and abs((f[0] + f[2]) / 2 - 216) < 3 for f in foots) and
      len(ch) == 2 and all(abs(w[0] - lm) < 2 and w[3] - w[1] > 18 for w in ch) and ch[0][3] < ch[1][1],
      "LaTeX's house style: no heads, the folio at the foot; the chapter headed at the left, bold",
      (tops, [(f[4], round((f[0] + f[2]) / 2)) for f in foots], lm, ch))

# one-sided: every page's text 1.5 inches in, headed Lopsided at the
# left and its number at the right; ragged: the lines' ends uneven
op = [[(float(a), float(b), float(c), float(e), html.unescape(w)) for a, b, c, e, w in
       re.findall(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<', p)]
      for p in re.findall(r'<page [^>]*>(.*?)</page>', open(d + '/o.html', encoding='utf-8').read(), re.S)]
ob = [p for p in op if any('Considerable' in w[4] for w in p)]
lms = [round(min(w[0] for w in p if 11 < w[3] - w[1] < 13.5)) for p in ob]
heads = [sorted((w for w in p if w[1] < 60), key=lambda w: w[0]) for p in ob[1:]]
ends = {}
for p in ob:
    for w in p:
        if 11 < w[3] - w[1] < 13.5:
            k = round(w[1])
            ends[k] = max(ends.get(k, 0), w[2])
spread = max(ends.values()) - sorted(ends.values())[len(ends) // 4]
check(len(ob) >= 3 and all(abs(x - 108) < 2 for x in lms) and
      all(h and h[0][4].lower() == 'lopsided' and re.match(r'^\d+$', h[-1][4]) for h in heads) and spread > 10,
      'one-sided: every page 1.5 inches in, headed by its chapter; ragged right',
      (lms, [[w[4] for w in h] for h in heads], spread))
sys.exit(fail)
PY

# PDF/UA-1, where veraPDF is
vera=${VERAPDF:-$(command -v verapdf 2>/dev/null)}
if [ -n "$vera" ] && [ -x "$vera" ]; then
    if "$vera" --flavour ua1 --format text "$tmp/m.pdf" 2>/dev/null | grep -q '^PASS'; then
        echo "PASS: veraPDF: PDF/UA-1"
    else
        echo "FAIL: veraPDF: $("$vera" --flavour ua1 --format text "$tmp/m.pdf" 2>&1 | tail -5)"
        fail=1
    fi
fi

# book2tex
if grep -q 'begin{enumerate}' "$tmp/t.tex" && grep -q 'begin{itemize}' "$tmp/t.tex" &&
   grep -q 'includegraphics\[width=2in,height=1in\]{a.jpg}' "$tmp/t.tex" && grep -q 'subsubsection{Deeper}' "$tmp/t.tex" &&
   grep -q 'chapter\[Short Head\]{Second}' "$tmp/t.tex"; then
    echo "PASS: book2tex: lists, images, subsubsections, a chapter's short title"
else
    echo "FAIL: book2tex: $(grep -n 'enumerate\|itemize\|includegraphics\|subsubsection\|chapter' "$tmp/t.tex" | head)"
    fail=1
fi
exit $fail
