#!/bin/sh
#
# tbl_test.sh — tbl(1), the table preprocessor:
#
#	its output is Plan 9 tbl's: tests/tbl/tbl.out was made by Plan 9's
#	tbl (as Neatroff uses it) from tests/tbl/tbl.ms (boxed, all-boxed,
#	double-boxed and expanded tables, spans across and down, fonts,
#	sizes and widths, text blocks, numbers aligned, alphabetic
#	columns, \R, .T&, rules, eqn's delimiters);
#	a table whose one line spans down (\^), on which Plan 9's tbl
#	loops for ever, is set;
#	under -mbook, a table's rules are drawn as lines (.rules), not as
#	glyphs set side by side;
#	a line outside a table, and one in a text block, longer than C's
#	buffers (5120 and 4096 bytes) is passed on whole, not cut in two
#	with a word;
#	under -ms, a boxed table's rules are drawn as lines, the box rules
#	meeting the underrules at the corners (\(br set nothing and \(ul
#	underscores); text set .na stays ragged after a table.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "tbl_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/tbl.dis" ] && [ -f "$ROOT/dis/troff.dis" ] ||
    { echo "tbl_test: SKIP (dis not built)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tbl.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf '.TS\nl.\n\\^\n.TE\n' >"$tmp/span.ms"
printf '.TS\nbox;\nl | l.\na\tb\n.TE\n' >"$tmp/box.ms"
long=$(awk 'BEGIN { for (i = 0; i < 1500; i++) printf "w%04d ", i }')
printf '%s\n.TS\nl.\nT{\n%s\nT}\n.TE\n' "$long" "$long" >"$tmp/long.ms"

with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "tbl < /tests/tbl/tbl.ms > '#U*$tmp/tbl.out'; tbl < '#U*$tmp/span.ms' > '#U*$tmp/span.out'; tbl < '#U*$tmp/box.ms' | troff -mbook > '#U*$tmp/box.tr'; tbl < '#U*$tmp/long.ms' > '#U*$tmp/long.out'" \
    </dev/null >"$tmp/emu.log" 2>&1

if cmp -s "$tmp/tbl.out" tests/tbl/tbl.out; then
    echo "PASS: Plan 9 tbl's output"
else
    echo "FAIL: Plan 9 tbl's output:"
    diff tests/tbl/tbl.out "$tmp/tbl.out" | head -20 | sed 's/^/    /'
    fail=1
fi

if grep -q '^\.TE' "$tmp/span.out" 2>/dev/null; then
    echo "PASS: a table of one line spanning down is set"
else
    echo "FAIL: a table of one line spanning down: $(head -c 200 "$tmp/span.out" 2>/dev/null)"
    fail=1
fi

# rules as lines: troff's output draws (D) and sets no underscore or bar
if grep -q '^D' "$tmp/box.tr" 2>/dev/null && ! grep -q '^c_' "$tmp/box.tr"; then
    echo "PASS: rules drawn as lines under -mbook"
else
    echo "FAIL: rules drawn as lines: $(grep -c '^D' "$tmp/box.tr" 2>/dev/null) lines drawn"
    fail=1
fi
if [ "$(grep -c "^$long\$" "$tmp/long.out" 2>/dev/null)" = 2 ]; then
    echo "PASS: long lines passed on whole"
else
    echo "FAIL: long lines: $(awk '{ print length($0) }' "$tmp/long.out" 2>/dev/null | sort -rn | head -3 | tr '\n' ' ')"
    fail=1
fi
# under -ms (no .rules asked for): a boxed table's rules drawn as lines
# (\(br set nothing, \(ul was underscores), the box rules' ends on the
# underrules' outer edges; text set .na stays ragged after a table (tbl's
# .if \n(.j=0 .na, which troff's \n(.j never let be 0)
printf '.TS\nbox;\nl | l.\nab\tcd\n_\nef\tgh\n.TE\n' >"$tmp/box.ms"
printf '.LP\n.na\nBefore the table, some words set ragged.\n.TS\nl l.\na\tb\n.TE\nAfter the table the words are still set ragged, not justified, as they were before it, and on and on until the line is full and more.\n' >"$tmp/na.ms"
with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$tmp'; tbl box.ms | troff -ms > box.out; tbl na.ms | troff -ms > na.out" </dev/null >/dev/null 2>&1
if python3 -I - "$tmp/box.out" <<'PY'
import re, sys
h = v = 0
hr, vr, glyph_ul = [], [], 0
for l in open(sys.argv[1], encoding='utf-8', errors='replace'):
    for m in re.finditer(r'([HVhv])(-?\d+)|(DP|Dl)([-\d ]+)|c(.)', l):
        if m.group(1):
            n = int(m.group(2))
            if m.group(1) == 'H': h = n
            elif m.group(1) == 'V': v = n
            elif m.group(1) == 'h': h += n
            else: v += n
        elif m.group(3):
            a = [int(x) for x in m.group(4).split()]
            ys = [v]
            y = v
            for i in range(1, len(a), 2):
                y += a[i]; ys.append(y)
            (hr if m.group(3) == 'DP' else vr).append((min(ys), max(ys)))
            if m.group(3) == 'Dl':
                h += a[0]; v += a[1]
        elif m.group(5) == '_':
            glyph_ul += 1
print('rules', hr, 'sides', vr, 'underscores', glyph_ul)
top = min(r[0] for r in hr); bot = max(r[1] for r in hr)
ok = len(vr) == 3 and len(hr) >= 3 and not glyph_ul
ok = ok and all(abs(a - top) <= 2 and abs(b - bot) <= 2 for a, b in vr)
sys.exit(not ok)
PY
then
    echo "PASS: -ms: a boxed table's rules drawn, its corners meeting"
else
    echo "FAIL: -ms: a boxed table's rules"; fail=1
fi
# (justified, a full line's last glyph ends at the line's end; ragged,
# short of it: the line after the table)
if python3 -I - "$tmp/na.out" <<'PY'
import re, sys
d = open(sys.argv[1], encoding='utf-8', errors='replace').read()
# the lines after the table: A of "After"
i = d.index('cA', d.index('cb'))
seg = d[i:]
lines = re.split(r'\nH', seg)
# each line's width: the sum of h moves and widths after its H
ends = []
for ln in lines[:2]:
    w = sum(int(x) for x in re.findall(r'h(-?\d+)', ln))
    ends.append(w)
print('line widths', ends)
sys.exit(not (len(ends) == 2 and ends[0] < 0.97 * 46800))
PY
then
    echo "PASS: .na kept after a table"
else
    echo "FAIL: .na after a table: the line justified"; fail=1
fi

exit $fail
