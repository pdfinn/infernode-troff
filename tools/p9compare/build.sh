#!/bin/sh
#
# build.sh [dir]: Plan 9's troff (plan9port's), built on the host, for
# compare.sh: the parts of plan9port it needs (its troff, lib9, its
# fonts and macros) fetched into dir ($TMPDIR/p9compare by default),
# troff compiled there as p9troff, its root (fonts, tmac) p9root.
# Needs git, cc and network access to github.com.
set -e
d=${1:-${TMPDIR:-/tmp}/p9compare}
mkdir -p "$d"
cd "$d"
if [ ! -d plan9port ]; then
	git clone -q --depth 1 --filter=blob:none --sparse https://github.com/9fans/plan9port.git
	(cd plan9port && git sparse-checkout set --no-cone /src/cmd/troff/ /tmac/ /include/ \
		/src/lib9/ /troff/ /lib/hyphen.tex)
fi
P=$d/plan9port
mkdir -p obj
# lib9 (what does not compile on this host is not needed by troff)
for f in "$P"/src/lib9/*.c "$P"/src/lib9/fmt/*.c "$P"/src/lib9/utf/*.c; do
	o=obj/$(echo "$f" | sed "s|$P/||; s|/|_|g; s|\.c$|.o|")
	cc -c -w -O1 -I"$P/include" -I"$P/src/lib9" -I"$P/src/lib9/fmt" -D_DEFAULT_SOURCE \
		-D_GNU_SOURCE -DPLAN9PORT -o "$o" "$f" 2>/dev/null || rm -f "$o"
done
cc -c -w -I"$P/include" -DPLAN9_TARGET="\"$d/p9root\"" -o obj/src_lib9_get9root.o "$P/src/lib9/get9root.c"
rm -f lib9.a
ar rcs lib9.a $(ls obj/*.o | grep -v '_main\.o\|fmt_test\|debugmalloc\|fmtlock2')
# troff
mkdir -p tobj
for f in "$P"/src/cmd/troff/*.c; do
	cc -c -w -O1 -I"$P/include" -DUNICODE -DTMACDIR='"tmac/tmac."' -DFONTDIR='"troff/font"' \
		-DNTERMDIR='"troff/term/tab."' -DALTHYPHENS='"lib/hyphen.tex"' \
		-DTEXHYPHENS='"#9/lib/hyphen.tex"' -DDWBHOME='"#9/"' -DTDEVNAME='"utf"' \
		-DNDEVNAME='"utf"' -o "tobj/$(basename "$f" .c).o" "$f"
done
cc -o p9troff tobj/*.o lib9.a -lm -lutil -lpthread
mkdir -p p9root/troff p9root/tmac p9root/lib
cp -r "$P/troff/font" p9root/troff/
cp "$P"/tmac/tmac.* p9root/tmac/
cp "$P/lib/hyphen.tex" p9root/lib/ 2>/dev/null || true
echo "built $d/p9troff"
