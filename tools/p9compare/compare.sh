#!/bin/sh
#
# compare.sh [-d dir] [-q] [file.tr ...]: each file (tests/p9/*.tr by
# default) set by Plan 9's troff (build.sh's, in dir) and by this one (in
# emu, in the tree $ROOT: InferNode's with this package over it), their
# pages as text (norm.py: each line's place in points, its words, its
# size and font where they change) and what each said, side by side;
# -q only the files whose pages or messages differ.  The two set on
# different devices and fonts: what differs is to be read, not counted.
d=${TMPDIR:-/tmp}/p9compare
quiet=0
while [ $# -gt 0 ]; do
	case $1 in
	-d) d=$2; shift 2 ;;
	-q) quiet=1; shift ;;
	*) break ;;
	esac
done
here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../.." && pwd)
[ -x "$d/p9troff" ] || { echo "compare.sh: no $d/p9troff: run build.sh first" >&2; exit 1; }
[ -n "$ROOT" ] || { echo "compare.sh: ROOT: the tree troff runs in" >&2; exit 1; }
EMU=$ROOT/emu/$(uname -s | sed 's/Darwin/MacOSX/')/o.emu
[ $# -gt 0 ] || set -- "$pkg"/tests/p9/*.tr
w=$(mktemp -d "${TMPDIR:-/tmp}/p9cmp.XXXXXX")
trap 'rm -rf "$w"' EXIT
for f in "$@"; do cp "$f" "$w/"; done
cd "$w"
for f in *.tr; do
	b=${f%.tr}
	PLAN9=$d/p9root timeout 10 "$d/p9troff" "$f" > "$b.p9.out" 2> "$b.p9.err"
done
printf 'load std\nfor f in *.tr {\n\tb=`{echo $f | sed '"'"'s/\\.tr$//'"'"'}\n\ttroff $f > $b.ne.out >[2] $b.ne.err\n}\n' > run.sh
SDL_VIDEODRIVER=dummy timeout 300 "$EMU" -c1 -r"$ROOT" /dis/sh.dis -c "cd '#U*$w'; run run.sh" </dev/null >/dev/null 2>&1
for f in *.tr; do
	b=${f%.tr}
	python3 "$here/norm.py" "$b.p9.out" > "$b.p9.txt" 2>/dev/null
	python3 "$here/norm.py" "$b.ne.out" > "$b.ne.txt" 2>/dev/null
	if cmp -s "$b.p9.txt" "$b.ne.txt" && cmp -s "$b.p9.err" "$b.ne.err"; then
		[ $quiet = 1 ] || echo "== $b: the same"
		continue
	fi
	echo "== $b (Plan 9 < > ours)"
	diff "$b.p9.txt" "$b.ne.txt" | sed 's/^/  /'
	if ! cmp -s "$b.p9.err" "$b.ne.err"; then
		echo "  -- said:"
		diff "$b.p9.err" "$b.ne.err" | sed 's/^/  /'
	fi
done
