#!/bin/sh
#
# refer_test.sh — refer(1): citations by key, from refer's databases and
# BibTeX's, plain (Neatrefer's) and in the Chicago style.
#
#	without a style, the output is Neatrefer's: tests/refer/ms.out was
#	made by Neatrefer from ms.tr and db.ref;
#	with -S chicago, tests/refer/chicago.tr cites the works of
#	works.bib (examples after The Chicago Manual of Style, 18th
#	edition) as tests/refer/chicago.out gives them: full notes, then
#	short; et al. past three authors in a note, past six in the
#	bibliography; translated, edited, chapter, article (DOI), thesis
#	and classical works; inclusive page ranges (101–8, 321–28); a
#	title ending in ? keeping its comma; a chapter citing in full
#	again; the bibliography sorted, accents aside;
#	a name left empty in a BibTeX list ("Smith and ", " and Jones")
#	is dropped, where refer stopped on it;
#	-S chicago,british,nodoi,nourl: titles in single quotation marks,
#	the punctuation after them, no DOI or URL; an article or a chapter
#	cited whole given its pages, a chapter its number (chap. 2 in), a
#	month its name, as biblatex-chicago gives them; an option no style
#	knows refused.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "refer_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/refer.dis" ] || { echo "refer_test: SKIP (dis not built)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/refer.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf '@book{a, author = {Smith and }, title = {T}, year = 2000}\n@book{b, author = { and Jones}, title = {U}, year = 2001}\n' >"$tmp/empty.bib"
printf 'x\n.cite a\ny\n.cite b\n.bibliography\n' >"$tmp/empty.tr"
cat >"$tmp/uk.bib" <<'EOF'
@article{art, author = {Wilde, Marc de}, title = {Just Trust Us}, journal = {Comparative Legal History}, volume = 3, number = 1, year = 2015, month = 6, pages = {110--130}, doi = {10.1080/2049677X.2015.1041728}}
@incollection{ch, author = {Dyzenhaus, David}, title = {The Compulsion of Legality}, booktitle = {Emergency and the Limits of Legality}, editor = {Ramraj, Victor}, publisher = {Cambridge University Press}, address = {Cambridge}, year = 2008, chapter = 2, pages = {33--59}, url = {https://example.org/x}}
EOF
printf 'x\n.cite art\ny\n.cite ch\n' >"$tmp/uk.tr"

with_timeout 60 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c \
    "cd /tests/refer; refer -p db.ref -ocite -sa < ms.tr > '#U*$tmp/ms.out'; refer -p works.bib -S chicago < chicago.tr > '#U*$tmp/chicago.out'; refer -p '#U*$tmp/empty.bib' -S chicago < '#U*$tmp/empty.tr' > '#U*$tmp/empty.out' >[2] '#U*$tmp/empty.err'; refer -p '#U*$tmp/uk.bib' -S chicago,british,nodoi,nourl < '#U*$tmp/uk.tr' > '#U*$tmp/uk.out'; refer -p '#U*$tmp/uk.bib' -S chicago,metric < '#U*$tmp/uk.tr' > '#U*$tmp/bad.out' >[2] '#U*$tmp/bad.err'" \
    </dev/null >/dev/null 2>&1

for t in ms chicago; do
    if cmp -s "$tmp/$t.out" "tests/refer/$t.out"; then
        echo "PASS: $t"
    else
        echo "FAIL: $t:"
        diff "tests/refer/$t.out" "$tmp/$t.out" | head -20 | sed 's/^/    /'
        fail=1
    fi
done
if grep -q '^Smith, \\fIT\\fP' "$tmp/empty.out" 2>/dev/null && grep -q '^Jones, \\fIU\\fP' "$tmp/empty.out" &&
    ! grep -q . "$tmp/empty.err"; then
    echo "PASS: a name left empty is dropped"
else
    echo "FAIL: a name left empty: $(cat "$tmp/empty.err" "$tmp/empty.out" 2>/dev/null | head -4)"
    fail=1
fi
# British, no DOI or URL; pages, chapter, month
if grep -q '‘Just Trust Us’, \\fIComparative Legal History\\fP 3, no. 1 (June 2015): 110–30' "$tmp/uk.out" &&
   grep -q '‘The Compulsion of Legality’, chap. 2 in' "$tmp/uk.out" && grep -q '33–59' "$tmp/uk.out" &&
   ! grep -q 'doi.org\|example.org' "$tmp/uk.out" && grep -q 'no option metric' "$tmp/bad.err"; then
    echo "PASS: chicago,british,nodoi,nourl"
else
    echo "FAIL: chicago,british,nodoi,nourl:"
    sed 's/^/    /' "$tmp/uk.out" "$tmp/bad.err" | head -20
    fail=1
fi

exit $fail
