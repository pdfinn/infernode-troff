#!/bin/sh
#
# troffns_test.sh — troffns(1)'s part in Xenith: troff's kinds of
# document added to Xenith's /lib/xenith/doctypes, so that a Xenith
# started after it shows troff's documents with nothing edited:
#
#	InferNode's kinds kept, troff's two after them, naming trodoc;
#	run twice, added once;
#	a doctypes that has them already (the user's own) left as it is.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "troffns_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/troff.dis" ] || { echo "troffns_test: SKIP (dis not built)"; exit 77; }
[ -f "$ROOT/troffns" ] || { echo "troffns_test: SKIP (no troffns in the root)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/troffns.XXXXXX")
trap 'rm -rf "$tmp"; rm -f "$ROOT"/tmp/troffns.*.doctypes' EXIT
# a doctypes as InferNode ships it, without troff's (the tree's own may
# have them: CI adds them as the README once had users do)
printf 'pdf\tbinary\t/dis/xenith/doc/pdfdoc.dis\t.pdf\tmagic=%%PDF-\nmarkdown\tsource\t/dis/xenith/doc/mddoc.dis\t.md .markdown\n' >"$tmp/stock"
cp "$tmp/stock" "$tmp/mine"
printf 'roff\tsource\t/dis/xenith/doc/trodoc.dis\t.ms\n' >>"$tmp/mine"
mkdir -p "$ROOT/tmp"

cat >"$tmp/run.sh" <<EOF
load std
bind '#U*$tmp/stock' /lib/xenith/doctypes
run '#U*$ROOT/troffns'
cat /lib/xenith/doctypes > '#U*$tmp/once'
run '#U*$ROOT/troffns'
cat /lib/xenith/doctypes > '#U*$tmp/twice'
bind '#U*$tmp/mine' /lib/xenith/doctypes
run '#U*$ROOT/troffns'
cat /lib/xenith/doctypes > '#U*$tmp/theirs'
EOF
with_timeout 60 "$EMU" -c0 -r"$ROOT" /dis/sh.dis "#U*$tmp/run.sh" </dev/null >"$tmp/emu.log" 2>&1

check() {
    if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi
}
check "InferNode's kinds are kept" 'grep -q "^markdown	source	/dis/xenith/doc/mddoc.dis" "$tmp/once" && grep -q "^pdf	" "$tmp/once"'
check "troff's output is a kind, by its magic" 'grep -q "^troff	binary	/dis/xenith/doc/trodoc.dis	magic=x\\\\x20T\\\\x20$" "$tmp/once"'
check "troff's input is a kind, by its names" 'grep -q "^roff	source	/dis/xenith/doc/trodoc.dis	.ms .mm .me .man .roff .tr .t$" "$tmp/once"'
check "troff's come after InferNode's" '[ "$(grep -n "^roff" "$tmp/once" | cut -d: -f1)" -gt "$(grep -n "^markdown" "$tmp/once" | cut -d: -f1)" ] 2>/dev/null'
check "run twice, they are added once" '[ "$(grep -c trodoc "$tmp/twice")" -eq 2 ] && cmp -s "$tmp/once" "$tmp/twice"'
check "a doctypes that has them is left as it is" 'cmp -s "$tmp/mine" "$tmp/theirs"'

if [ $fail -ne 0 ]; then
    for f in once twice theirs; do echo "--- $f"; cat "$tmp/$f" 2>/dev/null; done
    echo "--- emu"; tail -20 "$tmp/emu.log"
    echo "troffns_test: FAIL"; exit 1
fi
echo "troffns_test: PASS"
