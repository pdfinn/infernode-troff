#!/bin/sh
#
# trodoc_live_test.sh — troff's input shown in Xenith as it is written
# (trodoc, the engine; docview's live preview): in a headless Xenith,
# a document opened, its twin (Zerox) rendered, then
#
#	an article (.\" book -m article -S numeric -p works.bib) is set by
#	book(1) -l: its citation numbered and its bibliography set by
#	refer, its equation by eqn, its cross-reference to a later
#	section resolved (the passes book makes);
#	a text added in the other window is shown a moment later, not
#	saved (live), its reference to the bibliography still numbered;
#	a chapter using -mbook's headings, with no directive, is set by
#	-mbook (with -ms its .chapter would set nothing);
#	a memorandum whose usage line (.\"	book -m memo memo.ms) says how
#	is set so;
#	a file of -ms with neither is set by troff -ms, as before, a
#	comment that speaks of a book notwithstanding;
#	the document's text has its words apart where whole-paragraph
#	breaking shrank the spaces, and maths italic letters as such.
#
# Needs the SDL GUI emulator (Xenith runs under the dummy driver) and
# the package's commands in the root's /dis (as troffns binds them),
# its engine named for .ms in /lib/xenith/doctypes.

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/xenith_inside.sh"
cd "$ROOT"

for f in dis/troff.dis dis/refer.dis dis/eqn.dis dis/book dis/xenith/doc/trodoc.dis; do
    [ -f "$f" ] || { echo "trodoc_live_test: SKIP ($f not built)"; exit 77; }
done
grep -q 'trodoc.*\.ms' lib/xenith/doctypes 2>/dev/null ||
    { echo "trodoc_live_test: SKIP (no roff in /lib/xenith/doctypes)"; exit 77; }

dir=$(mktemp -d "$ROOT/.trodoc_live.XXXXXX")
d=${dir##*/}
# the references trodoc keeps between times, in the root's /tmp: this
# run's removed after it
mkdir -p "$ROOT/tmp"
before=$(ls "$ROOT/tmp" | grep '^trodoc\.')
cleanup() {
    rm -rf "$dir"
    for f in $(ls "$ROOT/tmp" | grep '^trodoc\.'); do
        printf '%s\n' "$before" | grep -qxF "$f" || rm -f "$ROOT/tmp/$f"
    done
}
trap cleanup EXIT
cp examples/works.bib examples/memo.ms "$dir/"

cat >"$dir/art.ms" <<'EOF'
.\" book -m article -S numeric -p works.bib
.title "Alpha Article"
.author "A. Writer"
.maketitle
.section "Opening" opening
Paragraphs are best broken whole.
.cite knuthplass1981
See section \*[ref closing] for more.
.EQ
x sup 2 + y sup 2 = z sup 2
.EN
.section "Closing" closing
Nothing more.
.bibliography
EOF

cat >"$dir/chap.ms" <<'EOF'
.chapter "Beginnings" begin
The first chapter.
EOF

cat >"$dir/plain.ms" <<'EOF'
.\" book reviews, for the newsletter
.TL
Plain Paper
.PP
Set by the macros its name says.
EOF

cat >"$dir/live.sh" <<EOF
load std expr
XENITH=/mnt/xenith
D=/$d
EOF
cat >>"$dir/live.sh" <<'EOF'
failed=0
fn ok { echo 'PASS:' $* }
fn bad { echo 'FAIL:' $*; failed=1 }
fn winof {
	for l in ${split '
' "{cat $XENITH/index}} {
		if {~ $l *^$"*^*} {
			echo ${index 1 ${split ' 	' $l}}
		}
	}
}
fn look {
	file := $1
	sid := `{cat $XENITH/new/ctl}
	sid = ${index 1 $sid}
	echo -n $file > $XENITH/$sid/body
	n := `{echo -n $file | wc -c}
	echo 'ML0 '^$n > $XENITH/$sid/event
	echo clean > $XENITH/$sid/ctl
	echo delete > $XENITH/$sid/ctl
}
fn attr {
	a := $*
	wid := ${index 1 $a}
	name := ${index 2 $a}
	v=()
	for l in ${split '
' "{cat $XENITH/$wid/doc/ctl}} {
		f := ${split ' ' $l}
		if {~ ${index 1 $f} $name} {
			v=${tl $f}
		}
	}
	echo $v
}
fn hasdoctext {
	a := $*
	wid := ${index 1 $a}
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 {
		t=`{cat $XENITH/$wid/doc/text >[2]/dev/null}
		if {! ~ $"t *^${index 2 $a}^*} {sleep 1}
	}
}
fn tagexec {
	a := $*
	wid := ${index 1 $a}
	word := ${index 2 $a}
	echo -n ' '^$word >> $XENITH/$wid/tag
	n=`{cat $XENITH/$wid/tag | wc -c}
	w=`{echo -n $word | wc -c}
	echo 'Mx'^${expr $n $w -}^' '^$n > $XENITH/$wid/event
}
fn other {
	a := $*
	for o in `{winof ${index 1 $a}} {
		if {! ~ $o ${index 2 $a}} {echo $o}
	}
}
# open a file and render a twin of it: twin name; sets aid and bid
fn twin {
	name := $1
	look $D/$name
	aid=()
	for i in 1 2 3 4 5 6 7 8 9 10 {
		if {~ $#aid 0} {
			aid=`{winof $name}
			if {~ $#aid 0} {sleep 1}
		}
	}
	tagexec $aid Zerox
	bid=()
	for i in 1 2 3 4 5 6 7 8 9 10 {
		if {~ $#bid 0} {
			bid=`{other $name $aid}
			if {~ $#bid 0} {sleep 1}
		}
	}
	echo render > $XENITH/$bid/doc/ctl
}

twin art.ms
hasdoctext $bid Nothing
t=`{cat $XENITH/$bid/doc/text}
if {~ $"t *Alpha*Article*} {ok 'an article is shown'} {bad 'article:' $"t}
if {~ $"t *'whole '?1?.*} {ok 'its citation numbered (refer -S numeric)'} {bad 'citation:' $"t}
if {~ $"t *Knuth*} {ok 'its bibliography set'} {bad 'bibliography:' $"t}
if {~ $"t *'section 2 for more'*} {ok 'its reference to a later section resolved'} {bad 'cross-reference:' $"t}
if {~ $"t *'𝑥'*'𝑦'*'𝑧'*} {ok 'its equation set by eqn, its letters maths italic'} {bad 'equation:' $"t}
if {~ `{attr $bid live} 1} {ok 'live'} {bad 'not live'}

echo 'Livelier still.' >> $XENITH/$aid/body
echo '.cite ossanna1976' >> $XENITH/$aid/body
hasdoctext $bid Livelier
t=`{cat $XENITH/$bid/doc/text}
if {~ $"t *'Livelier still'*} {ok 'an edit in the other window shown, live'} {bad 'live:' $"t}
if {~ $"t *'still '?2?*} {ok 'the citation it added numbered'} {bad 'live citation:' $"t}
if {grep -s Livelier $D/art.ms} {bad 'the edit was saved'} {ok 'and not saved'}

twin chap.ms
hasdoctext $bid first
t=`{cat $XENITH/$bid/doc/text}
if {~ $"t *Beginnings*} {ok 'a chapter with -mbook headings set by -mbook'} {bad 'chapter:' $"t}

twin memo.ms
hasdoctext $bid subject
t=`{cat $XENITH/$bid/doc/text}
if {~ $"t *subject:*} {ok 'a memorandum set by book -m memo, as its usage line says'} {bad 'memo:' $"t}

twin plain.ms
hasdoctext $bid Plain
t=`{cat $XENITH/$bid/doc/text}
if {~ $"t *'Plain Paper'*'Set by the macros'*} {ok 'a file of -ms set by -ms'} {bad 'plain:' $"t}

if {~ $failed 0} {echo 'ALL PASS'}
EOF

XENITH_INSIDE_TIMEOUT=120 xenith_inside trodoc_live_test "/$d/live.sh"
