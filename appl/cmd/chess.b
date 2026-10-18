implement Chess;

#
# chess - chess diagrams for troff
#
#	chess [file ...]
#
# Copies troff's input, the files in order or its standard input,
# setting each board between .CB and .CE as a diagram: the position in
# Forsyth-Edwards notation (fen), its dark squares grey, its pieces the
# Unicode chess figures of the device's CH (Noto Sans Symbols 2's), a
# white piece filled white, the files and ranks named along its edges:
#
#	.CB
#	fen r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w
#	size 2i
#	flip
#	nocoords
#	.CE
#
# A board is written as pic writes a picture (.PS height width, its
# drawing, .PE), so that the macros place it as one: -mbook centres it,
# keeps it on one page and tags it a Figure, described by .alt or, with
# none, by the position read out (White: King g1, ...).
#

include "sys.m";
	sys: Sys;

include "draw.m";

include "bufio.m";
	bufio: Bufio;
	Iobuf: import bufio;

Chess: module
{
	init:	fn(nil: ref Draw->Context, args: list of string);
};

out: ref Iobuf;
errs := 0;

init(nil: ref Draw->Context, args: list of string)
{
	sys = load Sys Sys->PATH;
	bufio = load Bufio Bufio->PATH;
	out = bufio->fopen(sys->fildes(1), Bufio->OWRITE);
	args = tl args;
	if(args == nil)
		copy(bufio->fopen(sys->fildes(0), Bufio->OREAD), "-");
	for(; args != nil; args = tl args){
		f := hd args;
		in: ref Iobuf;
		if(f == "-")
			in = bufio->fopen(sys->fildes(0), Bufio->OREAD);
		else
			in = bufio->open(f, Bufio->OREAD);
		if(in == nil){
			sys->fprint(sys->fildes(2), "chess: cannot open %s: %r\n", f);
			raise "fail:open";
		}
		copy(in, f);
	}
	out.flush();
	if(errs)
		raise "fail:errors";
}

# the input copied, each board set
copy(in: ref Iobuf, name: string)
{
	lnum := 0;
	while((l := in.gets('\n')) != nil){
		lnum++;
		if(!isreq(l, ".CB")){
			out.puts(l);
			continue;
		}
		b := ref Board(nil, 2.0, 0, 1, -1);
		start := lnum;
		ended := 0;
		while((l = in.gets('\n')) != nil){
			lnum++;
			if(isreq(l, ".CE")){
				ended = 1;
				break;
			}
			setting(b, l, name, lnum);
		}
		if(!ended)
			complain(name, start, ".CB with no .CE");
		if(b.sq == nil)
			complain(name, start, "a board with no fen");
		else
			board(b);
		out.puts(sys->sprint(".lf %d\n", lnum + 1));
	}
}

isreq(l, r: string): int
{
	return len l >= len r && l[0:len r] == r && (len l == len r || l[len r] == ' ' || l[len r] == '\n' || l[len r] == '\t');
}

complain(name: string, lnum: int, s: string)
{
	sys->fprint(sys->fildes(2), "chess: %s:%d: %s\n", name, lnum, s);
	errs++;
}

Board: adt {
	sq:	array of int;	# a8 to h1, by rank from the eighth: the piece's letter, or 0
	size:	real;		# the board's side, in inches
	flip:	int;		# black at the foot
	coords:	int;		# the files and ranks named
	tomove:	int;		# 'w' or 'b', or -1
};

# a line of a board's settings
setting(b: ref Board, l, name: string, lnum: int)
{
	(n, w) := sys->tokenize(l, " \t\n");
	if(n == 0)
		return;
	case hd w {
	"fen" =>
		if(n < 2){
			complain(name, lnum, "fen: no position");
			return;
		}
		(sq, err) := fen(hd tl w);
		if(err != nil){
			complain(name, lnum, "fen: " + err);
			return;
		}
		b.sq = sq;
		if(n > 2 && (hd tl tl w == "w" || hd tl tl w == "b"))
			b.tomove = (hd tl tl w)[0];
	"size" =>
		s := "";
		if(n > 1)
			s = hd tl w;
		if(s != nil && s[len s - 1] == 'i')
			s = s[0:len s - 1];
		v := real s;
		if(v <= 0.0)
			complain(name, lnum, "size: not a size in inches");
		else
			b.size = v;
	"flip" =>
		b.flip = 1;
	"nocoords" =>
		b.coords = 0;
	* =>
		complain(name, lnum, "unknown setting " + hd w);
	}
}

# the squares of a position in Forsyth-Edwards notation
fen(s: string): (array of int, string)
{
	sq := array[64] of {* => 0};
	r := 0;
	f := 0;
	for(i := 0; i < len s; i++){
		c := s[i];
		if(c == '/'){
			if(f != 8)
				return (nil, sys->sprint("rank %d has %d squares", 8 - r, f));
			r++;
			f = 0;
		}else if(c >= '1' && c <= '8')
			f += c - '0';
		else if(ispiece(c)){
			if(f >= 8 || r >= 8)
				return (nil, sys->sprint("rank %d has more than 8 squares", 8 - r));
			sq[8 * r + f++] = c;
		}else
			return (nil, sys->sprint("%c is not a piece", c));
		if(f > 8)
			return (nil, sys->sprint("rank %d has more than 8 squares", 8 - r));
	}
	if(r != 7 || f != 8)
		return (nil, "not eight ranks of eight squares");
	return (sq, nil);
}

# a piece's figure, filled (black's) and outlined (white's); its name
piece(c: int): (string, string, string)
{
	case c {
	'k' or 'K' =>	return ("♚", "♔", "King");
	'q' or 'Q' =>	return ("♛", "♕", "Queen");
	'r' or 'R' =>	return ("♜", "♖", "Rook");
	'b' or 'B' =>	return ("♝", "♗", "Bishop");
	'n' or 'N' =>	return ("♞", "♘", "Knight");
	'p' or 'P' =>	return ("♟", "♙", "Pawn");
	}
	return (nil, nil, nil);
}

ispiece(c: int): int
{
	(f, nil, nil) := piece(c);
	return f != nil;
}

iswhite(c: int): int
{
	return c >= 'A' && c <= 'Z';
}

# inches as troff's
in(v: real): string
{
	return sys->sprint("%.3fi", v);
}

DARK: con "#c8c8c8";	# the dark squares' grey
MARGIN: con 0.18;	# room for the ranks' names, at the left, and the files', below

board(b: ref Board)
{
	s := b.size / 8.0;		# a square's side
	left := 0.0;
	below := 0.0;
	if(b.coords){
		left = MARGIN;
		below = MARGIN;
	}
	w := left + b.size;
	h := b.size + below;
	# described for a tagged PDF, unless .alt has been
	out.puts(".if '\\*[book-alt]'' .ds book-alt " + describe(b) + "\n");
	out.puts(".PS " + in(h) + " " + in(w) + "\n");
	# the dark squares
	for(r := 0; r < 8; r++)
		for(f := 0; f < 8; f++){
			if((r + f) % 2 == 0)
				continue;
			(x, y) := corner(b, left, s, r, f);
			out.puts("\\v'" + in(y + s) + "'\\h'" + in(x) + "'\\m[" + DARK + "]\\D'P 0 -" + in(s) +
				" " + in(s) + " 0 0 " + in(s) + " -" + in(s) + " 0'\\m[]\n.sp -1\n");
		}
	# the board's edge
	out.puts("\\v'" + in(b.size) + "'\\h'" + in(left) + "'\\D'p 0 -" + in(b.size) + " " + in(b.size) +
		" 0 0 " + in(b.size) + " -" + in(b.size) + " 0'\n.sp -1\n");
	# the pieces, each centred on its square (CH's figures are an em
	# wide, their ink from -0.04 to 0.77 em); a white piece's filled
	# figure set white beneath its outline, so that a dark square does
	# not show through it
	pt := int (s * 72.0 * 0.86 + 0.5);
	for(i := 0; i < 64; i++){
		c := b.sq[i];
		if(c == 0)
			continue;
		(fill, outline, nil) := piece(c);
		(x, y) := corner(b, left, s, i / 8, i % 8);
		g := fill;
		if(iswhite(c))
			g = "\\Z'\\m[white]" + fill + "\\m[]'" + outline;
		out.puts("\\v'" + in(y + s * 0.81) + "'\\h'" + in(x + s / 2.0) + "'\\f[CH]\\s[" + string pt + "]" +
			"\\h'-\\w'" + fill + "'u/2u'" + g + "\\s0\\fP\n.sp -1\n");
	}
	# the files below, the ranks at the left
	if(b.coords){
		for(f = 0; f < 8; f++){
			name := "abcdefgh"[f:f + 1];
			col := f;
			if(b.flip)
				col = 7 - f;
			x := left + s * real col + s / 2.0;
			out.puts("\\v'" + in(b.size + below * 0.8) + "'\\h'" + in(x) + "'\\s[8]\\h'-\\w'" + name +
				"'u/2u'" + name + "\\s0\n.sp -1\n");
		}
		for(r = 0; r < 8; r++){
			name := string (8 - r);
			row := r;
			if(b.flip)
				row = 7 - r;
			y := s * real row + s / 2.0 + 0.035;
			out.puts("\\v'" + in(y) + "'\\h'" + in(left * 0.45) + "'\\s[8]\\h'-\\w'" + name +
				"'u/2u'" + name + "\\s0\n.sp -1\n");
		}
	}
	out.puts(".sp 1+" + in(h) + "\n.PE\n");
}

# the top left corner of the square of rank row r (from the eighth) and
# file f, from the picture's
corner(b: ref Board, left, s: real, r, f: int): (real, real)
{
	if(b.flip){
		r = 7 - r;
		f = 7 - f;
	}
	return (left + s * real f, s * real r);
}

# the position in words: each side's pieces, by kind, and who moves
describe(b: ref Board): string
{
	d := "Chess diagram. White: " + side(b, 1) + ". Black: " + side(b, 0) + ".";
	if(b.tomove == 'w')
		d += " White to move.";
	else if(b.tomove == 'b')
		d += " Black to move.";
	return d;
}

side(b: ref Board, white: int): string
{
	s := "";
	kinds := "kqrbnp";
	for(k := 0; k < len kinds; k++){
		sqs: list of string;
		for(i := 63; i >= 0; i--){
			c := b.sq[i];
			if(c == 0 || iswhite(c) != white || (c | 16r20) != kinds[k])
				continue;
			sqs = "abcdefgh"[i % 8:i % 8 + 1] + string (8 - i / 8) :: sqs;
		}
		if(sqs == nil)
			continue;
		(nil, nil, name) := piece(kinds[k]);
		if(len sqs > 1){
			if(name == "Bishop")
				name = "Bishops";
			else
				name += "s";
		}
		if(s != nil)
			s += ", ";
		s += name + " " + words(sqs);
	}
	if(s == nil)
		s = "no pieces";
	return s;
}

# a, b and c
words(l: list of string): string
{
	s := hd l;
	for(l = tl l; l != nil; l = tl l){
		if(tl l == nil)
			s += " and " + hd l;
		else
			s += ", " + hd l;
	}
	return s;
}
