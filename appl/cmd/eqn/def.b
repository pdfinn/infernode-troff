#
# def.c: definitions and operators
#

NMLEN: con 32;
GNLEN: con 32;
BRLEN: con 64;

# the default macros, name and definition
def_macros := array[] of {
	"<-", "\\(<-",
	"<=", "\\(<=",
	">=", "\\(>=",
	"==", "\\(==",
	"->", "\\(->",
	"!=", "\\(!=",
	"+-", "\\(+-",
	"...", "vcenter roman \"\\ .\\ .\\ .\\ \"",
	",...,", "roman \",\\ .\\ .\\ .\\ ,\\|\"",
	"ALPHA", "\\(*A",
	"BETA", "\\(*B",
	"CHI", "\\(*X",
	"DELTA", "\\(*D",
	"EPSILON", "\\(*E",
	"ETA", "\\(*Y",
	"GAMMA", "\\(*G",
	"IOTA", "\\(*I",
	"KAPPA", "\\(*K",
	"LAMBDA", "\\(*L",
	"MU", "\\(*M",
	"NU", "\\(*N",
	"OMEGA", "\\(*W",
	"OMICRON", "\\(*O",
	"PHI", "\\(*F",
	"PI", "\\(*P",
	"PSI", "\\(*Q",
	"RHO", "\\(*R",
	"SIGMA", "\\(*S",
	"TAU", "\\(*T",
	"THETA", "\\(*H",
	"UPSILON", "\\(*U",
	"XI", "\\(*C",
	"ZETA", "\\(*Z",
	"alpha", "\\(*a",
	"beta", "\\(*b",
	"chi", "\\(*x",
	"delta", "\\(*d",
	"epsilon", "\\(*e",
	"eta", "\\(*y",
	"gamma", "\\(*g",
	"iota", "\\(*i",
	"kappa", "\\(*k",
	"lambda", "\\(*l",
	"mu", "\\(*m",
	"nu", "\\(*n",
	"omega", "\\(*w",
	"omicron", "\\(*o",
	"phi", "\\(*f",
	"pi", "\\(*p",
	"psi", "\\(*q",
	"rho", "\\(*r",
	"sigma", "\\(*s",
	"tau", "\\(*t",
	"theta", "\\(*h",
	"upsilon", "\\(*u",
	"xi", "\\(*c",
	"zeta", "\\(*z",
	"Im", "roman \"Im\"",
	"Re", "roman \"Re\"",
	"and", "roman \"and\"",
	"approx", "\"\\v'-.2m'\\z\\(ap\\v'.25m'\\(ap\\v'-.05m'\"",
	"arc", "roman \"arc\"",
	"cdot", "\\(c.",
	"cos", "roman \"cos\"",
	"cosh", "roman \"cosh\"",
	"coth", "roman \"coth\"",
	"del", "\\(gr",
	"det", "roman \"det\"",
	"dollar", "roman $",
	"exp", "roman \"exp\"",
	"for", "roman \"for\"",
	"grad", "\\(gr",
	"half", "roman \\(12",
	"if", "roman \"if\"",
	"inf", "\\(if",
	"infinity", "\\(if",
	"int", "{vcenter roman size +2 \\(is}",
	"inter", "roman size +2 \\(ca",
	"lim", "roman \"lim\"",
	"ln", "roman \"ln\"",
	"log", "roman \"log\"",
	"max", "roman \"max\"",
	"min", "roman \"min\"",
	"nothing", "",
	"partial", "\\(pd",
	"prime", "roman \\(fm",
	"prod", "{vcenter roman size +2 \\(pr}",
	"sin", "roman \"sin\"",
	"sinh", "roman \"sinh\"",
	"sum", "{vcenter roman size +2 \\(su}",
	"tan", "roman \"tan\"",
	"tanh", "roman \"tanh\"",
	"times", "\\(mu",
	"union", "roman size +2 \\(cu",
};

binops := array[] of {
	"+", "\\(pl", "−", "-", "\\(mi", "÷", "\\(-:", "\\(di", "×", "xx", "\\(mu", "±", "\\(+-", "⊗", "\\(Ox", "⊕", "\\(O+", "∧", "\\(l&", "∨", "\\(l|", "∩", "\\(ca", "∪", "\\(cu", "⋅", "\\(c.",
};

relops := array[] of {
	"<", ">", ":=", "=", "\\(eq", "≅", "\\(cg", "≤", "\\(<=", "≥", "\\(>=", "≠", "\\(!=", "≡", "\\(==", "≈", "\\(~~", "⊃", "\\(sp", "⊇", "\\(ip", "⊄", "\\(!b", "⊂", "\\(sb", "⊆", "\\(ib", "∈", "\\(mo", "∉", "\\(!m", "↔", "\\(ab", "←", "\\(<-", "↑", "\\(ua", "→", "\\(->", "↓", "\\(da",
};

puncs := array[] of {
	".", ",", ";", ":", "!",
};

bracketleft := array[] of {
	"(", "[", "{", "\\(lc", "\\(lf", "\\(la",
};

bracketright := array[] of {
	")", "]", "}", "\\(rc", "\\(rf", "\\(ra",
};

# rows of 8; the empty after them are free
bracketsizes_init := array[] of {
	"(", "(", "\\N'parenleftbig'", "\\N'parenleftBig'", "\\N'parenleftbigg'", "\\N'parenleftBigg'", "", "",
	")", ")", "\\N'parenrightbig'", "\\N'parenrightBig'", "\\N'parenrightbigg'", "\\N'parenrightBigg'", "", "",
	"[", "[", "\\N'bracketleftbig'", "\\N'bracketleftBig'", "\\N'bracketleftbigg'", "\\N'bracketleftBigg'", "", "",
	"]", "]", "\\N'bracketrightbig'", "\\N'bracketrightBig'", "\\N'bracketrightbigg'", "\\N'bracketrightBigg'", "", "",
	"{", "{", "\\N'braceleftbig'", "\\N'braceleftBig'", "\\N'braceleftbigg'", "\\N'braceleftBigg'", "", "",
	"}", "}", "\\N'bracerightbig'", "\\N'bracerightBig'", "\\N'bracerightbigg'", "\\N'bracerightBigg'", "", "",
	"\\(lc", "\\N'ceilingleft'", "\\N'ceilingleftbig'", "\\N'ceilingleftBig'", "\\N'ceilingleftbigg'", "\\N'ceilingleftBigg'", "\\(lc", "",
	"\\(rc", "\\N'ceilingright'", "\\N'ceilingrightbig'", "\\N'ceilingrightBig'", "\\N'ceilingrightbigg'", "\\N'ceilingrightBigg'", "\\(rc", "",
	"\\(lf", "\\N'floorleft'", "\\N'floorleftbig'", "\\N'floorleftBig'", "\\N'floorleftbigg'", "\\N'floorleftBigg'", "\\(lf", "",
	"\\(rf", "\\N'floorright'", "\\N'floorrightbig'", "\\N'floorrightBig'", "\\N'floorrightbigg'", "\\N'floorrightBigg'", "\\(rf", "",
	"\\(la", "\\(la", "\\N'angbracketleft'", "\\N'angbracketleftbig'", "\\N'angbracketleftBig'", "\\N'angbracketleftbigg'", "\\N'angbracketleftBigg'", "",
	"\\(ra", "\\(ra", "\\N'angbracketright'", "\\N'angbracketrightbig'", "\\N'angbracketrightBig'", "\\N'angbracketrightbigg'", "\\N'angbracketrightBigg'", "",
	"|", "|", "|", "|", "|", "", "", "",
	"\\(sr", "\\(sr", "\\N'radical'", "\\N'radicalbig'", "\\N'radicalBig'", "\\N'radicalbigg'", "\\N'radicalBigg'", "",
};

# rows of 8; the empty after them are free
bracketpieces_init := array[] of {
	"(", "\\(LT", "\\(LX", "\\(LB", "", "", "", "",
	")", "\\(RT", "\\(RX", "\\(RB", "", "", "", "",
	"[", "\\(lc", "\\(lx", "\\(lf", "", "", "", "",
	"]", "\\(rc", "\\(rx", "\\(rf", "", "", "", "",
	"{", "\\(lt", "\\(bv", "\\(lb", "\\(lk", "", "", "",
	"}", "\\(rt", "\\(bv", "\\(rb", "\\(rk", "", "", "",
	"\\(lc", "\\(lc", "\\(lx", "\\(lx", "", "", "", "",
	"\\(rc", "\\(rc", "\\(rx", "\\(rx", "", "", "", "",
	"\\(lf", "\\(lx", "\\(lx", "\\(lf", "", "", "", "",
	"\\(rf", "\\(rx", "\\(rx", "\\(rf", "", "", "", "",
	"|", "|", "|", "|", "", "", "", "",
	"\\(sr", "\\N'radicaltp'", "\\N'radicalvertex'", "\\N'radicalbt'", "", "", "", "",
};

bracketsizes: array of array of string;
bracketpieces: array of array of string;

# the tables, their UTF-8 bytes a character each
def_init()
{
	for(i := 0; i < len def_macros; i++)
		def_macros[i] = u8(def_macros[i]);
	for(i = 0; i < len binops; i++)
		binops[i] = u8(binops[i]);
	for(i = 0; i < len relops; i++)
		relops[i] = u8(relops[i]);
	bracketsizes = rows(bracketsizes_init, 32, NSIZES);
	bracketpieces = rows(bracketpieces_init, 32, 8);
}

# n rows of m; a's are 8 long
rows(a: array of string, n: int, m: int): array of array of string
{
	r := array[n] of array of string;
	for(i := 0; i < n; i++){
		r[i] = array[m] of {* => ""};
		if(8 * i < len a)
			for(j := 0; j < 8; j++)
				r[i][j] = u8(a[8 * i + j]);
	}
	return r;
}

# glyphs' types, as chartype gives them
gtype_g := array[128] of {* => ""};
gtype_t := array[128] of {* => 0};

def_typeput(s: string, typ: int)
{
	i: int;
	for(i = 0; i < len gtype_g && gtype_g[i] != ""; i++)
		if(s == gtype_g[i])
			break;
	if(i < len gtype_g){
		gtype_g[i] = s;
		gtype_t[i] = typ;
	}
}

alookup(a: array of string, s: string): int
{
	for(i := 0; i < len a; i++)
		if(s == a[i])
			return 1;
	return 0;
}

def_type(s: string): int
{
	for(i := 0; i < len gtype_g && gtype_g[i] != ""; i++)
		if(s == gtype_g[i])
			return gtype_t[i];
	if(alookup(puncs, s))
		return T_PUNC;
	if(alookup(binops, s))
		return T_BINOP;
	if(alookup(relops, s))
		return T_RELOP;
	if(alookup(bracketleft, s))
		return T_LEFT;
	if(alookup(bracketright, s))
		return T_RIGHT;
	return -1;
}

pieces_find(sign: string): int
{
	for(i := 0; i < len bracketpieces; i++)
		if(bracketpieces[i][0] == sign)
			return i;
	return -1;
}

# the pieces a bracket is made of: top, mid, bot, cen
def_pieces(sign: string): (string, string, string, string)
{
	i := pieces_find(sign);
	if(i >= 0)
		return (bracketpieces[i][1], bracketpieces[i][2], bracketpieces[i][3], bracketpieces[i][4]);
	return (nil, nil, nil, nil);
}

def_piecesput(sign, top, mid, bot, cen: string)
{
	i := pieces_find(sign);
	if(i < 0 && (i = pieces_find("")) < 0)
		return;
	bracketpieces[i][0] = sign;
	bracketpieces[i][1] = top;
	bracketpieces[i][2] = mid;
	bracketpieces[i][3] = bot;
	bracketpieces[i][4] = cen;
}

sizes_find(sign: string): int
{
	for(i := 0; i < len bracketsizes; i++)
		if(bracketsizes[i][0] == sign)
			return i;
	return -1;
}

# a bracket's sizes, nil after the last
def_sizes(sign: string): array of string
{
	sizes := array[NSIZES] of string;
	idx := sizes_find(sign);
	sizes[0] = sign;
	for(i := 1; idx >= 0 && i < NSIZES; i++)
		sizes[i - 1] = bracketsizes[idx][i];
	return sizes;
}

def_sizesput(sign: string, sizes: array of string)
{
	idx := sizes_find(sign);
	if(idx < 0 && (idx = sizes_find("")) < 0)
		return;
	bracketsizes[idx][0] = sign;
	for(i := 1; i < NSIZES; i++)
		bracketsizes[idx][i] = sizes[i - 1];
}

# TeX's parameters, in hundredths of an em
e_axisheight := 23;
e_minimumsize := 5;
e_overhang := 7;
e_nulldelim := 12;
e_scriptspace := 12;
e_thinspace := 17;
e_mediumspace := 22;
e_thickspace := 28;
e_num1 := 70;
e_num2 := 40;
e_denom1 := 70;
e_denom2 := 36;
e_sup1 := 42;
e_sup2 := 37;
e_sup3 := 28;
e_sub1 := 20;
e_sub2 := 23;
e_supdrop := 38;
e_subdrop := 5;
e_xheight := 45;
e_rulethickness := 4;
e_bigopspacing1 := 11;
e_bigopspacing2 := 17;
e_bigopspacing3 := 20;
e_bigopspacing4 := 60;
e_bigopspacing5 := 10;
e_columnsep := 100;
e_baselinesep := 140;
e_bodyheight := 70;
e_bodydepth := 25;
e_textlimits := 0;	# limits as scripts in text, as TeX sets them (not Neateqn's)
# scripts' sizes, as percentages of the text's, as an OpenType math font
# gives them (its MATH table's ScriptPercentScaleDown and
# ScriptScriptPercentScaleDown); 0, Neateqn's: each 7/10 of the one
# above (not Neateqn's)
e_scriptpct := 0;
e_scriptscriptpct := 0;
# TeX's rule 18a whole: a script's shift from its base's top or bottom
# only for a base not a single character, in the script's size; 0,
# Neateqn's: for every base, in the base's (not Neateqn's)
e_texdrop := 0;
# the least gaps between a fraction's bar and its numerator or
# denominator, displayed and in text (FractionNumDisplayStyleGapMin,
# FractionNumeratorGapMin); 0, Neateqn's: 7/2 and 3/2 of the rule's
# thickness (not Neateqn's)
e_fracgapd := 0;
e_fracgapt := 0;
# a matrix as TeX's array: each column its own width, each row its own
# height and depth (a strut's, .7 and .3 of 1.2 ems stretched as the
# text's lines are, at least), the whole centred on the axis; 0,
# Neateqn's: every column the widest's width, every row the tallest's
# (not Neateqn's)
e_texarrays := 0;
# an OpenType math font's own script limits (its MATH table's), in
# hundredths of an em: the least gap between a subscript and a
# superscript set together (SubSuperscriptGapMin; 0, TeX's: four rules'
# thickness), the highest a superscript's bottom is raised to make it
# (SuperscriptBottomMaxWithSubscript; 0, TeX's: 4/5 of the x-height),
# the lowest a superscript's bottom may be (SuperscriptBottomMin; 0,
# TeX's: 1/4 of the x-height), the highest a subscript's top may be
# (SubscriptTopMax; 0, TeX's: 4/5 of the x-height)
# atoms as TeX's: an empty group, {}, an ordinary atom (so that {} = b
# spaces its relation as TeX's does), and a relation at a box's start
# still a relation (only a binary operator made ordinary there); 0,
# Neateqn's: {} nothing, a leading relation ordinary
e_texatoms := 0;
# capital Greek upright, lower-case italic, as TeX sets them; 0,
# Neateqn's: both in gfont
e_texgreek := 0;
# a fraction an ordinary atom, as LaTeX's \\frac makes it (a group,
# {a \\over b}); 0, TeX's \\over: an inner atom, a thin space beside it
e_fracord := 0;
# fractions as TeX's: the numerator and denominator in TeX's styles for
# them (in text style a fraction's parts in script size, in a script
# in scriptscript size), displaystyle and textstyle to ask for a
# display's or text's (\\dfrac, \\cfrac); 0, Neateqn's: in the size
# around
e_texfrac := 0;
# a radical as an OpenType math font gives it (its MATH table's), in
# hundredths of an em: the gap above what is under it, in text and in a
# display (RadicalVerticalGap, RadicalDisplayStyleVerticalGap), its
# rule's thickness (RadicalRuleThickness); its degree's bottom raised by
# a percentage of its height (RadicalDegreeBottomRaisePercent), the
# kerns before and after its degree (RadicalKernBeforeDegree,
# RadicalKernAfterDegree); 0, Neateqn's: TeX's rule 11, a sign a tenth
# larger than it needs
# a delimiter as TeX sizes one: as tall as \\delimiterfactor
# thousandths of what it encloses about the axis, and no more than
# \\delimitershortfall (hundredths of an em) short of it; 0, Neateqn's:
# covering it, a tenth to spare
e_delimfactor := 0;
e_delimshort := 0;
# the gap between a brace and what it is over or under, in hundredths
# of an em (an OpenType math font's StretchStackGapBelowMin)
e_stretchgap := 7;
e_radgap := 0;
e_radgapd := 0;
e_radrule := 0;
e_raddegraise := 60;
e_raddegkb := 5;
e_raddegka := -30;
# a letter (in no font asked for) in the math font's italic alphabet,
# Mathematical Italic (U+1D434 on, as TeX's and unicode-math's), not the
# text's italic; 0, Neateqn's: in gfont
e_mathitalic := 0;
# accents as TeX sets them from the math font's MATH table: its glyph
# for each (accent), aligned on the base glyph's top accent attachment
# (accentpos), raised by what the base passes AccentBaseHeight (in
# hundredths of an em), a wider variant over more than one glyph, bar
# over one glyph a macron; 0, Neateqn's: troff's characters, centred
e_texaccents := 0;
# TeX's \atop and \binom (choose, under tex_fractions): the shifts of a
# stack's top and bottom and their least gap, in display style and
# otherwise (TeX's num1, num3, denom1, denom2, 7 and 3 rule widths;
# OpenType's Stack constants), and the size of its delimiters (TeX's
# delim1 and delim2), in hundredths of an em
e_stacktopd := 0;
e_stacktop := 0;
e_stackbotd := 0;
e_stackbot := 0;
e_stackgapd := 0;
e_stackgap := 0;
e_delim1 := 239;
e_delim2 := 101;
e_accentbase := 45;
# the kern before a base's scripts, in hundredths of an em (Neateqn's
# 5; TeX's none)
e_scriptkern := 5;
e_subsupgap := 0;
e_supbotmaxsub := 0;
e_supbotmin := 0;
e_subtopmax := 0;

S_S1(): int	{ return e_thinspace; }
S_S2(): int	{ return e_mediumspace; }
S_S3(): int	{ return e_thickspace; }

def_set(name: string, val: int)
{
	case name {
	"axis_height" =>	e_axisheight = val;
	"minimum_size" =>	e_minimumsize = val;
	"over_hang" =>	e_overhang = val;
	"null_delimiter_space" =>	e_nulldelim = val;
	"script_space" =>	e_scriptspace = val;
	"thin_space" =>	e_thinspace = val;
	"medium_space" =>	e_mediumspace = val;
	"thick_space" =>	e_thickspace = val;
	"num1" =>	e_num1 = val;
	"num2" =>	e_num2 = val;
	"denom1" =>	e_denom1 = val;
	"denom2" =>	e_denom2 = val;
	"sup1" =>	e_sup1 = val;
	"sup2" =>	e_sup2 = val;
	"sup3" =>	e_sup3 = val;
	"sub1" =>	e_sub1 = val;
	"sub2" =>	e_sub2 = val;
	"sup_drop" =>	e_supdrop = val;
	"sub_drop" =>	e_subdrop = val;
	"x_height" =>	e_xheight = val;
	"default_rule_thickness" =>	e_rulethickness = val;
	"big_op_spacing1" =>	e_bigopspacing1 = val;
	"big_op_spacing2" =>	e_bigopspacing2 = val;
	"big_op_spacing3" =>	e_bigopspacing3 = val;
	"big_op_spacing4" =>	e_bigopspacing4 = val;
	"big_op_spacing5" =>	e_bigopspacing5 = val;
	"column_sep" =>	e_columnsep = val;
	"baseline_sep" =>	e_baselinesep = val;
	"body_height" =>	e_bodyheight = val;
	"body_depth" =>	e_bodydepth = val;
	"text_limits" =>	e_textlimits = val;
	"script_percent_scale_down" =>	e_scriptpct = val;
	"script_script_percent_scale_down" =>	e_scriptscriptpct = val;
	"tex_script_drop" =>	e_texdrop = val;
	"tex_arrays" =>	e_texarrays = val;
	"script_kern" =>	e_scriptkern = val;
	"tex_atoms" =>	e_texatoms = val;
	"tex_greek" =>	e_texgreek = val;
	"fraction_ord" =>	e_fracord = val;
	"math_italic" =>	e_mathitalic = val;
	"tex_accents" =>	e_texaccents = val;
	"stack_top_display_shift_up" =>	e_stacktopd = val;
	"stack_top_shift_up" =>	e_stacktop = val;
	"stack_bottom_display_shift_down" =>	e_stackbotd = val;
	"stack_bottom_shift_down" =>	e_stackbot = val;
	"stack_display_gap_min" =>	e_stackgapd = val;
	"stack_gap_min" =>	e_stackgap = val;
	"delim1" =>	e_delim1 = val;
	"delim2" =>	e_delim2 = val;
	"accent_base_height" =>	e_accentbase = val;
	"tex_fractions" =>	e_texfrac = val;
	"stretch_stack_gap" =>	e_stretchgap = val;
	"delimiter_factor" =>	e_delimfactor = val;
	"delimiter_shortfall" =>	e_delimshort = val;
	"radical_vertical_gap" =>	e_radgap = val;
	"radical_display_vertical_gap" =>	e_radgapd = val;
	"radical_rule_thickness" =>	e_radrule = val;
	"radical_degree_bottom_raise_percent" =>	e_raddegraise = val;
	"radical_kern_before_degree" =>	e_raddegkb = val;
	"radical_kern_after_degree" =>	e_raddegka = val;
	"sub_superscript_gap_min" =>	e_subsupgap = val;
	"superscript_bottom_max_with_subscript" =>	e_supbotmaxsub = val;
	"superscript_bottom_min" =>	e_supbotmin = val;
	"subscript_top_max" =>	e_subtopmax = val;
	"fraction_display_gap" =>	e_fracgapd = val;
	"fraction_gap" =>	e_fracgapt = val;
	}
}

# superscripts' style
ts_sup(style: int): int
{
	sz := min(2, TS_SZ(style) + 1);
	return TS_MK(sz, TS_0(style));
}

# subscripts'
ts_sub(style: int): int
{
	sz := min(2, TS_SZ(style) + 1);
	return TS_MK(sz, 1);
}

# numerators'
ts_num(style: int): int
{
	if(TS_DX(style)){
		if(TS_0(style))
			return TS_T0;
		return TS_T;
	}
	sz := min(2, TS_SZ(style) + 1);
	return TS_MK(sz, TS_0(style));
}

# denominators'
ts_denom(style: int): int
{
	if(TS_DX(style))
		return TS_T0;
	sz := min(2, TS_SZ(style) + 1);
	return TS_MK(sz, 1);
}

# the cost of breaking a line after an atom
brcost_type := array[32] of {* => 0};
brcost_cost := array[32] of {* => 0};
brcost_n := 0;

def_brcost(typ: int): int
{
	for(i := 0; i < brcost_n; i++)
		if(brcost_type[i] == typ && brcost_cost[i] > 0)
			return brcost_cost[i];
	return 100000;
}

def_brcostput(typ, cost: int)
{
	if(typ == 0)
		brcost_n = 0;
	i: int;
	for(i = 0; i < brcost_n; i++)
		if(brcost_type[i] == typ)
			break;
	more := 0;
	if(i >= brcost_n)
		more = 1;
	if(typ <= 0 || i + more >= len brcost_type)
		return;
	brcost_type[i] = typ;
	brcost_cost[i] = cost;
	if(i >= brcost_n)
		brcost_n = i + 1;
}

# the characters that chop equations
chopped := "^~\"\t";

def_chopped(c: int): int
{
	return strchr("\n {}", c) || strchr(chopped, c);
}

def_choppedset(c: string)
{
	chopped = c;
}

# glyphs' top accent attachments, in thousandths of an em (accentpos)
accpos_gl: list of string;
accpos_val: list of int;

def_accentposput(gl: string, val: int)
{
	accpos_gl = gl :: accpos_gl;
	accpos_val = val :: accpos_val;
}

# a glyph's top accent attachment; ok 0 if it has none
def_accentpos(gl: string): (int, int)
{
	v := accpos_val;
	for(g := accpos_gl; g != nil; g = tl g){
		if(hd g == gl)
			return (1, hd v);
		v = tl v;
	}
	return (0, 0);
}

# an accent's glyph and its wider variants, each with its attachment and
# width (accent), in thousandths of an em
Accvar: adt {
	gl:	string;
	pos:	int;
	wd:	int;
};
accents: list of (string, array of Accvar);

def_accentput(name: string, vars: array of Accvar)
{
	accents = (name, vars) :: accents;
}

def_accent(name: string): array of Accvar
{
	for(a := accents; a != nil; a = tl a){
		(n, vars) := hd a;
		if(n == name)
			return vars;
	}
	return nil;
}
