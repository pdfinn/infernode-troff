#!/bin/sh
#
# mkfn_test.sh — mkfn(1), troff's font descriptions made from OpenType
# fonts.
#
#	lib/troff/devutf is what lib/troff/devutf/mkdesc makes now;
#	an alias does not take a character the font has a glyph of its
#	own for (the micro sign's alias μ hid the Greek mu), and troff's
#	Greek names go to the Greek letters (*m to μ, *D to Δ);
#	-c gives the aliases as Neatmkfn does;
#	no glyph is named by a character beyond the 16 bits of a Limbo
#	string's (u1D400 would be read as U+D400, a Hangul syllable);
#	a CFF glyph's bounding box is read from its charstring;
#	troff sets μ, µ, \(*m, \(/u and \(*D as the characters they are;
#	eqnrc's settings for its math font are what mkfn -M makes of it now;
#	another OpenType math font (Latin Modern Math, where TeX Live has it)
#	sets the hard displays by mkfn -M's settings for it alone.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "mkfn_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/mkfn.dis" ] || { echo "mkfn_test: SKIP (dis not built)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/mkfn.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

inferno() {
    with_timeout 120 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "$1" </dev/null 2>"$tmp/err"
}

pass() { echo "PASS: $1"; }
failed() { echo "FAIL: $1"; fail=1; }

# the device is what mkdesc makes
mkdir "$tmp/dev"
inferno "sh /lib/troff/devutf/mkdesc '#U*$tmp/dev'"
same=1
for f in R I B BI CR HR HI HB S1 S; do
    if ! cmp -s "$tmp/dev/$f" "lib/troff/devutf/$f"; then
        failed "lib/troff/devutf/$f is not what mkdesc makes"; same=0
    fi
done
[ $same = 1 ] && pass "lib/troff/devutf is what mkdesc makes"

# the aliases of a character after its line, as "char,alias,alias"
aliases() {
    awk -F'\t' '/^char / && $2 != "\"" { if (c != "") print c; c = substr($1, 6) }
        /^char / && $2 == "\"" { c = c "," substr($1, 6) }
        END { if (c != "") print c }' "$1"
}
aliases "$tmp/dev/R" >"$tmp/R.alias"
grep -qx 'μ,\*m' "$tmp/R.alias" && grep -qx 'µ,/u' "$tmp/R.alias" &&
    grep -qx 'Δ,\*D' "$tmp/R.alias" && grep -qx '∆' "$tmp/R.alias" &&
    grep -qx '¢,c|,ct' "$tmp/R.alias" &&
    pass "aliases go to the glyphs troff means" ||
    failed "aliases: $(grep -E '^(μ|µ|Δ|∆|¢)(,|$)' "$tmp/R.alias" | tr '\n' ' ')"

# -c: Neatmkfn's aliases
inferno "mkfn -c -b -l -o -r7200 -Slatn,grek /fonts/libertinus/LibertinusSerif-Regular.otf >'#U*$tmp/Rc'"
aliases "$tmp/Rc" | grep -qx 'µ,/u,\*m,μ' &&
    pass "-c gives Neatmkfn's aliases" ||
    failed "-c: $(aliases "$tmp/Rc" | grep '^µ')"

# no names beyond 16 bits
if LC_ALL=C grep -q "$(printf '^char [^\t]*[\360-\367]')" "$tmp/dev/R" "$tmp/dev/S"; then
    failed "a glyph named by a character beyond U+FFFF"
else
    pass "no glyph named by a character beyond U+FFFF"
fi
grep -q "$(printf '^char ---\t[0-9,-]*\t[0-3]\tu1D400\t$')" "$tmp/dev/S" &&
    pass "u1D400 is described, unnamed" || failed "u1D400: $(grep 'u1D400' "$tmp/dev/S")"

# a CFF glyph's bounding box, from its charstring: a sits on the
# baseline below the x-height, g descends, b ascends
grep -q "$(printf '^char a\t457,36,-10,455,439\t0\t')" "$tmp/dev/R" &&
grep -q "$(printf '^char g\t[0-9]*,[0-9]*,-[0-9]*,[0-9]*,[0-9]*\t1\t')" "$tmp/dev/R" &&
grep -q "$(printf '^char b\t[0-9,-]*\t2\t')" "$tmp/dev/R" &&
    pass "CFF glyphs' bounding boxes" ||
    failed "CFF bounding boxes: $(grep '^char [agb]	' "$tmp/dev/R")"

# troff sets each as itself
printf 'μ µ \\(*m \\(/u \\(*D\n' >"$tmp/mu.tr"
inferno "troff '#U*$tmp/mu.tr'" >"$tmp/mu.out"
got=$(grep -v '^x' "$tmp/mu.out" | tr '\n' ' ')
want='cμ h490h250cµ h515h250cμ h490h250cµ h515h250cΔ h636'
case "$got" in
*"$want"*)
    pass "troff sets μ µ \\(*m \\(/u \\(*D" ;;
*)
    failed "troff set: $got" ;;
esac

# eqnrc's settings for Libertinus Math are mkfn -M's
inferno "mkfn -M /fonts/libertinus/LibertinusMath-Regular.otf" >"$tmp/math.rc"
sed -n '/^\.\\" ---- mkfn -M/,/^\.\\" ---- end of mkfn -M/p' lib/troff/eqnrc | sed '1d;$d' >"$tmp/eqnrc.math"
if [ -s "$tmp/math.rc" ] && cmp -s "$tmp/math.rc" "$tmp/eqnrc.math"; then
    pass "eqnrc's math font settings are mkfn -M's"
else
    failed "eqnrc's math font settings differ from mkfn -M's: $(diff "$tmp/math.rc" "$tmp/eqnrc.math" | head -5)"
fi

# Latin Modern Math, by its settings alone: a device with it as S, eqnrc
# with mkfn -M's for it
lm=/usr/share/texmf/fonts/opentype/public/lm-math/latinmodern-math.otf
if [ -f "$lm" ] && [ -f "$ROOT/dis/eqn.dis" ] && command -v pdfinfo >/dev/null 2>&1; then
    mkdir "$tmp/lm" "$tmp/lm/devutf"
    cp "$lm" "$tmp/lm/lm.otf"
    for f in lib/troff/devutf/*; do ln -s "$ROOT/$f" "$tmp/lm/devutf/"; done
    rm "$tmp/lm/devutf/S"
    inferno "cd '#U*$tmp/lm'; mkfn -b -l -o -s -r7200 -tS -f'#U*$tmp/lm/lm.otf' lm.otf > devutf/S; mkfn -M lm.otf > lm.rc"
    sed '/^\.\\" ---- mkfn -M/,$d' lib/troff/eqnrc >"$tmp/lm/eqnrc"
    cat "$tmp/lm/lm.rc" >>"$tmp/lm/eqnrc"
    cp tests/eqn/hard.ms "$tmp/lm/"
    inferno "cd '#U*$tmp/lm'; eqn eqnrc hard.ms > hard.eq >[2] eqn.err; troff -F'#U*$tmp/lm' hard.eq > hard.tr >[2] troff.err; tr2pdf -F'#U*$tmp/lm' hard.tr > hard.pdf >[2] pdf.err"
    pages=$(pdfinfo "$tmp/lm/hard.pdf" 2>/dev/null | awk '/^Pages:/{print $2}')
    if [ "$pages" = 23 ] && [ ! -s "$tmp/lm/eqn.err" ] && [ ! -s "$tmp/lm/troff.err" ] && [ ! -s "$tmp/lm/pdf.err" ] &&
        grep -q 'GID=parenleft\.v[0-9]' "$tmp/lm/hard.tr" && grep -q 'GID=summation\.v1' "$tmp/lm/hard.tr" &&
        grep -q '^set script_percent_scale_down 70' "$tmp/lm/lm.rc"; then
        pass "Latin Modern Math by mkfn -M's settings: 23 displays, its sizes and constants"
    else
        failed "Latin Modern Math: $pages pages; $(cat "$tmp/lm/eqn.err" "$tmp/lm/troff.err" "$tmp/lm/pdf.err" | head -3)"
    fi
else
    echo "SKIP: Latin Modern Math (no font, eqn or pdfinfo)"
fi

exit $fail
