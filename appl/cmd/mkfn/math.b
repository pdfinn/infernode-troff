#
# math.b: an OpenType math font's MATH table as eqn(1)'s settings
# (mkfn -M), so that eqn sets its mathematics by that font's own
# parameters, glyphs and sizes, as TeX does by unicode-math's: its
# constants (set), its maths italic letters (mathital) with their
# italic corrections (italcorr) and top accent attachments (accentpos),
# its accents and their wider variants (accent), its delimiters' sizes
# and pieces (bracketsizes, bracketpieces), its braces' (bracesizes,
# bracepieces), its big operators' display sizes and italic corrections
# (define), the glyphs of the symbols eqnrc names (define)
#

mathfont := "S";	# its troff name (-t)

# the glyph each character is, from cmap format 12 (all of Unicode) or,
# without one, format 4's codes
cmap12 := -1;

math_cmap(otf: ref Otf)
{
	cmap := otf_table(otf, "cmap");
	if(cmap < 0)
		return;
	nrecs := U16(cmap + 2);
	for(i := 0; i < nrecs; i++){
		rec := cmap + 4 + i * 8;
		tab := cmap + U32(rec + 4);
		if(U16(rec) == 3 && U16(rec + 2) == 10 && U16(tab) == 12)
			cmap12 = tab;
	}
}

# the glyph of character c; -1 if there is none
cglyph(c: int): int
{
	if(cmap12 >= 0){
		n := U32(cmap12 + 12);
		lo := 0;
		hi := n - 1;
		while(lo <= hi){
			m := (lo + hi) / 2;
			g := cmap12 + 16 + 12 * m;
			if(c < U32(g))
				hi = m - 1;
			else if(c > U32(g + 4))
				lo = m + 1;
			else
				return U32(g + 8) + c - U32(g);
		}
		return -1;
	}
	for(i := 0; i < glyph_n; i++)
		if(glyph_code[i] == c)
			return i;
	return -1;
}

# a value in hundredths (or thousandths) of an em, rounded half away from zero
hund(v: int): int
{
	return per(v, 100);
}

thou(v: int): int
{
	return per(v, 1000);
}

per(v, n: int): int
{
	if(v < 0)
		return -((-v * n + upm / 2) / upm);
	return (v * n + upm / 2) / upm;
}

# a coverage table's index of glyph g; -1 if it is not covered
covidx(cov: array of int, g: int): int
{
	for(i := 0; i < len cov; i++)
		if(cov[i] == g)
			return i;
	return -1;
}

# a negative number quoted, as eqn reads one
qnum(n: int): string
{
	if(n < 0)
		return "\"" + string n + "\"";
	return string n;
}

# the MATH table's constants: each MathValueRecord's place, after the
# table's four first values
mc_index := array[] of {
	"AxisHeight", "1", "AccentBaseHeight", "2", "SubscriptShiftDown", "4",
	"SubscriptTopMax", "5", "SubscriptBaselineDropMin", "6", "SuperscriptShiftUp", "7",
	"SuperscriptShiftUpCramped", "8", "SuperscriptBottomMin", "9",
	"SuperscriptBaselineDropMax", "10", "SubSuperscriptGapMin", "11",
	"SuperscriptBottomMaxWithSubscript", "12", "SpaceAfterScript", "13",
	"UpperLimitGapMin", "14", "UpperLimitBaselineRiseMin", "15", "LowerLimitGapMin", "16",
	"LowerLimitBaselineDropMin", "17", "StackTopShiftUp", "18",
	"StackTopDisplayStyleShiftUp", "19", "StackBottomShiftDown", "20",
	"StackBottomDisplayStyleShiftDown", "21", "StackGapMin", "22",
	"StackDisplayStyleGapMin", "23", "StretchStackGapBelowMin", "27",
	"FractionNumeratorShiftUp", "28", "FractionNumeratorDisplayStyleShiftUp", "29",
	"FractionDenominatorShiftDown", "30", "FractionDenominatorDisplayStyleShiftDown", "31",
	"FractionNumeratorGapMin", "32", "FractionNumDisplayStyleGapMin", "33",
	"FractionRuleThickness", "34", "RadicalVerticalGap", "45",
	"RadicalDisplayStyleVerticalGap", "46", "RadicalRuleThickness", "47",
	"RadicalKernBeforeDegree", "49", "RadicalKernAfterDegree", "50",
};

# eqn's settings, each a constant (or the x-height, or a percentage)
mc_sets := array[] of {
	"script_percent_scale_down", "%0",
	"script_script_percent_scale_down", "%1",
	"axis_height", "AxisHeight",
	"x_height", "xheight",
	"default_rule_thickness", "FractionRuleThickness",
	"num1", "FractionNumeratorDisplayStyleShiftUp",
	"num2", "FractionNumeratorShiftUp",
	"denom1", "FractionDenominatorDisplayStyleShiftDown",
	"denom2", "FractionDenominatorShiftDown",
	"sup1", "SuperscriptShiftUp",
	"sup2", "SuperscriptShiftUp",
	"sup3", "SuperscriptShiftUpCramped",
	"sub1", "SubscriptShiftDown",
	"sub2", "SubscriptShiftDown",
	"sup_drop", "SuperscriptBaselineDropMax",
	"sub_drop", "SubscriptBaselineDropMin",
	"big_op_spacing1", "UpperLimitGapMin",
	"big_op_spacing2", "LowerLimitGapMin",
	"big_op_spacing3", "UpperLimitBaselineRiseMin",
	"big_op_spacing4", "LowerLimitBaselineDropMin",
	"script_space", "SpaceAfterScript",
	"fraction_display_gap", "FractionNumDisplayStyleGapMin",
	"fraction_gap", "FractionNumeratorGapMin",
	"sub_superscript_gap_min", "SubSuperscriptGapMin",
	"superscript_bottom_max_with_subscript", "SuperscriptBottomMaxWithSubscript",
	"superscript_bottom_min", "SuperscriptBottomMin",
	"subscript_top_max", "SubscriptTopMax",
	"stack_top_display_shift_up", "StackTopDisplayStyleShiftUp",
	"stack_top_shift_up", "StackTopShiftUp",
	"stack_bottom_display_shift_down", "StackBottomDisplayStyleShiftDown",
	"stack_bottom_shift_down", "StackBottomShiftDown",
	"stack_display_gap_min", "StackDisplayStyleGapMin",
	"stack_gap_min", "StackGapMin",
	"stretch_stack_gap", "StretchStackGapBelowMin",
	"accent_base_height", "AccentBaseHeight",
	"radical_vertical_gap", "RadicalVerticalGap",
	"radical_display_vertical_gap", "RadicalDisplayStyleVerticalGap",
	"radical_rule_thickness", "RadicalRuleThickness",
	"radical_degree_bottom_raise_percent", "%raise",
	"radical_kern_before_degree", "RadicalKernBeforeDegree",
	"radical_kern_after_degree", "RadicalKernAfterDegree",
};

mathtab := -1;		# the MATH table
mconst := -1;		# its constants
minfo := -1;		# its glyph information
mvar := -1;		# its variants

mc(name: string): int
{
	for(i := 0; i < len mc_index; i += 2)
		if(mc_index[i] == name)
			return S16(mconst + 8 + 4 * atoi(mc_index[i + 1]));
	return 0;
}

# a glyph's name in \N'...'
gn(g: int): string
{
	return "\\N'" + glyph_name[g] + "'";
}

# a glyph's variants in one direction, with their advances; and its
# assembly's parts (glyph, advance, extender), in its order, with the
# connectors' lengths at each end
Construction: adt {
	vars:	array of (int, int);
	parts:	array of (int, int, int);
	conn:	array of (int, int);
};

construction(g: int, horiz: int): ref Construction
{
	if(mvar < 0)
		return nil;
	covoff := U16(mvar + 2 + 2 * horiz);
	if(covoff == 0)
		return nil;
	cov := coverage(mvar + covoff);
	i := covidx(cov, g);
	if(i < 0)
		return nil;
	nvert := U16(mvar + 6);
	k := i;
	if(horiz)
		k += nvert;
	cn := mvar + U16(mvar + 10 + 2 * k);
	n := U16(cn + 2);
	c := ref Construction(array[n] of (int, int), nil, nil);
	for(j := 0; j < n; j++)
		c.vars[j] = (U16(cn + 4 + 4 * j), U16(cn + 6 + 4 * j));
	if((asm := U16(cn)) != 0){
		asm += cn;
		np := U16(asm + 4);
		c.parts = array[np] of (int, int, int);
		c.conn = array[np] of (int, int);
		for(j = 0; j < np; j++){
			p := asm + 6 + 10 * j;
			c.parts[j] = (U16(p), U16(p + 6), U16(p + 8) & 1);
			c.conn[j] = (U16(p + 2), U16(p + 4));
		}
	}
	return c;
}

# a value from a glyph-info subtable (italic corrections, top accent
# attachments): its coverage and records; ok 0 if g has none
ginfo(sub: int, g: int): (int, int)
{
	if(minfo < 0 || U16(minfo + sub) == 0)
		return (0, 0);
	t := minfo + U16(minfo + sub);
	i := covidx(coverage(t + U16(t)), g);
	if(i < 0)
		return (0, 0);
	return (1, S16(t + 4 + 4 * i));
}

italcorr(g: int): (int, int)
{
	return ginfo(0, g);
}

topaccent(g: int): (int, int)
{
	return ginfo(2, g);
}

# the delimiters eqn sizes: its name for each, the character
delims := array[] of {
	"(", "(", ")", ")", "[", "[", "]", "]", "{", "{", "}", "}",
	"\\(lc", "⌈", "\\(rc", "⌉", "\\(lf", "⌊", "\\(rf", "⌋",
	"\\(la", "⟨", "\\(ra", "⟩", "|", "|", "\\(sr", "√",
};

# the big operators: eqn's name, the character, whether its limits are beside it
bigops := array[] of {
	("sum", 16r2211, 0), ("prod", 16r220F, 0), ("coprod", 16r2210, 0),
	("int", 16r222B, 1), ("iint", 16r222C, 1), ("oint", 16r222E, 1),
	("bigcup", 16r22C3, 0), ("bigcap", 16r22C2, 0), ("iiint", 16r222D, 1),
	("oiint", 16r222F, 1), ("oiiint", 16r2230, 1), ("bigvee", 16r22C1, 0),
	("bigwedge", 16r22C0, 0), ("bigodot", 16r2A00, 0), ("bigoplus", 16r2A01, 0),
	("bigotimes", 16r2A02, 0), ("biguplus", 16r2A04, 0), ("bigsqcup", 16r2A06, 0),
};

# symbols eqnrc names, by the font's glyph for each
symbols := array[] of {
	("cdots", 16r22EF), ("ldots", 16r2026), ("vdots", 16r22EE), ("ddots", 16r22F1),
	("nabla", 16r2207), ("hbar", 16r210F),
};

# the accents: eqn's name, the combining character
accents := array[] of {
	("hat", 16r0302), ("tilde", 16r0303), ("bar", 16r0304), ("dot", 16r0307),
	("dotdot", 16r0308), ("vec", 16r20D7), ("dyad", 16r20E1),
};

math_write(otf: ref Otf)
{
	math_cmap(otf);
	mathtab = otf_table(otf, "MATH");
	if(mathtab < 0){
		sys->fprint(sys->fildes(2), "mkfn: the font has no MATH table\n");
		raise "fail:math";
	}
	mconst = mathtab + U16(mathtab + 4);
	if(U16(mathtab + 6))
		minfo = mathtab + U16(mathtab + 6);
	if(U16(mathtab + 8))
		mvar = mathtab + U16(mathtab + 8);
	f := "\\f[" + mathfont + "]";
	out(".\\\" " + otf.name + "'s MATH table, by mkfn -M: its constants, maths italic,\n");
	out(".\\\" accents, delimiters, braces and big operators for eqn\n");
	if((g := cglyph(16r23AF)) >= 0){
		out(".char \\(ru " + f + gn(g) + "\n");
		out(".char \\(rn " + f + gn(g) + "\n");
	}
	out(".EQ\n");
	# the constants
	xh := 0;
	if((os2 := otf_table(otf, "OS/2")) >= 0 && U16(os2) >= 2)
		xh = S16(os2 + 86);
	for(i := 0; i < len mc_sets; i += 2){
		k := mc_sets[i + 1];
		v: int;
		case k {
		"%0" =>	v = S16(mconst);
		"%1" =>	v = S16(mconst + 2);
		"%raise" =>	v = S16(mconst + 8 + 4 * 51);
		"xheight" =>
			if(!xh)
				continue;
			v = hund(xh);
		* =>	v = hund(mc(k));
		}
		out("set " + mc_sets[i] + " " + string v + "\n");
	}
	# the maths italic letters: each plain letter's glyph, its italic
	# correction and top accent attachment, in thousandths of an em
	ital: list of (int, int);
	for(c := 'a'; c <= 'z'; c++)
		ital = (c, 16r1D44E + c - 'a') :: ital;
	for(c = 'A'; c <= 'Z'; c++)
		ital = (c, 16r1D434 + c - 'A') :: ital;
	for(c = 16r3B1; c <= 16r3C9; c++)
		ital = (c, 16r1D6FC + c - 16r3B1) :: ital;
	ital = ('h', 16r210E) :: ital;
	names, ics, tas: list of string;
	for(; ital != nil; ital = tl ital){
		(pc, uc) := hd ital;
		if((g = cglyph(uc)) < 0)
			continue;
		names = string pc + " " + glyph_name[g] :: names;
		(ok, v) := italcorr(g);
		if(ok && v)
			ics = glyph_name[g] + " " + qnum(thou(v)) :: ics;
		(ok, v) = topaccent(g);
		if(ok)
			tas = glyph_name[g] + " " + qnum(thou(v)) :: tas;
	}
	writelist("mathital", names);
	writelist("italcorr", ics);
	writelist("accentpos", tas);
	# the accents: the glyph, then its wider variants; each its
	# attachment (its middle, without one) and width
	for(i = 0; i < len accents; i++){
		(name, ac) := accents[i];
		if((g = cglyph(ac)) < 0)
			continue;
		cn := construction(g, 1);
		vars := array[] of {(g, 0)};
		if(cn != nil && len cn.vars)
			vars = cn.vars;
		s := "";
		for(j := 0; j < len vars; j++){
			(vg, adv) := vars[j];
			(ok, at) := topaccent(vg);
			if(!ok)
				at = glyph_wid[vg] / 2;
			s += " " + glyph_name[vg] + " " + qnum(thou(at)) + " " + string thou(adv);
		}
		out("accent " + name + " " + string len vars + s + "\n");
	}
	# the delimiters' sizes, the font's own first; their pieces
	for(i = 0; i < len delims; i += 2){
		ch := delims[i + 1];
		if((g = cglyph(ch[0])) < 0)
			continue;
		first := f + gn(g) + "\\f[P]";
		if(ch[0] < 16r80)
			first = f + ch + "\\f[P]";
		s := " \"" + first + "\"";
		n := 1;
		cn := construction(g, 0);
		if(cn != nil)
			for(j := 0; j < len cn.vars && n < 13; j++){
				(vg, nil) := cn.vars[j];
				if(vg != g){
					s += " \"" + gn(vg) + "\"";
					n++;
				}
			}
		out("bracketsizes " + delims[i] + " " + string n + s + "\n");
	}
	for(i = 0; i < len delims; i += 2){
		cn := construction(cglyph(delims[i + 1][0]), 0);
		if(cn == nil || len cn.parts < 2)
			continue;
		# bottom to top: its ends, its extender, a middle between two
		ext, bot, top, mid: string;
		p := cn.parts;
		for(j := 0; j < len p; j++){
			(pg, nil, isext) := p[j];
			if(isext && ext == nil)
				ext = gn(pg);
		}
		(g0, nil, e0) := p[0];
		(gl, nil, el) := p[len p - 1];
		if(!e0)
			bot = gn(g0);
		if(!el)
			top = gn(gl);
		if(len p == 5){
			(gm, nil, em) := p[2];
			if(!em)
				mid = gn(gm);
		}
		if(ext == nil)
			continue;
		if(bot == nil)
			bot = ext;
		if(top == nil)
			top = ext;
		out("bracketpieces " + delims[i] + " \"" + top + "\" \"" + ext + "\" \"" + bot + "\" \"" + mid + "\"\n");
	}
	# the braces over and under: their sizes, and pieces (left, extender,
	# middle, right, each its width) with their overlap: as much as the
	# connectors allow, not less than the font's least
	for(i = 0; i < 2; i++){
		which := "over";
		bc := 16r23DE;
		if(i){
			which = "under";
			bc = 16r23DF;
		}
		if((g = cglyph(bc)) < 0 || (cn := construction(g, 1)) == nil)
			continue;
		s := "";
		for(j := 0; j < len cn.vars; j++){
			(vg, adv) := cn.vars[j];
			s += " " + glyph_name[vg] + " " + string thou(adv);
		}
		out("bracesizes " + which + " " + string len cn.vars + s + "\n");
		p := cn.parts;
		if(len p != 5)
			continue;
		(lt, ltw, nil) := p[0];
		(ex, exw, nil) := p[1];
		(md, mdw, nil) := p[2];
		(rt, rtw, nil) := p[4];
		ov := -1;
		for(j = 0; j + 1 < len p; j++){
			(nil, e) := cn.conn[j];
			(st, nil) := cn.conn[j + 1];
			if(st < e)
				e = st;
			if(ov < 0 || e < ov)
				ov = e;
		}
		if(ov < U16(mvar))
			ov = U16(mvar);
		out("bracepieces " + which + " " + glyph_name[lt] + " " + string thou(ltw) + " " +
			glyph_name[ex] + " " + string thou(exw) + " " + glyph_name[md] + " " + string thou(mdw) + " " +
			glyph_name[rt] + " " + string thou(rtw) + " " + string thou(ov) + "\n");
	}
	# the big operators: in a display the first size of the font's
	# least display height (DisplayOperatorMinHeight); their italic
	# corrections, in hundredths of an em
	dmin := U16(mconst + 6);
	for(i = 0; i < len bigops; i++){
		(name, oc, beside) := bigops[i];
		if((g = cglyph(oc)) < 0)
			continue;
		dg := g;
		if((cn := construction(g, 0)) != nil){
			for(j := 0; j < len cn.vars; j++){
				(vg, adv) := cn.vars[j];
				dg = vg;
				if(adv >= dmin)
					break;
			}
		}
		s := "define " + name + " @";
		if(beside)
			s += "nolimits ";
		s += "ifdisplay {" + opdef(dg) + "} {" + opdef(g) + "}@\n";
		out(s);
	}
	for(i = 0; i < len symbols; i++){
		(name, sc) := symbols[i];
		if((g = cglyph(sc)) >= 0)
			out("define " + name + " @roman \"" + gn(g) + "\"@\n");
	}
	out(".EN\n");
}

opdef(g: int): string
{
	s := "type op ";
	(ok, v) := italcorr(g);
	if(ok && hund(v))
		s += "icorr " + string hund(v) + " ";
	return s + "vcenter roman \"" + gn(g) + "\"";
}

# a keyword's pairs, eight a line
writelist(kw: string, l: list of string)
{
	a: list of string;
	for(; l != nil; l = tl l)
		a = hd l :: a;
	while(a != nil){
		s := "";
		n := 0;
		for(; a != nil && n < 8; a = tl a){
			s += " " + hd a;
			n++;
		}
		out(kw + " " + string n + s + "\n");
	}
}
