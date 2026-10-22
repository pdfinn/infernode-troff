#!/bin/sh
#
# make.sh summer.reconstructed.pdf > linotron202.ms: the figures of
# Condon, Kernighan and Thompson, "Experience with the Mergenthaler
# Linotron 202 Phototypesetter, or, How We Spent Our Summer Vacation"
# (Bell Laboratories, 1980), as one document for book(1).
#
# Figure 1 is fig1.pic.  Figure 2's vectors are read by fig2.py from the
# 2013 reconstruction (www.cs.princeton.edu/~bwk/202/, with the scan of
# the 1980 original) and set to the scan's proportions.  The chess board
# is chess(1)'s.  A1 and A3 are drawn by figa1a3.py, A2 by figa2.py,
# from coordinates measured on those pages.
#
# Needs python3 and pypdf (for Figure 2).
here=$(cd "$(dirname "$0")" && pwd)
[ $# -eq 1 ] || { echo 'usage: make.sh summer.reconstructed.pdf > linotron202.ms' >&2; exit 2; }
pdf=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
w=$(mktemp -d "${TMPDIR:-/tmp}/linotron202.XXXXXX")
trap 'rm -rf "$w"' EXIT
cd "$w"
python3 -I "$here/fig2.py" "$pdf" > e.pic 2>/dev/null || { echo 'make.sh: fig2.py failed' >&2; exit 1; }
python3 -I "$here/figa1a3.py" || exit 1
python3 -I "$here/figa2.py" > a2.pic || exit 1

cat <<'X'
.\" linotron202.ms — the figures of Condon, Kernighan and Thompson,
.\" "Experience with the Mergenthaler Linotron 202 Phototypesetter, or,
.\" How We Spent Our Summer Vacation" (Bell Laboratories, 1980), set
.\" again: pic for the drawings, chess for the board.  Made by make.sh
.\" from the sources beside it; the original, scanned, and its 2013
.\" reconstruction are at www.cs.princeton.edu/~bwk/202/.
.\"
.\"	book -m memo linotron202.ms		# linotron202.pdf
.p
.\" the memo's typewriter labels are bold
.bd CR 36
X
echo '.alt "A block diagram: a disk of character definitions feeding a CPU, a 16-bit minicomputer, which also takes input and drives a CRT that exposes paper drawn past rollers."'
cat "$here/fig1.pic"
printf '.ce\nFigure 1:  Basic Digital Typesetter\n.bp\n'
echo '.alt "The outline of a letter e as chains of short vectors, each running left to right; Create marks where a pair of chains begins, Destroy where it ends."'
cat e.pic
printf '.ce\nFigure 2:  Character representation in the 202\n.sp 2\n'
printf '.CB\nfen 2b1k1nr/1N2p2p/p1p1Pppb/8/2B5/2B2P2/PPP2P1P/1K1R4 b\n.CE\n'
printf '%s\n' '.ce' '\fBPosition after 23 N\(mub7\fP' '.bp'
echo '.alt "Schematic: eight inverting drivers and a parity generator from J1 to the Linotron, the grounded pins, and eight IL100 optical isolators with drivers back to J2."'
cat a1.pic
printf '.ce\nFigure A1: Interface between Linotron 202 and DR11-C\n.bp\n'
echo '.alt "Schematic: the handshake each way, an IL100, a NAND gate and a 74LS74 flip-flop per direction."'
cat a2.pic
printf '.ce\nFigure A2:  Interface Signals\n.sp\n'
echo '.alt "Timing diagram of ac, rqsta, ndry, sc, rqstb and dxmt, arrows showing what causes what."'
cat a3.pic
printf '.ce\nFigure A3: Interface Timing\n'
