#!/bin/sh
#
# troff_test.sh — troff(1), what fuzzing it against C Neatroff found:
#
#	roman numerals of 10000 to 39999 (.af x i and I) are set as C
#	Neatroff sets them (39999 is ZZZMZCMXCIX), not a
#	slice past the end of the letters for five (V) that stopped troff;
#	text already below a page length then shortened under it (.pl) is
#	set and troff ends, where it filled no lines for ever (C's
#	MIN(LEN(a), n) compares unsigned, so n < 0 is all of a);
#	where troff fails it says so and exits, not leaving a Broken
#	program (which keeps emu running);
#	under -mbook, a character none of Libertinus's fonts has (✓) is set
#	in the fallback, DejaVu Sans (DF, special), and one no font has is
#	said, once (.mg), not dropped without a word;
#	a pair kerned as the font kerns it, once: Libertinus's Latin and
#	Greek share their kerning lookups, which Neatmkfn wrote once for
#	each script and troff, with no script chosen, performed each time
#	(AV twice its kern); and a first glyph in no class of a pair's
#	class definition (class 0: D of DA), which Neatmkfn left unkerned;
#	with fontTools, every pair of letters in Libertinus Serif and Sans
#	checked against the font's GPOS;
#	\s10 to \s39 are sizes of two digits, as in troff and groff (\s11
#	was a size of 1 and a 1 printed); -ms spaces a picture of no height
#	(a line and its labels) from the text round it;
#	.na sets lines from the left margin after .ad r (they stayed
#	right), .ad gives the alignment back; \n(.j is troff's number for
#	the adjustment (left 0, both 1, centre 3, right 5), Neatroff's own
#	modes above it, so that .ad \n(.j restores them;
#	classic troff's names: \f(CW our constant width, Plan 9's H and L
#	under -C; \(Do, \(tm, \(~=, \(sq, \(bx, \(ob, \(lh, \(rh their
#	characters; \D't n' the lines' thickness; \- a minus sign copied as
#	a hyphen-minus; -man's .MR.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "troff_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] || { echo "troff_test: SKIP (dis not built)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/troff.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf '.nr x 30000\n.af x i\n\\nx\n.nr y 39999\n.af y I\n\\ny\n' >"$tmp/roman.tr"
printf '.sp 5i\nword\n.pl 4i\n' >"$tmp/pl.tr"
printf 'A check ✓, and 中 and 中 again.\n' >"$tmp/fb.tr"

with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "troff < '#U*$tmp/roman.tr' > '#U*$tmp/roman.out'; troff < '#U*$tmp/pl.tr' > '#U*$tmp/pl.out'; troff -mbook < '#U*$tmp/fb.tr' > '#U*$tmp/fb.out' >[2] '#U*$tmp/fb.err'" \
    </dev/null >"$tmp/emu.log" 2>&1
st=$?

r=$(grep -o 'c[a-zA-Z]' "$tmp/roman.out" 2>/dev/null | tr -d 'c\n')
if [ "$r" = "zzzZZZMZCMXCIX" ]; then
    echo "PASS: roman numerals 30000 and 39999"
else
    echo "FAIL: roman numerals 30000 and 39999: '$r' (exit $st)"
    fail=1
fi

if [ $st != 124 ] && grep -q 'cw' "$tmp/pl.out" 2>/dev/null; then
    echo "PASS: text below a page length shortened under it"
else
    echo "FAIL: text below a page length shortened under it (exit $st)"
    fail=1
fi
# the fallback: ✓ set in the font mounted as DF
if python3 -c '
import re, sys
pos = None
mounts = {}
f = 0
for ln in open(sys.argv[1], encoding="utf-8"):
    m = re.match(r"x font (\d+) (\S+)", ln)
    if m:
        mounts[m.group(1)] = m.group(2)
    m = re.match(r"f(\d+)", ln)
    if m:
        f = m.group(1)
    if "c✓" in ln:
        pos = mounts.get(f)
sys.exit(0 if pos == "DF" else 1)
' "$tmp/fb.out" 2>/dev/null && [ "$(grep -c '中' "$tmp/fb.err")" = 1 ]; then
    echo "PASS: a character Libertinus lacks set in the fallback, one no font has said once"
else
    echo "FAIL: the fallback: $(grep -v '^aux' "$tmp/fb.err" | head -3)"
    fail=1
fi
# kerning, once: AV at 10 points is Libertinus Serif's -112 (thousandths
# of an em), and every pair of letters as the font's GPOS gives it
printf '.ps 10\n.ft R\nAV\n.br\n' >"$tmp/kern.tr"
with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff kern.tr > kern.out" </dev/null >/dev/null 2>&1
if grep -q 'cAh695h-112cV' "$tmp/kern.out"; then
    echo "PASS: a pair kerned once (AV)"
else
    echo "FAIL: AV kerned $(grep -o 'cA[^c]*cV' "$tmp/kern.out")"; fail=1
fi
# sizes of two digits, \s10 to \s39, as troff and groff read them
# (Neatroff, in compatibility mode only): \s11 eleven points, not one
# point and a 1; \s4 one digit
printf 'A\\s11B\\s0C\\s36D\\s0E\\s4F\\s0G\\s(14H\n.br\n' >"$tmp/size.tr"
# -ms: a picture pic gave its size, of no height (an arrow, its labels
# above and below), spaced from the text round it, as Bell's -ms did
printf '.PP\nbefore\n.PS 0.000i 1.000i\n.PE\nafter\n' >"$tmp/pic0.tr"
with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff size.tr > size.out; troff -ms pic0.tr > pic0.out" </dev/null >/dev/null 2>&1
if [ "$(grep -o '^s[0-9]*' "$tmp/size.out" | tr '\n' ' ')" = "s1000 s1000 s1100 s1000 s3600 s1000 s400 s1000 s1400 " ] &&
    ! grep -q 'c1\|c3' "$tmp/size.out"; then
    echo "PASS: sizes of two digits (\\s11, \\s36)"
else
    echo "FAIL: sizes: $(grep '^s\|^c' "$tmp/size.out" | tr '\n' ' ')"; fail=1
fi
# (V of the line after, less V of the line before: a line, and a line's
# .35 and .65 round the picture)
gap=$(awk '/^V/ {v = substr($0, 2)} /^cb/ {b = v} /^ca/ {a = v} END {print a - b}' "$tmp/pic0.out")
if [ "$gap" -ge 2400 ] 2>/dev/null; then
    echo "PASS: -ms spaces a picture of no height ($gap units)"
else
    echo "FAIL: -ms: a picture of no height spaced $gap units"; fail=1
fi
# .na: from the left margin, whatever .ad said (it kept a right or a
# centred alignment); .ad gives it back; \n(.j as troff gives it (left
# 0, both 1, centre 3, right 5, .na with right 4), .ad \n(.j restoring
# Neatroff's modes too (pb)
printf '.ll 3i\n.ad r\nright\n.br\n.na\nragged\n.br\n.ad\nright again\n.br\n.tm j=\\n(.j\n.na\n.tm j=\\n(.j\n.ad l\n.tm j=\\n(.j\n.ad b\n.tm j=\\n(.j\n.ad c\n.tm j=\\n(.j\n.ad pb\n.nr J \\n(.j\n.ad l\n.ad \\nJ\n.tm pb=\\n(.j\n' >"$tmp/na.tr"
with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff na.tr > na.out >[2] na.err" </dev/null >/dev/null 2>&1
# (where each line's first glyph is: right, ragged, right again)
hs=$(python3 -I - "$tmp/na.out" <<'PY'
import re, sys
h = v = 0; first = {}
for m in re.finditer(r'([HVhv])(-?\d+)|c(.)', open(sys.argv[1], encoding='utf-8', errors='replace').read()):
    if m.group(1):
        n = int(m.group(2))
        if m.group(1) == 'H': h = n
        elif m.group(1) == 'V': v = n
        elif m.group(1) == 'h': h += n
        else: v += n
    elif v not in first:
        first[v] = h
print(' '.join(str(first[k]) for k in sorted(first)[:3]))
PY
)
set -- $hs
if [ $# -ge 3 ] && [ "$2" -lt "$1" ] && [ "$3" -gt "$2" ]; then
    echo "PASS: .na from the left margin after .ad r; .ad gives it back"
else
    echo "FAIL: .na after .ad r: the lines' starts $hs"; fail=1
fi
if [ "$(grep '^j=\|^pb=' "$tmp/na.err" | tr '\n' ' ')" = "j=5 j=4 j=0 j=1 j=3 pb=33 " ]; then
    echo "PASS: the adjustment (.j) as troff's numbers; .ad restores Neatroff's modes from them"
else
    echo "FAIL: the adjustment (.j): $(tr '\n' ' ' < "$tmp/na.err")"; fail=1
fi
if python3 -c 'import fontTools' 2>/dev/null; then
    python3 -I - "$ROOT/fonts/libertinus" > "$tmp/pairs.tr" <<'PY'
import sys
# every pair of letters, a word each, after its font
caps = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
for ft, name in (('R', 'Serif-Regular'), ('HR', 'Sans-Regular')):
    print('.ft %s' % ft)
    for a in caps:
        print(' '.join(a + b for b in caps))
    print('.br')
PY
    printf '.ps 10\n.fp 6 HR\n.nf\n' | cat - "$tmp/pairs.tr" > "$tmp/pairs2.tr"
    with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff pairs2.tr > pairs.out" </dev/null >/dev/null 2>&1
    python3 -I - "$tmp/pairs.out" "$ROOT/fonts/libertinus" <<'PY' && echo "PASS: every pair of letters kerned as the font's GPOS kerns it" || { echo "FAIL: kerning differs from the font's: see above"; fail=1; }
import re, sys
from fontTools.ttLib import TTFont
out, d = sys.argv[1:3]
def kern(f, a, b):
    # the font's kern feature for Latin, its lookups in order, the first
    # subtable that covers the pair in each
    g = f['GPOS'].table
    cm = f.getBestCmap()
    ga, gb = cm[ord(a)], cm[ord(b)]
    ls = [s for s in g.ScriptList.ScriptRecord if s.ScriptTag == 'latn'][0].Script.DefaultLangSys
    lookups = sorted(set(i for fi in ls.FeatureIndex if g.FeatureList.FeatureRecord[fi].FeatureTag == 'kern'
                         for i in g.FeatureList.FeatureRecord[fi].Feature.LookupListIndex))
    tot = 0
    for li in lookups:
        for t in g.LookupList.Lookup[li].SubTable:
            if ga not in t.Coverage.glyphs:
                continue
            if t.Format == 1:
                ps = t.PairSet[t.Coverage.glyphs.index(ga)]
                pv = [p for p in ps.PairValueRecord if p.SecondGlyph == gb]
                if not pv:
                    continue
                v = pv[0].Value1
            else:
                c2 = t.ClassDef2.classDefs.get(gb, 0)
                v = t.Class1Record[t.ClassDef1.classDefs.get(ga, 0)].Class2Record[c2].Value1
            tot += getattr(v, 'XAdvance', 0) or 0 if v else 0
            break
    return tot
fonts = {'1': TTFont(d + '/LibertinusSerif-Regular.otf'), '6': TTFont(d + '/LibertinusSans-Regular.otf')}
bad = []
n = 0
ft = None
for ln in open(out, encoding='utf-8'):
    m = re.match(r'f(\d+)', ln)
    if m:
        ft = m.group(1)
    for a, k, b in re.findall(r'c([A-Za-z])h\d+(?:h(-?\d+))?c([A-Za-z])', ln):
        if ft not in fonts:
            continue
        n += 1
        want = kern(fonts[ft], a, b)
        if int(k or 0) != want:
            bad.append((ft, a + b, k, want))
print('%d pairs, %d kerned otherwise %s' % (n, len(bad), bad[:5]))
sys.exit(not (n > 5000 and not bad))
PY
fi
# classic troff's names: CW our constant width (CR), and under -C Plan
# 9's H (HR) and -man's L (CR); \(Do and Plan 9's \(tm \(~= \(sq \(bx
# \(ob \(lh \(rh their characters; \D't n' the lines' thickness (0 the
# default again); \- a minus sign read as a hyphen-minus; -man's .MR
printf '.mg 1\n\\f(CWcw\\fP \\(Do5 \\(tm \\(~= \\(sq \\(bx \\(ob \\(rh \\fHh\\fP \\fLl\\fP\n.fp 5 CW\n\\f5five\\fP \\fBls \\-l\\fP\n.sp\n\\D'"'"'l 1i 0'"'"'\n.sp\n\\D'"'"'t 3p'"'"'\\D'"'"'l 1i 0'"'"'\\D'"'"'t 0'"'"'\n.sp\n\\D'"'"'l 1i 0'"'"'\n' >"$tmp/alias.tr"
printf '.TH X 1\n.SH SEE ALSO\n.MR troff 1 ,\n.MR eqn 1 .\n' >"$tmp/mr.1"
with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; troff alias.tr > alias.out >[2] alias.err; troff -C alias.tr > aliasc.out >[2] aliasc.err; tr2pdf alias.out > alias.pdf; troff -man mr.1 > mr.out; tr2pdf mr.out > mr.pdf" </dev/null >/dev/null 2>&1
if [ "$(cat "$tmp/alias.err")" = "troff: failed to mount <H>
troff: failed to mount <L>" ] && [ ! -s "$tmp/aliasc.err" ] &&
   ! grep -q '^x font [0-9]* CW' "$tmp/alias.out"; then
    echo "PASS: CW is CR; H and L (Plan 9's) only under -C"
else
    echo "FAIL: font names: $(cat "$tmp/alias.err" "$tmp/aliasc.err" | tr '\n' ' ')"; fail=1
fi
if command -v pdftotext >/dev/null 2>&1; then
    t=$(pdftotext "$tmp/alias.pdf" - | tr '\n' ' ')
    m=$(pdftotext "$tmp/mr.pdf" - | tr '\n' ' ')
    case "$t|$m" in
    *'cw $5 ™ ≃ □ ■ ◦ ☞'*'five ls -l'*'|'*'troff(1), eqn(1).'*)
        echo "PASS: \\(Do \\(tm \\(~= \\(sq \\(bx \\(ob \\(rh set; \\- copied as -; .MR" ;;
    *) echo "FAIL: characters, \\-, .MR: $t | $m"; fail=1 ;;
    esac
fi
if grep -q '^Dt 300$' "$tmp/alias.out" && grep -q '^Dt 0$' "$tmp/alias.out" && command -v python3 >/dev/null 2>&1 &&
   python3 -I - "$tmp/alias.pdf" <<'PY'
import re, sys, zlib
d = open(sys.argv[1], 'rb').read()
w = []
for m in re.finditer(rb'stream\r?\n(.*?)endstream', d, re.S):
    try: w += re.findall(rb'([\d.]+) w\n', zlib.decompress(m.group(1)))
    except Exception: pass
sys.exit(0 if [float(x) for x in w] == [0.4, 3.0, 0.4] else 1)
PY
then echo "PASS: \\D't 3p' a line 3 points thick, \\D't 0' the default again"
else echo "FAIL: \\D't': $(grep '^D' "$tmp/alias.out" | tr '\n' ' ')"; fail=1; fi

exit $fail
