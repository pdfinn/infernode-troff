#!/bin/sh
#
# sizescale_test.sh — troff(1)'s sizescale (devutf's 100): sizes in
# hundredths of a point, as groff's scaled points:
#
#	.ps 8.8 is 8.8 points (s880), \n(.s 9 (whole points, as ever),
#	\n[.ps] 880, 1m 8.8 points; \s[8.8] and \s+2 from it;
#	a size kept through a diversion (troff's own \s[880z] read again);
#	tr2pdf's text at 8.8 points (Tf);
#	a document of whole sizes set on a copy of devutf without sizescale
#	the same, its sizes aside.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "sizescale_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] && [ -f "$ROOT/dis/tr2pdf.dis" ] || { echo "sizescale_test: SKIP (dis not built)"; exit 77; }
grep -q '^sizescale 100' lib/troff/devutf/DESC || { echo "sizescale_test: SKIP (devutf has no sizescale)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/sizescale.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pass() { echo "PASS: $1"; }
failed() { echo "FAIL: $1"; fail=1; }

printf '.ps 8.8\n.nr w 1m\nA \\n(.s \\n[.ps] \\nw\n.br\n\\s[8.8]B\\s+2C\\s0\n.br\n.di X\n.ps 8.8\nD\n.br\n.di\n.ps 11\n.X\nE\n' >"$tmp/s.tr"
printf '.ps 11\n.vs 13p\nWords set at eleven points, \\s-2smaller\\s0 and \\s+3larger\\s0, filled\nacross a line or two so that spaces stretch as they must.\n.ps 9\nNine.\n' >"$tmp/w.tr"
mkdir "$tmp/devutf"
for f in lib/troff/devutf/*; do ln -s "$ROOT/$f" "$tmp/devutf/"; done
rm "$tmp/devutf/DESC"
grep -v '^sizescale' lib/troff/devutf/DESC >"$tmp/devutf/DESC"

with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd '#U*$tmp'; troff s.tr > s.out; tr2pdf s.out > s.pdf; troff w.tr > w100.out; troff -F'#U*$tmp' w.tr > w1.out" \
    </dev/null >"$tmp/emu.log" 2>&1

python3 -I - "$tmp" <<'PY' || fail=1
import re, sys, zlib
d = sys.argv[1]
fail = 0
def check(ok, what, why=''):
    global fail
    print(('PASS: ' if ok else 'FAIL: ') + what + ('' if ok else ': ' + str(why)[:300]))
    fail |= not ok
out = open(d + '/s.out', encoding='utf-8').read()
# the text after each size: s880 then A's line
seq = re.findall(r'(?m)^s(\d+)|c(\S)|C(\S+)', out)
text = ''.join(c for s, c, n in seq if c)
check('s880' in out and '9880880' in text.replace(' ', ''), '.ps 8.8: s880, \\n(.s 9, \\n[.ps] 880, 1m 880',
      (re.findall(r's\d+', out)[:6], text[:40]))
sizes = []
cur = None
for s, c, n in seq:
    if s:
        cur = int(s)
    elif c and c in 'BCDE':
        sizes.append((c, cur))
check(sizes == [('B', 880), ('C', 1080), ('D', 880), ('E', 1100)], '\\s[8.8], \\s+2, a diversion, .ps 11', sizes)
pdf = open(d + '/s.pdf', 'rb').read()
tf = set()
for m in re.finditer(rb'stream\r?\n(.*?)endstream', pdf, re.S):
    try:
        tf |= set(re.findall(rb' ([\d.]+) Tf', zlib.decompress(m.group(1))))
    except Exception:
        pass
check(b'8.8' in tf and b'10.8' in tf, 'tr2pdf: 8.8 and 10.8 points', tf)
a = open(d + '/w1.out', encoding='utf-8').read()
b = open(d + '/w100.out', encoding='utf-8').read()
b = re.sub(r'(?m)^s(\d+)00$', r's\1', b)
check(a == b and len(a) > 200, 'whole sizes set the same on a device with no sizescale', (len(a), len(b)))
sys.exit(fail)
PY
exit $fail
