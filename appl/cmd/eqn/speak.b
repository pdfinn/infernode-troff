#
# speak.b: an equation said in words, for those who hear it read (set
# speech 1: a tagged PDF's Formula's description, tok.b's tagalt), as a
# screen reader's ClearSpeak says it: "x squared plus y squared equals r
# squared", "the fraction with numerator a plus b and denominator c",
# "the sum from i equals 1 to n of i", "f of x"
#
# It reads eqn's source as eqn reads it (a word, a quoted string, or one
# of eqn's operators; braces group), not its output.
#

sp_toks: array of string;
sp_glued: array of int;		# a token with no blank before it (eqn's word goes on)
sp_i := 0;

speak(src: string): string
{
	sp_toks = sp_lex(src);
	sp_i = 0;
	s := sp_list(nil);
	# one blank between words, none before a comma
	r := "";
	blank := 0;
	for(i := 0; i < len s; i++){
		c := s[i];
		if(c == ' '){
			blank = r != "";
			continue;
		}
		if((c == ',' || c == ';') && (r == "" || r[len r - 1] == ',' || r[len r - 1] == ';'))
			continue;	# one pause, not two
		if(blank && c != ',' && c != ';')
			r[len r] = ' ';
		blank = 0;
		r[len r] = c;
	}
	while(r != "" && (r[len r - 1] == ',' || r[len r - 1] == ';'))
		r = r[0:len r - 1];
	return r;
}

SP_OPS: con "<= >= != == -> <- => +- -+ << >> ";

sp_lex(s: string): array of string
{
	l: list of (string, int);
	blank := 1;
	for(i := 0; i < len s; ){
		c := s[i];
		t: string;
		if(c == ' ' || c == '\t' || c == '\n'){
			blank = 1;
			i++;
			continue;
		}
		if(c == '{' || c == '}' || c == '~' || c == '^'){
			l = (s[i:i + 1], 0) :: l;
			blank = 1;
			i++;
			continue;
		}
		if(c == '\\' && i + 1 < len s){
			# troff's escapes: a character by name a word; others none
			d := s[i + 1];
			if(d == '(' && i + 3 < len s){
				t = s[i:i + 4];
				i += 4;
			}else if(d == '['){
				j := i + 2;
				while(j < len s && s[j] != ']')
					j++;
				t = s[i:j + 1];
				i = j + 1;
			}else{
				# a string's, a font's or a size's change, a space
				j := i + 2;
				if(d == '*' || d == 'f' || d == 's'){
					if(j < len s && s[j] == '(')
						j += 3;
					else if(j < len s && s[j] == '['){
						while(j < len s && s[j] != ']')
							j++;
						j++;
					}else
						j++;
				}
				i = j;
				continue;
			}
		}else if(c == '"'){
			j := i + 1;
			while(j < len s && s[j] != '"')
				j++;
			t = s[i:j];	# its opening quote marks it
			i = j + 1;
		}else if(i + 1 < len s && sp_isop(s[i:i + 2])){
			n := 2;
			if(s[i:i + 2] == ".." && i + 2 < len s && s[i + 2] == '.')
				n = 3;
			t = s[i:i + n];
			i += n;
		}else if(sp_isalnum(c) || c == '*' && i + 1 < len s && sp_isalnum(s[i + 1])){
			j := i + 1;
			while(j < len s && (sp_isalnum(s[j]) || s[j] == '.' && j + 1 < len s && s[j + 1] >= '0' && s[j + 1] <= '9'))
				j++;
			t = s[i:j];
			i = j;
		}else{
			t = s[i:i + 1];
			i++;
		}
		l = (t, !blank) :: l;
		blank = 0;
	}
	a := array[len l] of string;
	sp_glued = array[len l] of int;
	for(k := len a - 1; k >= 0; k--){
		(a[k], sp_glued[k]) = hd l;
		l = tl l;
	}
	return a;
}

sp_isop(s: string): int
{
	if(s == "..")
		return 1;
	for(i := 0; i + 2 <= len SP_OPS; i += 3)
		if(SP_OPS[i:i + 2] == s)
			return 1;
	return 0;
}

sp_isalnum(c: int): int
{
	return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c >= 16r80;
}

sp_peek(): string
{
	if(sp_i < len sp_toks)
		return sp_toks[sp_i];
	return nil;
}

sp_next(): string
{
	if(sp_i < len sp_toks)
		return sp_toks[sp_i++];
	return nil;
}

SP_ROW: con 16r1;	# between a pile's rows

# boxes until one of stops (read past it) or the end
sp_list(stops: list of string): string
{
	r := sp_list1(stops);
	# a pile's rows, said apart
	s := "";
	for(i := 0; i < len r; i++)
		if(r[i] == SP_ROW)
			s += "; ";
		else
			s[len s] = r[i];
	return s;
}

# two piles side by side, as their rows: the first's first and the
# second's first, and so on
sp_zip(a, b: string): string
{
	ra := sp_split(a);
	rb := sp_split(b);
	s := "";
	while(ra != nil || rb != nil){
		row := "";
		if(ra != nil){
			row = hd ra;
			ra = tl ra;
		}
		if(rb != nil){
			row += " " + hd rb;
			rb = tl rb;
		}
		if(s != "")
			s[len s] = SP_ROW;
		s += row;
	}
	return s;
}

sp_split(s: string): list of string
{
	l: list of string;
	b := 0;
	for(i := 0; i <= len s; i++)
		if(i == len s || s[i] == SP_ROW){
			l = s[b:i] :: l;
			b = i + 1;
		}
	r: list of string;
	for(; l != nil; l = tl l)
		r = hd l :: r;
	return r;
}

sp_haspile(s: string): int
{
	for(i := 0; i < len s; i++)
		if(s[i] == SP_ROW)
			return 1;
	return 0;
}

sp_list1(stops: list of string): string
{
	r := "";
	lastpile: string;	# the pile just said, if one was
	prevfn := 0;
	for(;;){
		t := sp_peek();
		if(t == nil)
			return r;
		for(l := stops; l != nil; l = tl l)
			if(hd l == t){
				sp_next();
				return r;
			}
		if(t == "}"){		# out of place
			sp_next();
			continue;
		}
		# |x|, the floor and the ceiling of what is between
		if(t == "|" || t == "\\(lf" || t == "\\(lc"){
			close := "|";
			w := "the absolute value of ";
			case t {
			"\\(lf" =>	(close, w) = ("\\(rf", "the floor of ");
			"\\(lc" =>	(close, w) = ("\\(rc", "the ceiling of ");
			}
			if(sp_ahead(close)){
				sp_next();
				r += " " + w + sp_list(close :: nil) + ",";
				prevfn = 0;
				continue;
			}
		}
		# f(x): f of x
		if(t == "(" && prevfn){
			sp_next();
			r += " of " + sp_list(")" :: nil);
			prevfn = 0;
			continue;
		}
		n := sp_i;
		(b, isfn) := sp_box();
		if(sp_i == n){
			sp_next();
			continue;
		}
		if(b == "")	# (a space)
			continue;
		if(lastpile != nil && sp_haspile(b) && len r >= len lastpile && r[len r - len lastpile:] == lastpile){
			r = r[0:len r - len lastpile] + sp_zip(lastpile, b);
			lastpile = nil;
		}else{
			r += " " + b;
			lastpile = nil;
			if(sp_haspile(b))
				lastpile = b;
		}
		prevfn = isfn;
	}
}

# whether the token is ahead, at this level of braces
sp_ahead(t: string): int
{
	d := 0;
	for(i := sp_i + 1; i < len sp_toks; i++){
		case sp_toks[i] {
		"{" =>	d++;
		"}" =>
			if(--d < 0)
				return 0;
		* =>
			if(d == 0 && sp_toks[i] == t)
				return 1;
		}
	}
	return 0;
}

# a box: what is over or chosen from what
sp_box(): (string, int)
{
	(b, isfn) := sp_left();
	for(;;){
		case sp_peek() {
		"over" =>
			sp_next();
			(d, nil) := sp_left();
			if(sp_simple(b) && sp_simple(d))
				b = b + " over " + d;
			else
				b = "the fraction with numerator " + b + " and denominator " + d + ",";
			isfn = 0;
		"choose" =>
			sp_next();
			(d, nil) := sp_left();
			b = b + " choose " + d;
			isfn = 0;
		* =>
			return (b, isfn);
		}
	}
}

# whether what is said is one word (a number, a letter)
sp_simple(s: string): int
{
	for(i := 0; i < len s; i++)
		if(s[i] == ' ')
			return 0;
	return 1;
}

# a primary and what follows it: scripts, limits, accents; a script's
# or a limit's own stopping where eqn's do (x sub i sup 2: i's sub stops
# at sup; sum from i to n: i's at to)
SP_SUB, SP_SUP, SP_FROM: con 1 << iota;

sp_left(): (string, int)
{
	return sp_left1(0);
}

sp_left1(stop: int): (string, int)
{
	(b, isfn, op) := sp_primary();
	sub, sup, from, upto: string;
	for(;;){
		t := sp_peek();
		if((stop & SP_SUB) && (t == "sup" || t == "from" || t == "to") ||
				(stop & SP_SUP) && (t == "from" || t == "to") ||
				(stop & SP_FROM) && (t == "to" || t == "from"))
			t = nil;
		case t {
		"sub" =>
			sp_next();
			(sub, nil) = sp_left1(SP_SUB);
		"sup" =>
			sp_next();
			(sup, nil) = sp_left1(SP_SUP);
		"from" =>
			sp_next();
			(from, nil) = sp_left1(SP_FROM);
		"to" =>
			sp_next();
			(upto, nil) = sp_left1(SP_FROM);
		"bar" =>
			sp_next();
			b += " bar";
		"under" =>
			sp_next();
			b += " underlined";
		"hat" =>
			sp_next();
			b += " hat";
		"tilde" =>
			sp_next();
			b += " tilde";
		"vec" =>
			sp_next();
			b = "vector " + b;
		"dyad" =>
			sp_next();
			b = "dyad " + b;
		"dot" =>
			sp_next();
			b += " dot";
		"dotdot" =>
			sp_next();
			b += " double dot";
		* =>
			# a big operator's limits, its scripts as limits too
			if(op != nil){
				lo := from;
				if(lo == nil)
					lo = sub;
				hi := upto;
				if(hi == nil)
					hi = sup;
				if(op == "the limit" && lo != nil)
					b = "the limit as " + lo;
				else{
					b = op;
					if(lo != nil)
						b += " from " + lo;
				}
				if(hi != nil)
					b += " to " + hi;
				return (b + " of", 0);
			}
			if(from != nil)
				b += " under " + from;
			if(upto != nil)
				b += " over " + upto;
			if(sub != nil){
				if(sp_simple(sub))
					b += " sub " + sub;
				else
					b += " sub " + sub + ", end sub,";
			}
			if(sup != nil){
				if(sup == "2")
					b += " squared";
				else if(sup == "3")
					b += " cubed";
				else if(sup == "prime")
					b += " prime";
				else if(sp_simple(sup))
					b += " to the " + sup;
				else
					b += " raised to the power " + sup + ", end power,";
			}
			return (b, isfn && sub == nil && sup == nil);
		}
	}
}

# a primary: what it says, whether it is a function's name (said "of"
# before a parenthesis), and an operator's words if it is a big one
sp_primary(): (string, int, string)
{
	t := sp_next();
	if(t == nil)
		return ("", 0, nil);
	case t {
	"{" =>
		return (sp_list("}" :: nil), 0, nil);
	"sqrt" =>
		(x, nil) := sp_left();
		if(sp_simple(x))
			return ("the square root of " + x, 0, nil);
		return ("the square root of " + x + ", end root,", 0, nil);
	"root" =>
		(n, nil) := sp_left();
		(x, nil) := sp_left();
		which := n + "th";
		case n {
		"2" =>	which = "square";
		"3" =>	which = "cube";
		}
		return ("the " + which + " root of " + x + ", end root,", 0, nil);
	"left" =>
		l := sp_next();
		inner := sp_list("right" :: nil);
		r := "";
		if(sp_peek() != nil && sp_peek() != "}" && sp_i > 0 && sp_toks[sp_i - 1] == "right")
			r = sp_next();
		if(l != nil && l[0] == '"')
			l = l[1:];
		if(r != nil && r[0] == '"')
			r = r[1:];
		return (sp_delims(l, r, inner), 0, nil);
	"pile" or "lpile" or "cpile" or "rpile" =>
		# its rows apart (SP_ROW), so that piles side by side are said
		# row by row (sp_list)
		rows := sp_rows();
		s := "";
		for(; rows != nil; rows = tl rows){
			if(s != "")
				s[len s] = SP_ROW;
			s += hd rows;
		}
		return (s, 0, nil);
	"matrix" =>
		# its spacing (columns pulled together: aligned equations)
		aligned := 0;
		while(sp_peek() != nil && sp_peek() != "{"){
			if(sp_next() == "-")
				aligned = 1;
		}
		if(sp_peek() == "{")
			sp_next();
		cols: list of list of string;
		nc := 0;
		while((k := sp_peek()) == "col" || k == "ccol" || k == "lcol" || k == "rcol"){
			sp_next();
			while(sp_peek() != nil && sp_peek() != "{")
				sp_next();	# its spacing
			cols = sp_rows() :: cols;
			nc++;
		}
		if(sp_peek() == "}")
			sp_next();
		a := array[nc] of list of string;
		for(c := nc - 1; c >= 0; c--){
			a[c] = hd cols;
			cols = tl cols;
		}
		nr := 0;
		for(c = 0; c < nc; c++)
			if(len a[c] > nr)
				nr = len a[c];
		if(aligned){	# each row a line, its cells one after another
			s := "";
			for(r := 1; r <= nr; r++){
				for(c = 0; c < nc; c++)
					if(a[c] != nil){
						s += " " + hd a[c];
						a[c] = tl a[c];
					}
				s += ";";
			}
			return (s, 0, nil);
		}
		s := "the " + string nr + " by " + string nc + " matrix:";
		for(r := 1; r <= nr; r++){
			s += " row " + string r + ":";
			for(c = 0; c < nc; c++){
				if(a[c] != nil){
					s += " " + hd a[c];
					a[c] = tl a[c];
				}
				if(c + 1 < nc)
					s += ",";
			}
			s += ";";
		}
		return (s, 0, nil);
	"roman" or "italic" or "ital" or "vcenter" or "displaystyle" or "textstyle" or "nolimits" =>
		return sp_primary();
	"bold" or "fat" =>
		(x, isfn, op) := sp_primary();
		return ("bold " + x, isfn, op);
	"size" or "font" or "fwd" or "back" or "up" or "down" =>
		sp_next();
		return sp_primary();
	"type" =>
		sp_next();
		if(sp_peek() == "icorr"){
			sp_next();
			sp_next();
		}
		return sp_primary();
	"mark" or "lineup" or "strut" or "~" or "^" or "\t" or "overbrace" or "underbrace" =>
		if(t == "overbrace" || t == "underbrace"){
			(x, nil) := sp_left();
			w := "over";
			if(t == "underbrace")
				w = "under";
			return ("the brace " + w + " " + x, 0, nil);
		}
		return ("", 0, nil);
	}
	if(t[0] == '"')
		return (t[1:], 0, nil);
	# an eqn word of several (i=1, f(x), x->0): said as its own list
	e := sp_i;
	while(e < len sp_toks && sp_glued[e] && !sp_keyword(sp_toks[e]))
		e++;
	if(e == sp_i)
		return sp_word(t);
	(toks, glued, i) := (sp_toks, sp_glued, sp_i);
	sp_toks = toks[i - 1:e];
	sp_glued = array[len sp_toks] of {* => 0};
	sp_i = 0;
	w := sp_list(nil);
	(sp_toks, sp_glued, sp_i) = (toks, glued, e);
	return (w, 0, nil);
}

# eqn's words that do not go on a word before them
sp_keyword(t: string): int
{
	case t {
	"sub" or "sup" or "from" or "to" or "over" or "choose" or "above" or "right" or
	"bar" or "hat" or "tilde" or "vec" or "dot" or "dotdot" or "dyad" or "under" =>
		return 1;
	}
	return 0;
}

# a pile's or a column's rows
sp_rows(): list of string
{
	if(sp_peek() == "{")
		sp_next();
	rows: list of string;
	for(;;){
		n := sp_i;
		r := sp_list("above" :: "}" :: nil);
		rows = r :: rows;
		if(sp_i == n || sp_i > 0 && sp_toks[sp_i - 1] != "above")
			break;
	}
	l: list of string;
	for(; rows != nil; rows = tl rows)
		l = hd rows :: l;
	return l;
}

sp_delims(l, r, inner: string): string
{
	case l {
	"{" =>
		if(r == ""){
			# cases: a matrix's rows said as its rows
			for(i := 0; i + 7 < len inner; i++)
				if(inner[i:i + 8] == " matrix:"){
					inner = inner[i + 8:];
					break;
				}
			return "cases: " + inner + ",";
		}
	"|" =>
		return "the absolute value of " + inner + ",";
	"floor" or "\\(lf" =>
		return "the floor of " + inner + ",";
	"ceiling" or "\\(lc" =>
		return "the ceiling of " + inner + ",";
	}
	return sp_delim(l, 1) + " " + inner + " " + sp_delim(r, 0);
}

sp_delim(d: string, open: int): string
{
	w := "";
	case d {
	"(" or ")" =>	w = "paren";
	"[" or "]" =>	w = "bracket";
	"{" or "}" =>	w = "brace";
	"<" or ">" or "la" or "ra" =>	w = "angle bracket";
	"" or "\"\"" =>	return "";
	* =>	return d;
	}
	if(open)
		return "open " + w;
	return "close " + w;
}

GREEKSP := array[] of {
	"alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa",
	"lambda", "mu", "nu", "xi", "omicron", "pi", "rho", "sigma", "tau", "upsilon", "phi", "chi",
	"psi", "omega",
};

# a word: a name, a number, an operator
sp_word(t: string): (string, int, string)
{
	case t {
	"+" =>	return ("plus", 0, nil);
	"-" =>	return ("minus", 0, nil);
	"=" =>	return ("equals", 0, nil);
	"!=" =>	return ("is not equal to", 0, nil);
	"<=" =>	return ("is less than or equal to", 0, nil);
	">=" =>	return ("is greater than or equal to", 0, nil);
	"<" =>	return ("is less than", 0, nil);
	">" =>	return ("is greater than", 0, nil);
	"<<" =>	return ("is much less than", 0, nil);
	">>" =>	return ("is much greater than", 0, nil);
	"==" =>	return ("is equivalent to", 0, nil);
	"->" =>	return ("approaches", 0, nil);
	"<-" =>	return ("gets", 0, nil);
	"=>" =>	return ("implies", 0, nil);
	"+-" =>	return ("plus or minus", 0, nil);
	"-+" =>	return ("minus or plus", 0, nil);
	"approx" =>	return ("is approximately equal to", 0, nil);
	"times" =>	return ("times", 0, nil);
	"cdot" =>	return ("dot", 0, nil);
	"/" =>	return ("divided by", 0, nil);
	"!" =>	return ("factorial", 0, nil);
	"," =>	return (",", 0, nil);
	"(" =>	return ("open paren", 0, nil);
	")" =>	return ("close paren", 0, nil);
	"[" =>	return ("open bracket", 0, nil);
	"]" =>	return ("close bracket", 0, nil);
	"|" =>	return ("vertical bar", 0, nil);
	"..." or "cdots" or "ldots" or "vdots" or "ddots" =>	return ("dot dot dot", 0, nil);
	"inf" or "infinity" =>	return ("infinity", 0, nil);
	"partial" =>	return ("partial", 0, nil);
	"nabla" or "del" or "grad" =>	return ("del", 0, nil);
	"hbar" =>	return ("h bar", 0, nil);
	"prime" =>	return ("prime", 0, nil);
	"half" =>	return ("one half", 0, nil);
	"sum" =>	return ("", 0, "the sum");
	"prod" =>	return ("", 0, "the product");
	"coprod" =>	return ("", 0, "the coproduct");
	"int" =>	return ("", 0, "the integral");
	"iint" =>	return ("", 0, "the double integral");
	"iiint" =>	return ("", 0, "the triple integral");
	"oint" =>	return ("", 0, "the contour integral");
	"oiint" =>	return ("", 0, "the surface integral");
	"oiiint" =>	return ("", 0, "the volume integral");
	"union" or "bigcup" =>	return ("", 0, "the union");
	"inter" or "bigcap" =>	return ("", 0, "the intersection");
	"lim" =>	return ("", 0, "the limit");
	"det" =>	return ("the determinant", 1, nil);
	"max" or "min" =>	return ("", 0, "the " + t);
	"sin" or "cos" or "tan" or "cot" or "sec" or "csc" or "sinh" or "cosh" or "tanh" or
	"coth" or "arcsin" or "arccos" or "arctan" or "exp" or "log" or "ln" or "lg" or
	"gcd" or "arg" or "deg" or "dim" or "hom" or "ker" or "Pr" =>
		return (t, 1, nil);
	}
	# Greek by name, as eqn's words, troff's (*a, as tagalt gives \(*a)
	# and UTF-8
	for(i := 0; i < len GREEKSP; i++){
		if(t == GREEKSP[i])
			return (t, 0, nil);
		if(len t == len GREEKSP[i] && t == upper(GREEKSP[i]))
			return ("capital " + GREEKSP[i], 0, nil);
	}
	if(len t == 2 && t[0] == '*'){
		# troff's Greek names, in GREEKNM's order, GREEKSP's
		k := sp_index(GREEKNM, t[1] | 16r20);
		if(k >= 0){
			if(t[1] >= 'A' && t[1] <= 'Z')
				return ("capital " + GREEKSP[k], 0, nil);
			return (GREEKSP[k], 0, nil);
		}
	}
	if(len t == 1 && t[0] >= 16r391 && t[0] <= 16r3C9){
		c := t[0];
		cap := c < 16r3B1;
		if(cap)
			c += 16r20;
		k := c - 16r3B1;
		if(c > 16r3C2)
			k--;
		if(c == 16r3C2)
			k = 17;
		if(k >= 0 && k < len GREEKSP){
			if(cap)
				return ("capital " + GREEKSP[k], 0, nil);
			return (GREEKSP[k], 0, nil);
		}
	}
	if(len t > 2 && t[0] == '\\')
		return (sp_troffname(t), 0, nil);
	case t {
	"≤" =>	return ("is less than or equal to", 0, nil);
	"≥" =>	return ("is greater than or equal to", 0, nil);
	"≠" =>	return ("is not equal to", 0, nil);
	"→" =>	return ("approaches", 0, nil);
	"∞" =>	return ("infinity", 0, nil);
	"±" =>	return ("plus or minus", 0, nil);
	"×" =>	return ("times", 0, nil);
	"·" =>	return ("dot", 0, nil);
	"∂" =>	return ("partial", 0, nil);
	"∇" =>	return ("del", 0, nil);
	}
	# a short word of letters is letters (dx: d x), a function's name
	# if one letter (f, g, h before a parenthesis)
	if(len t > 1 && len t <= 3 && sp_letters(t)){
		r := "";
		for(i = 0; i < len t; i++){
			if(r != "")
				r += " ";
			r[len r] = t[i];
		}
		return (r, 0, nil);
	}
	if(t == "f" || t == "g" || t == "h" || t == "F" || t == "G" || t == "H")
		return (t, 1, nil);
	return (t, 0, nil);
}

sp_index(s: string, c: int): int
{
	for(i := 0; i < len s; i++)
		if(s[i] == c)
			return i;
	return -1;
}

sp_letters(t: string): int
{
	for(i := 0; i < len t; i++)
		if(!(t[i] >= 'a' && t[i] <= 'z' || t[i] >= 'A' && t[i] <= 'Z'))
			return 0;
	return 1;
}

upper(s: string): string
{
	r := s;
	for(i := 0; i < len r; i++)
		if(r[i] >= 'a' && r[i] <= 'z')
			r[i] -= 16r20;
	return r;
}

# a character by troff's name (\\(xx, \\[name]): its words
sp_troffname(t: string): string
{
	n := t[2:];
	if(t[1] == '[')
		n = t[2:len t - 1];
	if(len n == 2 && n[0] == '*'){
		k := sp_index(GREEKNM, n[1] | 16r20);
		if(k >= 0){
			if(n[1] >= 'A' && n[1] <= 'Z')
				return "capital " + GREEKSP[k];
			return GREEKSP[k];
		}
	}
	case n {
	"mi" or "-" =>	return "minus";
	"pl" =>	return "plus";
	"eq" =>	return "equals";
	"<=" =>	return "is less than or equal to";
	">=" =>	return "is greater than or equal to";
	"!=" =>	return "is not equal to";
	"==" =>	return "is equivalent to";
	"~=" or "ap" =>	return "is approximately equal to";
	"->" =>	return "approaches";
	"<-" =>	return "gets";
	"+-" =>	return "plus or minus";
	"mu" or "**" =>	return "times";
	"di" =>	return "divided by";
	"if" =>	return "infinity";
	"pd" =>	return "partial";
	"gr" =>	return "del";
	"de" =>	return "degrees";
	"fm" =>	return "prime";
	"ca" =>	return "intersection";
	"cu" =>	return "union";
	"mo" =>	return "is an element of";
	"sb" =>	return "is a subset of";
	"sp" =>	return "is a superset of";
	"es" =>	return "the empty set";
	"no" =>	return "not";
	"is" =>	return "the integral";
	"sr" =>	return "the square root";
	}
	return "";
}
