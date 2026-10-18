#
# box.c: equations' boxes
#

Box: adt {
	raw:	string;		# its contents
	szreg:	int;		# the register of its size
	szown:	int;		# its own
	reg:	int;		# the string register of its contents
	atoms:	int;		# the atoms in it
	tbeg:	int;		# the types of its first and last atoms
	tcur:	int;
	style:	int;		# TeX's style
	tomark:	string;		# a register for its width
	sht:	int;		# registers of a strut's height and depth in
	sdp:	int;		# it (TeX's \strut), its ink aside; 0 if none
	lastgl:	string;		# its last glyph, if a maths italic letter (italcorr)
};

box_alloc(szreg, pre, style: int): ref Box
{
	box := ref Box("", szreg, 0, 0, 0, 0, 0, style, nil, 0, 0, nil);
	if(pre)
		box.tcur = pre;
	return box;
}

box_free(box: ref Box)
{
	if(box.reg)
		sregrm(box.reg);
	if(box.szown)
		nregrm(box.szreg);
	if(box.sht){
		nregrm(box.sht);
		nregrm(box.sdp);
	}
}

# a strut at least ht high and dp deep (registers) in a box
box_strutput(box: ref Box, ht, dp: int)
{
	if(!box.sht){
		box.sht = nregmk();
		box.sdp = nregmk();
		printf(".nr " + nregname(box.sht) + " 0+" + nreg(ht) + "\n");
		printf(".nr " + nregname(box.sdp) + " 0+" + nreg(dp) + "\n");
		return;
	}
	printf(".if " + nreg(ht) + ">" + nreg(box.sht) + " .nr " + nregname(box.sht) + " 0+" + nreg(ht) + "\n");
	printf(".if " + nreg(dp) + ">" + nreg(box.sdp) + " .nr " + nregname(box.sdp) + " 0+" + nreg(dp) + "\n");
}

# a box's height and depth (registers) at least its strut's
box_strutdim(box: ref Box, ht, dp: int)
{
	if(!box.sht)
		return;
	if(ht)
		printf(".if " + nreg(box.sht) + ">" + nreg(ht) + " .nr " + nregname(ht) + " 0+" + nreg(box.sht) + "\n");
	if(dp)
		printf(".if " + nreg(box.sdp) + ">" + nreg(dp) + " .nr " + nregname(dp) + " 0+" + nreg(box.sdp) + "\n");
}

# TeX's \strut: .7 and .3 of the baseline (strut, under tex_fractions)
box_strut(box: ref Box)
{
	ht := nregmk();
	dp := nregmk();
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	printf(".nr " + nregname(ht) + " \\n(.v*7/10\n");
	printf(".nr " + nregname(dp) + " \\n(.v*3/10\n");
	box_strutput(box, ht, dp);
	nregrm(ht);
	nregrm(dp);
}

box_put(box: ref Box, s: string)
{
	box.raw += s;
	if(box.reg)
		printf(".as " + sregname(box.reg) + " \"" + s + "\n");
}

# as Neateqn's buffer of LNLEN cuts it
box_putf(box: ref Box, s: string)
{
	if(len s > LNLEN - 1)
		s = s[0:LNLEN - 1];
	box_put(box, s);
}

box_buf(box: ref Box): string
{
	return box.raw;
}

# change the box's point size; the register holding it
box_size(box: ref Box, val: string): int
{
	szreg := box.szreg;
	if(val == nil)
		return szreg;
	if(!box.szown){
		box.szown = 1;
		box.szreg = nregmk();
	}
	if(val[0] == '-' || val[0] == '+')
		printf(".nr " + nregname(box.szreg) + " " + nreg(szreg) + val[0:1] + ptsz(val[1:]) + "\n");
	else{
		# (gsize's +n after the size around)
		for(i := len val - 1; i > 0 && val[i] != ']'; i--)
			if(val[i] == '+' || val[i] == '-'){
				val = val[0:i + 1] + ptsz(val[i + 1:]);
				break;
			}
		printf(".nr " + nregname(box.szreg) + " " + ptsz(val) + "\n");
	}
	return box.szreg;
}

box_move(box: ref Box, dy, dx: int)
{
	if(dy)
		box_putf(box, "\\v'" + string dy + "u*" + nreg(box.szreg) + SZP() + "/100u'");
	if(dx)
		box_putf(box, "\\h'" + string dx + "u*" + nreg(box.szreg) + SZP() + "/100u'");
}

# T_ORD, T_BIGOP, T_BINOP, T_RELOP, T_LEFT, T_RIGHT, T_PUNC, T_INNER
spacing := array[] of {
	array[] of {0, 1, 2, 3, 0, 0, 0, 1},
	array[] of {1, 1, 0, 3, 0, 0, 0, 1},
	array[] of {2, 2, 0, 0, 2, 0, 0, 2},
	array[] of {3, 3, 0, 0, 3, 0, 0, 3},
	array[] of {0, 0, 0, 0, 0, 0, 0, 0},
	array[] of {0, 1, 2, 3, 0, 0, 0, 1},
	array[] of {1, 1, 0, 1, 1, 1, 1, 1},
	array[] of {1, 1, 2, 3, 1, 0, 1, 1},
};

# the space put before a token
box_gaps(box: ref Box, cur: int): int
{
	s := 0;
	a1 := T_ATOM(box.tcur);
	a2 := T_ATOM(cur);
	if(!TS_SZ(box.style) && a1 && a2)
		s = spacing[T_ATOMIDX(a1)][T_ATOMIDX(a2)];
	if(s == 3)
		return S_S3();
	if(s == 2)
		return S_S2();
	if(s)
		return S_S1();
	return 0;
}

# before a character not in italics
box_italiccorrection(box: ref Box)
{
	if(box.atoms && (box.tcur & T_ITALIC))
		box_put(box, icorr(box.lastgl));
	box.tcur &= ~T_ITALIC;
	box.lastgl = nil;
}

# the italic correction after a glyph: the font's (italcorr), if eqnrc
# gives its maths italic's, else troff's (\/)
icorr(gl: string): string
{
	if(gl == nil || italcorrs == nil)
		return "\\/";
	(ok, v) := def_italcorr(gl);
	if(!ok || !v)
		return "";
	return "\\h'" + string v + "m/1000u'";
}

box_fixatom(cur, pre: int): int
{
	if(cur == T_BINOP && (!pre || pre == T_RELOP || pre == T_BIGOP ||
			pre == T_LEFT || pre == T_PUNC))
		return T_ORD;
	if(cur == T_RELOP && (!pre || pre == T_LEFT) && !e_texatoms)
		return T_ORD;
	return cur;
}

box_beforeput(box: ref Box, typ, breakable: int)
{
	if(box.atoms){
		autogaps := box_gaps(box, T_ATOM(typ));
		# TeX's: a maths italic letter's italic correction after it
		# whatever follows (but its scripts)
		if(!(typ & T_ITALIC) || e_mathitalic)
			box_italiccorrection(box);
		if(autogaps && typ != T_GAP && box.tcur != T_GAP){
			box_italiccorrection(box);
			if(breakable)	# a space as wide as the gap
				box_putf(box, "\\s[" + ECURSZ() + "*" + string autogaps + "u*" + nreg(box.szreg) + SZP() +
					"/100u/\\w' 'u]\\j'" + string def_brcost(T_ATOM(box.tcur)) + "' \\s0");
			else
				box_putf(box, "\\h'" + string autogaps + "u*" + nreg(box.szreg) + SZP() + "/100u'");
		}
	}
	if(box.tomark != nil){
		printf(".nr " + box.tomark + " 0\\w'" + box_toreg(box) + "'\n");
		box.tomark = nil;
	}
}

box_afterput(box: ref Box, typ: int)
{
	box.atoms++;
	box.tcur = T_FONT(typ) | box_fixatom(T_TOK(typ), T_TOK(box.tcur));
	if(!box.tbeg)
		box.tbeg = box.tcur;
}

box_puttext(box: ref Box, typ: int, s: string)
{
	if(len s > LNLEN - 1)
		s = s[0:LNLEN - 1];
	box_beforeput(box, typ, 0);
	if(!(box.tcur & T_ITALIC) && (typ & T_ITALIC))
		box_put(box, "\\,");
	box_put(box, s);
	box_afterput(box, typ);
}

box_merge(box, sub: ref Box, breakable: int)
{
	if(sub.sht)	# (a strut alone is empty)
		box_strutput(box, sub.sht, sub.sdp);
	if(box_empty(sub))
		return;
	box_beforeput(box, sub.tbeg, breakable);
	box_toreg(box);
	box_put(box, box_toreg(sub));
	if(!box.tbeg)
		box.tbeg = sub.tbeg;
	# an atom's type fixed only if one is merged
	if(sub.atoms == 1)
		box_afterput(box, sub.tcur);
	else{
		box.tcur = sub.tcur;
		box.atoms += sub.atoms;
	}
	box.lastgl = sub.lastgl;
}

# the larger of registers a and b in dst
roff_max(dst, a, b: int)
{
	printf(".ie " + nreg(a) + ">=" + nreg(b) + " .nr " + nregname(dst) + " 0+" + nreg(a) + "\n");
	printf(".el .nr " + nregname(dst) + " 0+" + nreg(b) + "\n");
}

# a string's width, height and depth
tok_dim(s: string, wd, ht, dp: int)
{
	printf(".nr " + nregname(wd) + " 0\\w'" + s + "'\n");
	if(ht)
		printf(".nr " + nregname(ht) + " 0-\\n[bbury]\n");
	if(dp)
		printf(".nr " + nregname(dp) + " 0\\n[bblly]\n");
}

box_suprise(box: ref Box): int
{
	if(TS_0(box.style))
		return e_sup3;
	if(box.style == TS_D)
		return e_sup1;
	return e_sup2;
}

m100(n: int): string
{
	return "(" + string n + "m/100u)";
}

# whether a box is a single character (TeX's character box): one atom,
# and nothing moved up or down in it
box_ischar(box: ref Box): int
{
	if(box.atoms != 1)
		return 0;
	for(i := 0; i + 1 < len box.raw; i++)
		if(box.raw[i] == '\\' && (box.raw[i + 1] == 'v' || box.raw[i + 1] == '*'))
			return 0;
	return 1;
}

# TeX's script limits, or the font's (def.b)
subsupgap(): string
{
	if(e_subsupgap)
		return m100(e_subsupgap);
	return "(" + string e_rulethickness + "m/100u*4)";
}

supbotmaxsub(): string
{
	if(e_supbotmaxsub)
		return m100(e_supbotmaxsub);
	return "(" + string e_xheight + "m/100u*4/5)";
}

supbotmin(): string
{
	if(e_supbotmin)
		return m100(e_supbotmin);
	return "(" + string e_xheight + "m/100u/4)";
}

subtopmax(): string
{
	if(e_subtopmax)
		return m100(e_subtopmax);
	return "(" + string e_xheight + "m/100u*4/5)";
}

box_sub(box, sub, sup: ref Box)
{
	box_wd := nregmk();
	box_wdnoic := nregmk();
	box_dp := nregmk();
	box_ht := nregmk();
	sub_wd := nregmk();
	sup_wd := nregmk();
	all_wd := nregmk();
	sup_dp := nregmk();
	sub_ht := nregmk();
	sup_rise := nregmk();
	sub_fall := nregmk();
	tmp_18e := nregmk();
	sub_cor := nregmk();
	if(sub != nil)
		box_italiccorrection(sub);
	if(sup != nil)
		box_italiccorrection(sup);
	if(sub != nil)
		tok_dim(box_toreg(box), box_wdnoic, 0, 0);
	box_italiccorrection(box);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_dim(box_toreg(box), box_wd, box_ht, box_dp);
	if(e_scriptkern)
		box_putf(box, "\\h'" + string e_scriptkern + "m/100u'");
	char := e_texdrop && box_ischar(box);
	# an operator's italic correction (type op icorr n): its subscript
	# that much to the left, under it, as TeX sets an integral's
	opic := 0;
	if(box.tcur == T_BIGOP){
		opic = eqn_opic;
		eqn_opic = 0;
	}
	if(sup != nil){
		tok_dim(box_toreg(sup), sup_wd, 0, sup_dp);
		# 18a
		if(char)
			printf(".nr " + nregname(sup_rise) + " 0\n");
		else if(e_texdrop)	# the script's drop, in its size
			printf(".nr " + nregname(sup_rise) + " 0" + nreg(box_ht) + "u-(" + string e_supdrop + "m/100u*" +
				nreg(sup.szreg) + "/" + nreg(box.szreg) + ")\n");
		else
			printf(".nr " + nregname(sup_rise) + " 0" + nreg(box_ht) + "u-(" + string e_supdrop + "m/100u)\n");
		# 18c
		printf(".if " + nreg(sup_rise) + "<" + m100(box_suprise(box)) + " .nr " + nregname(sup_rise) + " " + m100(box_suprise(box)) + "\n");
		printf(".if " + nreg(sup_rise) + "<(" + nreg(sup_dp) + "+" + supbotmin() + ") .nr " +
			nregname(sup_rise) + " 0" + nreg(sup_dp) + "+" + supbotmin() + "\n");
	}
	if(sub != nil){
		tok_dim(box_toreg(sub), sub_wd, sub_ht, 0);
		# 18a
		if(char)
			printf(".nr " + nregname(sub_fall) + " 0\n");
		else if(e_texdrop)
			printf(".nr " + nregname(sub_fall) + " 0" + nreg(box_dp) + "u+(" + string e_subdrop + "m/100u*" +
				nreg(sub.szreg) + "/" + nreg(box.szreg) + ")\n");
		else
			printf(".nr " + nregname(sub_fall) + " 0" + nreg(box_dp) + "u+(" + string e_subdrop + "m/100u)\n");
	}
	if(sub != nil && sup == nil){
		# 18b
		printf(".if " + nreg(sub_fall) + "<" + m100(e_sub1) + " .nr " + nregname(sub_fall) + " " + m100(e_sub1) + "\n");
		printf(".if " + nreg(sub_fall) + "<(" + nreg(sub_ht) + "-" + subtopmax() + ") .nr " +
			nregname(sub_fall) + " 0" + nreg(sub_ht) + "-" + subtopmax() + "\n");
	}
	if(sub != nil && sup != nil){
		# 18d
		printf(".if " + nreg(sub_fall) + "<" + m100(e_sub2) + " .nr " + nregname(sub_fall) + " " + m100(e_sub2) + "\n");
		# 18e
		printf(".if (" + nreg(sup_rise) + "-" + nreg(sup_dp) + ")-(" + nreg(sub_ht) + "-" + nreg(sub_fall) +
			")<" + subsupgap() + " \\{\\\n");
		printf(".nr " + nregname(sub_fall) + " " + subsupgap() + "+" + nreg(sub_ht) +
			"-(" + nreg(sup_rise) + "-" + nreg(sup_dp) + ")\n");
		printf(".nr " + nregname(tmp_18e) + " " + supbotmaxsub() + "-(" + nreg(sup_rise) +
			"-" + nreg(sup_dp) + ")\n");
		printf(".if " + nreg(tmp_18e) + ">0 .nr " + nregname(sup_rise) + " +" + nreg(tmp_18e) + "\n");
		printf(".if " + nreg(tmp_18e) + ">0 .nr " + nregname(sub_fall) + " -" + nreg(tmp_18e) + " \\}\n");
	}
	# the superscript
	if(sup != nil){
		box_putf(box, "\\v'-" + nreg(sup_rise) + "u'" + box_toreg(sup) + "\\v'" + nreg(sup_rise) + "u'");
		if(sub != nil)
			box_putf(box, "\\h'-" + nreg(sup_wd) + "u'");
	}
	# the subscript
	if(sub != nil){
		# its correction
		if(opic)
			printf(".nr " + nregname(sub_cor) + " " + m100(opic) + "\n");
		else{
			printf(".nr " + nregname(sub_cor) + " (" + nreg(box_wd) + "-" + nreg(box_wdnoic) + ")\n");
			printf(".if " + nreg(box_ht) + ">0 .nr " + nregname(sub_cor) + " (" + nreg(box_ht) + "+" + nreg(sub_fall) +
				")*(" + nreg(box_wd) + "-" + nreg(box_wdnoic) + ")/" + nreg(box_ht) + "\n");
		}
		printf(".nr " + nregname(sub_wd) + " -" + nreg(sub_cor) + "\n");
		box_putf(box, "\\h'-" + nreg(sub_cor) + "u'");
		box_putf(box, "\\v'" + nreg(sub_fall) + "u'" + box_toreg(sub) + "\\v'-" + nreg(sub_fall) + "u'");
		if(sup != nil){
			box_putf(box, "\\h'-" + nreg(sub_wd) + "u'");
			roff_max(all_wd, sub_wd, sup_wd);
			box_putf(box, "\\h'+" + nreg(all_wd) + "u'");
		}
	}
	box_putf(box, "\\h'" + string e_scriptspace + "m/100u'");
	nregrm(box_wd);
	nregrm(box_wdnoic);
	nregrm(box_dp);
	nregrm(box_ht);
	nregrm(sub_wd);
	nregrm(sup_wd);
	nregrm(all_wd);
	nregrm(sup_dp);
	nregrm(sub_ht);
	nregrm(sup_rise);
	nregrm(sub_fall);
	nregrm(tmp_18e);
	nregrm(sub_cor);
}

box_from(box, lim, llim, ulim: ref Box)
{
	lim_wd := nregmk();
	lim_ht := nregmk();
	lim_dp := nregmk();
	llim_wd := nregmk();
	ulim_wd := nregmk();
	ulim_dp := nregmk();
	llim_ht := nregmk();
	ulim_rise := nregmk();
	llim_fall := nregmk();
	all_wd := nregmk();
	box_italiccorrection(lim);
	box_beforeput(box, T_BIGOP, 0);
	tok_dim(box_toreg(lim), lim_wd, lim_ht, lim_dp);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	if(ulim != nil)
		tok_dim(box_toreg(ulim), ulim_wd, 0, ulim_dp);
	if(llim != nil)
		tok_dim(box_toreg(llim), llim_wd, llim_ht, 0);
	if(ulim != nil && llim != nil)
		roff_max(all_wd, llim_wd, ulim_wd);
	else if(ulim != nil)
		printf(".nr " + nregname(all_wd) + " " + nreg(ulim_wd) + "\n");
	else
		printf(".nr " + nregname(all_wd) + " " + nreg(llim_wd) + "\n");
	printf(".if " + nreg(lim_wd) + ">" + nreg(all_wd) + " .nr " + nregname(all_wd) + " 0" + nreg(lim_wd) + "\n");
	box_putf(box, "\\h'" + nreg(all_wd) + "u-" + nreg(lim_wd) + "u/2u'");
	box_merge(box, lim, 0);
	box_putf(box, "\\h'-" + nreg(lim_wd) + "u/2u'");
	if(ulim != nil){
		# 13a
		printf(".nr " + nregname(ulim_rise) + " (" + string e_bigopspacing3 + "m/100u)-" + nreg(ulim_dp) + "\n");
		printf(".if " + nreg(ulim_rise) + "<" + m100(e_bigopspacing1) + " .nr " + nregname(ulim_rise) + " " + m100(e_bigopspacing1) + "\n");
		printf(".nr " + nregname(ulim_rise) + " +" + nreg(lim_ht) + "+" + nreg(ulim_dp) + "\n");
		box_putf(box, "\\h'-" + nreg(ulim_wd) + "u/2u'\\v'-" + nreg(ulim_rise) + "u'" + box_toreg(ulim) +
			"\\v'" + nreg(ulim_rise) + "u'\\h'-" + nreg(ulim_wd) + "u/2u'");
	}
	if(llim != nil){
		# 13a
		printf(".nr " + nregname(llim_fall) + " (" + string e_bigopspacing4 + "m/100u)-" + nreg(llim_ht) + "\n");
		printf(".if " + nreg(llim_fall) + "<" + m100(e_bigopspacing2) + " .nr " + nregname(llim_fall) + " " + m100(e_bigopspacing2) + "\n");
		printf(".nr " + nregname(llim_fall) + " +" + nreg(lim_dp) + "+" + nreg(llim_ht) + "\n");
		box_putf(box, "\\h'-" + nreg(llim_wd) + "u/2u'\\v'" + nreg(llim_fall) + "u'" + box_toreg(llim) +
			"\\v'-" + nreg(llim_fall) + "u'\\h'-" + nreg(llim_wd) + "u/2u'");
	}
	box_putf(box, "\\h'" + nreg(all_wd) + "u/2u'");
	box_afterput(box, T_BIGOP);
	nregrm(lim_wd);
	nregrm(lim_ht);
	nregrm(lim_dp);
	nregrm(llim_wd);
	nregrm(ulim_wd);
	nregrm(ulim_dp);
	nregrm(llim_ht);
	nregrm(ulim_rise);
	nregrm(llim_fall);
	nregrm(all_wd);
}

# s's width, and its length (height and depth)
tok_len(s: string, wd, ln, ht, dp: int)
{
	printf(".nr " + nregname(wd) + " 0\\w'" + s + "'\n");
	if(ln)
		printf(".nr " + nregname(ln) + " 0\\n[bblly]-\\n[bbury]-2\n");
	if(dp)
		printf(".nr " + nregname(dp) + " 0\\n[bblly]-1\n");
	if(ht)
		printf(".nr " + nregname(ht) + " 0-\\n[bbury]-1\n");
}

# width, vertical length, height and depth
blen_mk(s: string): array of int
{
	l := array[4] of int;
	for(i := 0; i < 4; i++)
		l[i] = nregmk();
	tok_len(s, l[0], l[1], l[2], l[3]);
	return l;
}

blen_rm(l: array of int)
{
	for(i := 0; i < 4; i++)
		nregrm(l[i]);
}

# a fraction; its font set up before
box_over(box, num, den: ref Box)
{
	num_wd := nregmk();
	num_dp := nregmk();
	den_wd := nregmk();
	den_ht := nregmk();
	all_wd := nregmk();
	num_rise := nregmk();
	den_fall := nregmk();
	bar_wd := nregmk();
	bar_dp := nregmk();
	bar_ht := nregmk();
	bar_fall := nregmk();
	tmp_15d := nregmk();
	bargap := 3 * e_rulethickness / 2;
	if(TS_DX(box.style))
		bargap = 7 * e_rulethickness / 2;
	if(TS_DX(box.style) && e_fracgapd)
		bargap = e_fracgapd;
	if(!TS_DX(box.style) && e_fracgapt)
		bargap = e_fracgapt;
	ftyp := T_INNER;
	if(e_fracord)
		ftyp = T_ORD;
	box_beforeput(box, ftyp, 0);
	box_italiccorrection(num);
	box_italiccorrection(den);
	tok_dim(box_toreg(num), num_wd, 0, num_dp);
	box_strutdim(num, 0, num_dp);
	tok_dim(box_toreg(den), den_wd, den_ht, 0);
	box_strutdim(den, den_ht, 0);
	roff_max(all_wd, num_wd, den_wd);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_len("\\(ru", bar_wd, 0, bar_ht, bar_dp);
	# 15b
	n1 := e_num2;
	d1 := e_denom2;
	if(TS_DX(box.style)){
		n1 = e_num1;
		d1 = e_denom1;
	}
	printf(".nr " + nregname(num_rise) + " 0" + string n1 + "m/100u\n");
	printf(".nr " + nregname(den_fall) + " 0" + string d1 + "m/100u\n");
	# 15d
	printf(".nr " + nregname(tmp_15d) + " (" + nreg(num_rise) + "-" + nreg(num_dp) + ")-((" +
		string e_axisheight + "m/100u)+(" + string e_rulethickness + "m/100u/2))\n");
	printf(".if " + nreg(tmp_15d) + "<" + m100(bargap) + " .nr " + nregname(num_rise) + " +" +
		m100(bargap) + "-" + nreg(tmp_15d) + "\n");
	printf(".nr " + nregname(tmp_15d) + " ((" + string e_axisheight + "m/100u)-(" + string e_rulethickness +
		"m/100u/2))-(" + nreg(den_ht) + "-" + nreg(den_fall) + ")\n");
	printf(".if " + nreg(tmp_15d) + "<" + m100(bargap) + " .nr " + nregname(den_fall) + " +" +
		m100(bargap) + "-" + nreg(tmp_15d) + "\n");
	# the bar's place
	printf(".nr " + nregname(bar_fall) + " 0-" + nreg(bar_dp) + "+" + nreg(bar_ht) + "/2-(" +
		string e_axisheight + "m/100u)\n");
	# a longer bar
	printf(".nr " + nregname(all_wd) + " +2*(" + string e_overhang + "m/100u)\n");
	# the null delimiter's space
	box_putf(box, "\\h'" + nreg(box.szreg) + SZP() + "*" + string e_nulldelim + "u/100u'");
	# the bar
	box_putf(box, "\\v'" + nreg(bar_fall) + "u'\\f[\\n(.f]\\s[" + nreg(box.szreg) + SZU() + "]\\l'" + nreg(all_wd) +
		"u'\\v'-" + nreg(bar_fall) + "u'\\h'-" + nreg(all_wd) + "u/2u'");
	# the numerator
	box_putf(box, "\\h'-" + nreg(num_wd) + "u/2u'");
	box_putf(box, "\\v'-" + nreg(num_rise) + "u'" + box_toreg(num) + "\\v'" + nreg(num_rise) + "u'");
	box_putf(box, "\\h'-" + nreg(num_wd) + "u/2u'");
	# the denominator
	box_putf(box, "\\h'-" + nreg(den_wd) + "u/2u'");
	box_putf(box, "\\v'" + nreg(den_fall) + "u'" + box_toreg(den) + "\\v'-" + nreg(den_fall) + "u'");
	box_putf(box, "\\h'(-" + nreg(den_wd) + "u+" + nreg(all_wd) + "u)/2u'");
	box_putf(box, "\\h'" + nreg(box.szreg) + SZP() + "*" + string e_nulldelim + "u/100u'");
	box_afterput(box, ftyp);
	box_toreg(box);
	# the struts in its parts, where they are now
	if(num.sht || den.sht){
		sht := nregmk();
		sdp := nregmk();
		tok_dim(box_toreg(num), tmp_15d, sht, 0);
		box_strutdim(num, sht, 0);
		tok_dim(box_toreg(den), tmp_15d, 0, sdp);
		box_strutdim(den, 0, sdp);
		printf(".nr " + nregname(sht) + " +" + nreg(num_rise) + "\n");
		printf(".nr " + nregname(sdp) + " +" + nreg(den_fall) + "\n");
		box_strutput(box, sht, sdp);
		nregrm(sht);
		nregrm(sdp);
	}
	nregrm(num_wd);
	nregrm(num_dp);
	nregrm(den_wd);
	nregrm(den_ht);
	nregrm(all_wd);
	nregrm(num_rise);
	nregrm(den_fall);
	nregrm(bar_wd);
	nregrm(bar_dp);
	nregrm(bar_ht);
	nregrm(bar_fall);
	nregrm(tmp_15d);
}

# the smallest of br[] at least as long as ht and dp
box_bracketsel(dst, ht, dp: int, br: array of string, any, both: int)
{
	i: int;
	if((hts := def_heights(bracketof(br))) != nil){
		box_bracketselht(dst, ht, dp, br, hts, any, both);
		return;
	}
	for(i = 0; i < len br && br[i] != nil; i++){
		s := ".if '" + sreg(dst) + "'' ";
		s += ".if \\w'" + br[i] + "' ";	# is it there?
		if(both){	# both the height and the depth
			s += ".if (" + nreg(ht) + "-(" + string e_rulethickness + "m/100)*2)<=(-\\n[bbury]+\\n[bblly]+(" +
				string e_axisheight + "m/100*2)) ";
			s += ".if (" + nreg(dp) + "*2)<=(-\\n[bbury]+\\n[bblly]-(" + string e_axisheight + "m/100*2)) ";
		}else
			s += ".if (" + nreg(ht) + "+" + nreg(dp) + ")<=(-\\n[bbury]+\\n[bblly]) ";
		s += ".ds " + sregname(dst) + " \"" + br[i] + "\n";
		printf(s);
	}
	if(any)	# the largest, if none is large enough
		while(--i >= 0)
			printf(".if '" + sreg(dst) + "'' .if \\w'" + br[i] + "' .ds " + sregname(dst) + " \"" + br[i] + "\n");
}

# box_bracketsel, its sizes' heights known (bracketheights): each size
# tested by its number, not set by troff to measure it; one request a
# size (.ie ... .el .ie ...)
box_bracketselht(dst, ht, dp: int, br: array of string, hts: array of int, any, both: int)
{
	n := len hts;
	if(n == 0)
		return;
	for(i := 0; i < n; i++){
		h := inkht(hts[i]);
		cond: string;
		if(both)
			cond = "((" + nreg(ht) + "-(" + string e_rulethickness + "m/100)*2)<=(" + h + "+(" +
				string e_axisheight + "m/100*2)))&((" + nreg(dp) + "*2)<=(" + h + "-(" +
				string e_axisheight + "m/100*2)))";
		else
			cond = "(" + nreg(ht) + "+" + nreg(dp) + ")<=" + h;
		pre := ".el .ie ";
		if(i == 0)
			pre = ".ie ";
		if(i == n - 1 && !any)
			pre = ".el .if ";
		if(i == 0 && i == n - 1 && !any)
			pre = ".if ";
		printf(pre + cond + " .ds " + sregname(dst) + " \"" + br[i] + "\n");
	}
	if(any)	# the largest, if none is large enough
		printf(".el .ds " + sregname(dst) + " \"" + br[n - 1] + "\n");
}

# a size's height, as a troff expression
inkht(h: int): string
{
	return "(" + string h + "m/1000u)";
}

# the sign whose sizes br are
bracketof(br: array of string): string
{
	for(i := 0; i < len bracketsizes; i++)
		if(bracketsizes[i][1] == br[0])
			return bracketsizes[i][0];
	return nil;
}

# a bracket built of its pieces
box_bracketmk(dst, ln: int, top, mid, bot, cen: string)
{
	cenlen: array of int;
	mid_cnt := nregmk();
	mid_cur := nregmk();
	cen_pos := nregmk();
	buildmacro := sregmk();
	toplen := blen_mk(top);
	midlen := blen_mk(mid);
	botlen := blen_mk(bot);
	if(cen != nil)
		cenlen = blen_mk(cen);
	# the mid pieces to cover it
	if(cen == nil){
		if(e_delimfactor)	# (enough to reach it: TeX's)
			printf(".nr " + nregname(mid_cnt) + " " + nreg(ln) + "*2-" + nreg(toplen[1]) + "-" + nreg(botlen[1]) +
				"+" + nreg(midlen[1]) + "-1/" + nreg(midlen[1]) + "\n");
		else
			printf(".nr " + nregname(mid_cnt) + " " + nreg(ln) + "*2-" + nreg(toplen[1]) + "-" + nreg(botlen[1]) +
				"*11/10/" + nreg(midlen[1]) + "\n");
		printf(".if " + nreg(mid_cnt) + "<0 .nr " + nregname(mid_cnt) + " 0\n");
	}else{	# a bracket with a centre, as {
		if(e_delimfactor)
			printf(".nr " + nregname(cen_pos) + " " + nreg(ln) + "-(" + nreg(cenlen[1]) + "+" + nreg(toplen[1]) + "+" +
				nreg(botlen[1]) + "/2)+" + nreg(midlen[1]) + "-1/" + nreg(midlen[1]) + "\n");
		else
			printf(".nr " + nregname(cen_pos) + " " + nreg(ln) + "-(" + nreg(cenlen[1]) + "+" + nreg(toplen[1]) + "+" +
				nreg(botlen[1]) + "/2)*11/10/" + nreg(midlen[1]) + "\n");
		printf(".if " + nreg(cen_pos) + "<0 .nr " + nregname(cen_pos) + " 0\n");
		printf(".nr " + nregname(mid_cnt) + " 0" + nreg(cen_pos) + "*2\n");
	}
	# the macro building it; its backslashes escaped
	printf(".de " + sregname(buildmacro) + "\n");
	if(cen != nil)
		printf(".if \\" + nreg(mid_cur) + "=\\" + nreg(cen_pos) + " .as " + sregname(dst) + " \"\\v'-\\" +
			nreg(cenlen[3]) + "u'" + cen + "\\h'-\\" + nreg(cenlen[0]) + "u'\\v'-\\" + nreg(cenlen[2]) + "u'\n");
	printf(".if \\" + nreg(mid_cur) + "<\\" + nreg(mid_cnt) + " .as " + sregname(dst) + " \"\\v'-\\" +
		nreg(midlen[3]) + "u'" + mid + "\\h'-\\" + nreg(midlen[0]) + "u'\\v'-\\" + nreg(midlen[2]) + "u'\n");
	printf(".if \\\\n+" + escarg(nregname(mid_cur)) + "<\\" + nreg(mid_cnt) + " ." + sregname(buildmacro) + "\n");
	printf("..\n");
	# the bracket
	printf(".ds " + sregname(dst) + " \"\\v'-" + nreg(botlen[3]) + "u'" + bot + "\\h'-" + nreg(botlen[0]) +
		"u'\\v'-" + nreg(botlen[2]) + "u'\n");
	printf(".nr " + nregname(mid_cur) + " 0 1\n");
	printf("." + sregname(buildmacro) + "\n");
	printf(".as " + sregname(dst) + " \"\\v'-" + nreg(toplen[3]) + "u'" + top + "\\h'-" + nreg(toplen[0]) +
		"u'\\v'-" + nreg(toplen[2]) + "u'\n");
	# back up
	c := "0";
	if(cen != nil)
		c = nreg(cenlen[1]);
	printf(".as " + sregname(dst) + " \"\\v'" + nreg(mid_cnt) + "u*" + nreg(midlen[1]) + "u+" + nreg(botlen[1]) +
		"u+" + nreg(toplen[1]) + "u+" + c + "u'\n");
	# right
	if(cen != nil)
		c = nreg(cenlen[0]);
	else
		c = nreg(midlen[0]);
	printf(".as " + sregname(dst) + " \"\\h'" + c + "u'\n");
	blen_rm(toplen);
	blen_rm(midlen);
	blen_rm(botlen);
	if(cen != nil)
		blen_rm(cenlen);
	nregrm(mid_cnt);
	nregrm(mid_cur);
	nregrm(cen_pos);
	sregrm(buildmacro);
}

box_bracket(box: ref Box, brac: string, ht, dp: int)
{
	dst := sregmk();
	ln := nregmk();
	fall := nregmk();
	roff_max(ln, ht, dp);
	sizes := def_sizes(brac);
	hts := def_heights(brac);
	printf(".ds " + sregname(dst) + " \"\n");
	(top, mid, bot, cen) := def_pieces(brac);
	if(e_delimfactor){
		# TeX's: the smallest of the sizes that reaches what is needed
		# (by a flag: a size's \\N'...' is no string for .if '...''),
		# else one built to it, else the largest
		need := nregmk();
		t := nregmk();
		fnd := nregmk();
		ax := "(" + string e_axisheight + "m/100u)";
		printf(".nr " + nregname(need) + " 0" + nreg(ht) + "-" + ax + "\n");
		printf(".nr " + nregname(t) + " 0" + nreg(dp) + "+" + ax + "\n");
		printf(".if " + nreg(t) + ">" + nreg(need) + " .nr " + nregname(need) + " 0" + nreg(t) + "\n");
		printf(".nr " + nregname(t) + " 0" + nreg(need) + "*2-(" + string e_delimshort + "m/100u)\n");
		printf(".nr " + nregname(need) + " " + nreg(need) + "*2*" + string e_delimfactor + "/1000\n");
		printf(".if " + nreg(t) + ">" + nreg(need) + " .nr " + nregname(need) + " 0" + nreg(t) + "\n");
		printf(".nr " + nregname(fnd) + " 0\n");
		i := 0;
		if(hts != nil){
			# its sizes' heights known: one request a size
			for(i = 0; i < len hts; i++){
				pre := ".el .ie ";
				if(i == 0)
					pre = ".ie ";
				printf(pre + nreg(need) + "<=" + inkht(hts[i]) + " .ds " + sregname(dst) + " \"" + sizes[i] + "\n");
			}
			printf(".el .nr " + nregname(fnd) + " 1\n");
			# fnd is 1 if none was found: the other way round
			printf(".nr " + nregname(fnd) + " 1-" + nreg(fnd) + "\n");
		}
		for(; hts == nil && i < len sizes && sizes[i] != nil; i++){
			printf(".if !" + nreg(fnd) + " .if \\w'" + sizes[i] + "' .if " + nreg(need) + "<=(-\\n[bbury]+\\n[bblly]) .ds " +
				sregname(dst) + " \"" + sizes[i] + "\n");
			printf(".if !" + nreg(fnd) + " .if \\w'" + sizes[i] + "' .if " + nreg(need) + "<=(-\\n[bbury]+\\n[bblly]) .nr " +
				nregname(fnd) + " 1\n");
		}
		if(mid != nil){
			printf(".nr " + nregname(ln) + " 0" + nreg(need) + "/2\n");
			printf(".if !" + nreg(fnd) + " \\{\\\n");
			box_bracketmk(dst, ln, top, mid, bot, cen);
			printf(".nr " + nregname(fnd) + " 1\n");
			printf(".  \\}\n");
		}
		if(hts != nil && i > 0)	# the largest
			printf(".if !" + nreg(fnd) + " .ds " + sregname(dst) + " \"" + sizes[i - 1] + "\n");
		else while(--i >= 0){
			printf(".if !" + nreg(fnd) + " .if \\w'" + sizes[i] + "' .ds " + sregname(dst) + " \"" + sizes[i] + "\n");
			printf(".if !" + nreg(fnd) + " .if \\w'" + sizes[i] + "' .nr " + nregname(fnd) + " 1\n");
		}
		nregrm(need);
		nregrm(t);
		nregrm(fnd);
	}else{
		box_bracketsel(dst, ht, dp, sizes, mid == nil, 1);
		if(mid != nil){
			printf(".if '" + sreg(dst) + "'' \\{\\\n");
			box_bracketmk(dst, ln, top, mid, bot, cen);
			printf(".  \\}\n");
		}
	}
	# its length
	parlen := blen_mk(sreg(dst));
	# how far down it goes
	printf(".nr " + nregname(fall) + " 0-" + nreg(parlen[3]) + "+" + nreg(parlen[2]) + "/2-(" + nreg(box.szreg) + SZP() +
		"*" + string e_axisheight + "u/100u)\n");
	box_putf(box, "\\f[\\n(.f]\\s[" + CURSZ() + SZU() + "]\\v'" + nreg(fall) + "u'" + sreg(dst) + "\\v'-" + nreg(fall) + "u'");
	box_toreg(box);
	blen_rm(parlen);
	sregrm(dst);
	nregrm(ln);
	nregrm(fall);
}

bracsign(brac: string, left: int): string
{
	if(len brac > 0 && brac[0] == 'c' && len brac <= len "ceiling" && "ceiling"[0:len brac] == brac){
		if(left)
			return "\\(lc";
		return "\\(rc";
	}
	if(len brac > 0 && brac[0] == 'f' && len brac <= len "floor" && "floor"[0:len brac] == brac){
		if(left)
			return "\\(lf";
		return "\\(rf";
	}
	if(brac == "<")
		return "\\(la";
	if(brac == ">")
		return "\\(ra";
	return brac;
}

# large brackets; the font set up before
box_wrap(box, sub: ref Box, left, right: string)
{
	# TeX's \\left ... \\right: one inner atom, spaced as one
	if(e_texatoms){
		inner := box_alloc(box.szreg, 0, box.style);
		box_wrap1(inner, sub, left, right);
		box_beforeput(box, T_INNER, 0);
		box_toreg(box);
		box_put(box, box_toreg(inner));
		if(!box.tbeg)
			box.tbeg = T_INNER;
		box_afterput(box, T_INNER);
		box_free(inner);
		return;
	}
	box_wrap1(box, sub, left, right);
}

box_wrap1(box, sub: ref Box, left, right: string)
{
	sublen := blen_mk(box_toreg(sub));
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	if(left != nil){
		box_beforeput(box, T_LEFT, 0);
		box_bracket(box, bracsign(left, 1), sublen[2], sublen[3]);
		box_afterput(box, T_LEFT);
	}
	box_merge(box, sub, 0);
	if(right != nil){
		box_beforeput(box, T_RIGHT, 0);
		box_bracket(box, bracsign(right, 0), sublen[2], sublen[3]);
		box_afterput(box, T_RIGHT);
	}
	blen_rm(sublen);
}

# a radical at least ln long and wd wide, in dst
sqrt_rad(dst, ln, wd: int)
{
	sr_sz := nregmk();
	wd_diff := nregmk();	# if wd is narrower than \(rn
	sr_rx := nregmk();	# \(sr's right edge
	rn_dx := nregmk();	# \(rn's displacement
	len2 := nregmk();
	rad := sregmk();
	if(e_radgap)	# the font's: as large as it needs
		printf(".nr " + nregname(len2) + " 0" + nreg(ln) + "/2\n");
	else
		printf(".nr " + nregname(len2) + " 0" + nreg(ln) + "/2*11/10\n");
	printf(".ds " + sregname(rad) + " \"\n");
	# a radical of the size
	(top, mid, bot, nil) := def_pieces("\\(sr");
	sizes := def_sizes("\\(sr");
	box_bracketsel(rad, len2, len2, sizes, 0, 0);
	# built if need be
	if(mid != nil){
		printf(".if \\w'" + mid + "' ");
		printf(".if '" + sreg(rad) + "'' \\{\\\n");
		box_bracketmk(rad, len2, top, mid, bot, nil);
		printf(".  \\}\n");
	}
	# \(sr enlarged if none was found
	printf(".if '" + sreg(rad) + "'' \\{\\\n");
	srlen := blen_mk("\\(sr");
	printf(".ie " + nreg(ln) + "<(" + nreg(srlen[2]) + "+" + nreg(srlen[3]) + ") .nr " + nregname(sr_sz) + " 0" + CURSZ() + "\n");
	printf(".el .nr " + nregname(sr_sz) + " 0" + nreg(ln) + "*" + CURSZ() + "/(" + nreg(srlen[2]) + "+" + nreg(srlen[3]) +
		"-(" + string e_rulethickness + "m/100u))+1\n");
	printf(".ps " + nreg(sr_sz) + SZU() + "\n");
	printf(".ds " + sregname(rad) + " \"\\(sr\n");
	blen_rm(srlen);
	printf(".  \\}\n");
	# its handle
	srlen = blen_mk(sreg(rad));
	printf(".nr " + nregname(sr_rx) + " \\n[bburx]\n");
	rnlen := blen_mk("\\(rn");
	printf(".nr " + nregname(rn_dx) + " 0" + nreg(sr_rx) + "-\\n[bbllx]-(" + string e_rulethickness + "m/100u)\n");
	printf(".nr " + nregname(wd_diff) + " 0\n");
	printf(".if " + nreg(wd) + "<" + nreg(rnlen[0]) + " .nr " + nregname(wd_diff) + " 0" + nreg(rnlen[0]) + "-" + nreg(wd) + "\n");
	# the radical; its top at the baseline
	printf(".ds " + nregname(dst) + " \"\\s[" + CURSZ() + SZU() + "]\\f[\\n(.f]" +
		"\\v'" + nreg(rnlen[2]) + "u'\\h'" + nreg(rn_dx) + "u'\\l'" + nreg(wd) + "u+" + nreg(wd_diff) + "u\\(rn'\\h'-" +
		nreg(rn_dx) + "u'\\v'-" + nreg(rnlen[2]) + "u'" +
		"\\h'-" + nreg(wd) + "u-" + nreg(wd_diff) + "u'\\v'" + nreg(srlen[2]) + "u'" + sreg(rad) + "\\v'-" +
		nreg(srlen[2]) + "u'\\h'" + nreg(wd) + "u+" + nreg(wd_diff) + "u'\n");
	blen_rm(srlen);
	blen_rm(rnlen);
	nregrm(sr_sz);
	nregrm(wd_diff);
	nregrm(sr_rx);
	nregrm(rn_dx);
	sregrm(rad);
}

box_sqrt(box, sub: ref Box)
{
	box_root(box, nil, sub);
}

# a radical, its degree deg if not nil: raised by part of the sign's
# height, kerned into it (the font's, as TeX's \\sqrt[n])
box_root(box, deg, sub: ref Box)
{
	rad := sregmk();
	rad_rise := nregmk();
	min_ht := nregmk();
	box_italiccorrection(sub);
	box_beforeput(box, T_ORD, 0);
	sublen := blen_mk(box_toreg(sub));
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	xh := e_rulethickness;
	if(TS_DX(box.style))
		xh = e_xheight;
	if(e_radgap){
		# the font's gap and rule
		gap := e_radgap;
		if(TS_DX(box.style))
			gap = e_radgapd;
		rule := e_radrule;
		if(!rule)
			rule = e_rulethickness;
		printf(".nr " + nregname(min_ht) + " 0" + nreg(sublen[2]) + "+" + nreg(sublen[3]) + "+" + m100(gap + rule) + "\n");
		sqrt_rad(rad, min_ht, sublen[0]);
	}else{
		# 11
		printf(".nr " + nregname(min_ht) + " 0" + nreg(sublen[2]) + "+" + nreg(sublen[3]) + "+(2*" +
			string e_rulethickness + "m/100u)+(" + string xh + "m/100u/4)\n");
		sqrt_rad(rad, min_ht, sublen[0]);
	}
	radlen := blen_mk(sreg(rad));
	if(e_radgap){
		gap := e_radgap;
		if(TS_DX(box.style))
			gap = e_radgapd;
		rule := e_radrule;
		if(!rule)
			rule = e_rulethickness;
		printf(".nr " + nregname(rad_rise) + " 0" + m100(gap + rule) + "\n");
	}else
		printf(".nr " + nregname(rad_rise) + " 0(" + string e_rulethickness + "m/100u)+(" + string xh + "m/100u/4)\n");
	printf(".if " + nreg(radlen[3]) + ">(" + nreg(sublen[2]) + "+" + nreg(sublen[3]) + "+" + nreg(rad_rise) +
		") .nr " + nregname(rad_rise) + " (" + nreg(rad_rise) + "+" + nreg(radlen[3]) + "-" + nreg(sublen[2]) +
		"-" + nreg(sublen[3]) + ")/2\n");
	printf(".nr " + nregname(rad_rise) + " +" + nreg(sublen[2]) + "\n");
	# the degree: its bottom raised by part of the sign's height, kerned
	# before and after (overlapping the sign); no further left than
	# where it begins
	if(deg != nil){
		deglen := blen_mk(box_toreg(deg));
		dk := nregmk();
		printf(".nr " + nregname(dk) + " " + m100(e_raddegkb) + "+" + nreg(deglen[0]) + "+" + m100(e_raddegka) + "\n");
		draise := nregmk();
		printf(".nr " + nregname(draise) + " 0-" + nreg(rad_rise) + "+" + nreg(radlen[3]) + "-(" + nreg(radlen[3]) +
			"*" + string e_raddegraise + "/100)-" + nreg(deglen[3]) + "\n");
		box_putf(box, "\\h'" + m100(e_raddegkb) + "'\\v'" + nreg(draise) + "u'" + box_toreg(deg) +
			"\\v'-" + nreg(draise) + "u'\\h'" + m100(e_raddegka) + "'");
		# (the degree narrower than the kerns take back: no further left)
		box_putf(box, "\\h'(0-" + nreg(dk) + "u)*(" + nreg(dk) + "u<0u)'");
		blen_rm(deglen);
		nregrm(dk);
		nregrm(draise);
	}
	# the radical
	box_putf(box, "\\v'-" + nreg(rad_rise) + "u'" + sreg(rad) + "\\v'" + nreg(rad_rise) + "u'\\h'-" +
		nreg(sublen[0]) + "u'" + box_toreg(sub));
	box_afterput(box, T_ORD);
	box_toreg(box);
	blen_rm(sublen);
	blen_rm(radlen);
	sregrm(rad);
	nregrm(rad_rise);
	nregrm(min_ht);
}

box_bar(box: ref Box)
{
	box_wd := nregmk();
	box_ht := nregmk();
	bar_wd := nregmk();
	bar_dp := nregmk();
	bar_rise := nregmk();
	box_italiccorrection(box);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_len("\\(ru", bar_wd, 0, 0, bar_dp);
	tok_dim(box_toreg(box), box_wd, box_ht, 0);
	printf(".if " + nreg(box_ht) + "u<(" + string e_xheight + "m/100u) .nr " + nregname(box_ht) + " 0" +
		string e_xheight + "m/100u\n");
	printf(".nr " + nregname(bar_rise) + " 0" + nreg(box_ht) + "u+" + nreg(bar_dp) + "u+(3*" +
		string e_rulethickness + "m/100u)\n");
	box_putf(box, "\\v'-" + nreg(bar_rise) + "u'\\s" + escarg(nreg(box.szreg) + SZU()) + "\\f[\\n(.f]\\l'-" +
		nreg(box_wd) + "u\\(ru'\\v'" + nreg(bar_rise) + "u'");
	nregrm(box_wd);
	nregrm(box_ht);
	nregrm(bar_wd);
	nregrm(bar_dp);
	nregrm(bar_rise);
}

box_accent(box: ref Box, c: string)
{
	box_wd := nregmk();
	box_ht := nregmk();
	ac_rise := nregmk();
	ac_wd := nregmk();
	ac_dp := nregmk();
	box_italiccorrection(box);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_len(c, ac_wd, 0, 0, ac_dp);
	tok_dim(box_toreg(box), box_wd, box_ht, 0);
	printf(".if " + nreg(box_ht) + "u<(" + string e_xheight + "m/100u) .nr " + nregname(box_ht) + " 0" +
		string e_xheight + "m/100u\n");
	printf(".nr " + nregname(ac_rise) + " 0" + nreg(box_ht) + "u+" + nreg(ac_dp) + "u+(" + nreg(box.szreg) + SZP() +
		"*10u/100u)\n");
	box_putf(box, "\\v'-" + nreg(ac_rise) + "u'\\h'-" + nreg(box_wd) + "u-" + nreg(ac_wd) + "u/2u'\\s" +
		escarg(nreg(box.szreg)) + "\\f[\\n(.f]" + c + "\\h'" + nreg(box_wd) + "u-" + nreg(ac_wd) + "u/2u'\\v'" +
		nreg(ac_rise) + "u'");
	nregrm(box_wd);
	nregrm(box_ht);
	nregrm(ac_rise);
	nregrm(ac_wd);
	nregrm(ac_dp);
}

box_under(box: ref Box)
{
	box_wd := nregmk();
	box_dp := nregmk();
	bar_wd := nregmk();
	bar_ht := nregmk();
	bar_fall := nregmk();
	box_italiccorrection(box);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_len("\\(ul", bar_wd, 0, bar_ht, 0);
	tok_dim(box_toreg(box), box_wd, 0, box_dp);
	printf(".if " + nreg(box_dp) + "<0 .nr " + nregname(box_dp) + " 0\n");
	printf(".nr " + nregname(bar_fall) + " 0" + nreg(box_dp) + "u+" + nreg(bar_ht) + "u+(3*" +
		string e_rulethickness + "m/100u)\n");
	box_putf(box, "\\v'" + nreg(bar_fall) + "u'\\s" + escarg(nreg(box.szreg) + SZU()) + "\\f[\\n(.f]\\l'-" +
		nreg(box_wd) + "u\\(ul'\\v'-" + nreg(bar_fall) + "u'");
	nregrm(box_wd);
	nregrm(box_dp);
	nregrm(bar_wd);
	nregrm(bar_ht);
	nregrm(bar_fall);
}

box_toreg(box: ref Box): string
{
	if(!box.reg){
		box.reg = sregmk();
		printf(".ds " + sregname(box.reg) + " \"" + cstr(box_buf(box)) + "\n");
	}
	return sreg(box.reg);
}

box_empty(box: ref Box): int
{
	return cstr(box.raw) == "";
}

box_vcenter(box, sub: ref Box)
{
	wd := nregmk();
	ht := nregmk();
	dp := nregmk();
	fall := nregmk();
	box_beforeput(box, sub.tbeg, 0);
	tok_dim(box_toreg(sub), wd, ht, dp);
	printf(".nr " + nregname(fall) + " 0-" + nreg(dp) + "+" + nreg(ht) + "/2-(" + nreg(box.szreg) + SZP() + "*" +
		string e_axisheight + "u/100u)\n");
	box_putf(box, "\\v'" + nreg(fall) + "u'" + box_toreg(sub) + "\\v'-" + nreg(fall) + "u'");
	box_toreg(box);
	box_afterput(box, sub.tcur);
	nregrm(wd);
	nregrm(ht);
	nregrm(dp);
	nregrm(fall);
}

# the line's spacing made room for it
box_vertspace(box: ref Box)
{
	box_wd := nregmk();
	htroom := nregmk();
	dproom := nregmk();
	box_italiccorrection(box);
	# the room before and after the line
	printf(".nr " + nregname(htroom) + " 0+\\n(.vu-" + nreg(box.szreg) + SZP() + "+(" + nreg(box.szreg) + SZP() + "*" +
		string e_bodyheight + "u/100u)\n");
	printf(".nr " + nregname(dproom) + " 0+\\n(.vu-" + nreg(box.szreg) + SZP() + "+(" + nreg(box.szreg) + SZP() + "*" +
		string e_bodydepth + "u/100u)\n");
	# \x requests
	tok_dim(box_toreg(box), box_wd, 0, 0);
	printf(".if -\\n[bbury]>" + nreg(htroom) + " .as " + sregname(box.reg) + " \"\\x'\\n[bbury]u+" + nreg(htroom) + "u'\n");
	printf(".if \\n[bblly]>" + nreg(dproom) + " .as " + sregname(box.reg) + " \"\\x'\\n[bblly]u-" + nreg(dproom) + "u'\n");
	nregrm(box_wd);
	nregrm(htroom);
	nregrm(dproom);
}

box_markpos(box: ref Box, reg: string)
{
	box.tomark = reg;
}

# a pile's or a matrix column's lengths
box_colinit(pile: array of ref Box, n: int, plen: array of array of int, wd, ht: int)
{
	for(i := 0; i < n; i++)
		if(pile[i] != nil)
			box_italiccorrection(pile[i]);
	for(i = 0; i < n; i++){
		s := "";
		if(pile[i] != nil)
			s = box_toreg(pile[i]);
		plen[i] = blen_mk(s);
	}
	printf(".nr " + nregname(wd) + " 0" + nreg(plen[0][0]) + "\n");
	printf(".nr " + nregname(ht) + " 0" + nreg(plen[0][2]) + "\n");
	# the widest
	for(i = 1; i < n; i++)
		printf(".if " + nreg(plen[i][0]) + ">" + nreg(wd) + " .nr " + nregname(wd) + " 0+" + nreg(plen[i][0]) + "\n");
	# the tallest
	for(i = 1; i < n; i++)
		printf(".if " + nreg(plen[i - 1][3]) + "+" + nreg(plen[i][2]) + ">" + nreg(ht) + " .nr " + nregname(ht) +
			" 0+" + nreg(plen[i - 1][3]) + "+" + nreg(plen[i][2]) + "\n");
	# and the last row's depth
	printf(".if " + nreg(plen[n - 1][3]) + ">" + nreg(ht) + " .nr " + nregname(ht) + " 0+" + nreg(plen[n - 1][3]) + "\n");
}

box_colput(pile: array of ref Box, n: int, box: ref Box, adj: int, plen: array of array of int, wd, ht: int)
{
	box_putf(box, "\\v'-" + string (n - 1) + "u*" + nreg(ht) + "u/2u'");
	for(i := 0; i < n; i++){
		if(adj == 'c')
			box_putf(box, "\\h'" + nreg(wd) + "u-" + nreg(plen[i][0]) + "u/2u'");
		if(adj == 'r')
			box_putf(box, "\\h'" + nreg(wd) + "u-" + nreg(plen[i][0]) + "u'");
		v := "0";
		if(i)
			v = nreg(ht);
		s := "";
		if(pile[i] != nil)
			s = box_toreg(pile[i]);
		box_putf(box, "\\v'" + v + "u'" + s);
		if(adj == 'l')
			box_putf(box, "\\h'-" + nreg(plen[i][0]) + "u'");
		if(adj == 'c')
			box_putf(box, "\\h'-" + nreg(wd) + "u+(" + nreg(wd) + "u-" + nreg(plen[i][0]) + "u/2u)'");
		if(adj == 'r')
			box_putf(box, "\\h'-" + nreg(wd) + "u'");
	}
	box_putf(box, "\\v'-" + string (n - 1) + "u*" + nreg(ht) + "u/2u'\\h'" + nreg(wd) + "u'");
}

box_coldone(n: int, plen: array of array of int)
{
	for(i := 0; i < n; i++)
		blen_rm(plen[i]);
}

box_colnrows(cols: array of ref Box): int
{
	n := 0;
	while(n < NPILES && cols[n] != nil)
		n++;
	return n;
}

box_pile(box: ref Box, pile: array of ref Box, adj, rowspace: int)
{
	plen := array[NPILES] of array of int;
	max_wd := nregmk();
	max_ht := nregmk();
	n := box_colnrows(pile);
	box_beforeput(box, T_INNER, 0);
	box_colinit(pile, n, plen, max_wd, max_ht);
	# space between rows
	printf(".if " + nreg(max_ht) + "<(" + nreg(box.szreg) + SZP() + "*" + string e_baselinesep + "u/100u) .nr " +
		nregname(max_ht) + " (" + nreg(box.szreg) + SZP() + "*" + string e_baselinesep + "u/100u)\n");
	if(rowspace)
		printf(".nr " + nregname(max_ht) + " +(" + nreg(box.szreg) + SZP() + "*" + string rowspace + "u/100u)\n");
	box_colput(pile, n, box, adj, plen, max_wd, max_ht);
	box_coldone(n, plen);
	box_afterput(box, T_INNER);
	box_toreg(box);
	nregrm(max_wd);
	nregrm(max_ht);
}

box_matrix(box: ref Box, ncols: int, cols: array of array of ref Box, adj: array of int, colspace, rowspace: int)
{
	if(e_texarrays){
		box_array(box, ncols, cols, adj, colspace, rowspace);
		return;
	}
	plen := array[NPILES] of array of array of int;
	wd := array[NPILES] of int;
	ht := array[NPILES] of int;
	max_ht := nregmk();
	max_wd := nregmk();
	nrows := 0;
	box_beforeput(box, T_INNER, 0);
	for(i := 0; i < ncols; i++)
		if(box_colnrows(cols[i]) > nrows)
			nrows = box_colnrows(cols[i]);
	for(i = 0; i < ncols; i++)
		wd[i] = nregmk();
	for(i = 0; i < ncols; i++)
		ht[i] = nregmk();
	# the columns
	for(i = 0; i < ncols; i++){
		plen[i] = array[NPILES] of array of int;
		box_colinit(cols[i], nrows, plen[i], wd[i], ht[i]);
	}
	# the widest and tallest
	printf(".nr " + nregname(max_wd) + " 0" + nreg(wd[0]) + "\n");
	printf(".nr " + nregname(max_ht) + " 0" + nreg(ht[0]) + "\n");
	for(i = 1; i < ncols; i++)
		printf(".if " + nreg(wd[i]) + ">" + nreg(max_wd) + " .nr " + nregname(max_wd) + " 0+" + nreg(wd[i]) + "\n");
	for(i = 1; i < ncols; i++)
		printf(".if " + nreg(ht[i]) + ">" + nreg(max_ht) + " .nr " + nregname(max_ht) + " 0+" + nreg(ht[i]) + "\n");
	# space between rows
	printf(".if " + nreg(max_ht) + "<(" + nreg(box.szreg) + SZP() + "*" + string e_baselinesep + "u/100u) .nr " +
		nregname(max_ht) + " (" + nreg(box.szreg) + SZP() + "*" + string e_baselinesep + "u/100u)\n");
	if(rowspace)
		printf(".nr " + nregname(max_ht) + " +(" + nreg(box.szreg) + SZP() + "*" + string rowspace + "u/100u)\n");
	# the columns, put
	for(i = 0; i < ncols; i++){
		if(i)	# space between them
			box_putf(box, "\\h'" + nreg(box.szreg) + SZP() + "*" + string (e_columnsep + colspace) + "u/100u'");
		box_colput(cols[i], nrows, box, adj[i], plen[i], max_wd, max_ht);
	}
	box_afterput(box, T_INNER);
	box_toreg(box);
	for(i = 0; i < ncols; i++)
		box_coldone(nrows, plen[i]);
	for(i = 0; i < ncols; i++)
		nregrm(ht[i]);
	for(i = 0; i < ncols; i++)
		nregrm(wd[i]);
	nregrm(max_wd);
	nregrm(max_ht);
}

# a matrix as TeX sets an array: each column as wide as its widest
# cell, each row as high and deep as its highest and deepest (a
# strut's, .7 and .3 of the baseline, at least; the baseline 1.2 ems,
# stretched as the text's lines are, the register .eqnbs's thousandths),
# the rows one under the other by their depths and heights, the whole
# centred on the axis
box_array(box: ref Box, ncols: int, cols: array of array of ref Box, adj: array of int, colspace, rowspace: int)
{
	plen := array[NPILES] of array of array of int;
	wd := array[NPILES] of int;
	nrows := 0;
	box_beforeput(box, T_INNER, 0);
	for(i := 0; i < ncols; i++)
		if(box_colnrows(cols[i]) > nrows)
			nrows = box_colnrows(cols[i]);
	if(nrows == 0)
		return;
	for(i = 0; i < ncols; i++){
		wd[i] = nregmk();
		for(j := 0; j < nrows; j++)
			if(cols[i][j] != nil)
				box_italiccorrection(cols[i][j]);
		plen[i] = array[NPILES] of array of int;
		for(j = 0; j < nrows; j++){
			s := "";
			if(cols[i][j] != nil)
				s = box_toreg(cols[i][j]);
			plen[i][j] = blen_mk(s);
		}
		printf(".nr " + nregname(wd[i]) + " 0" + nreg(plen[i][0][0]) + "\n");
		for(j = 1; j < nrows; j++)
			printf(".if " + nreg(plen[i][j][0]) + ">" + nreg(wd[i]) + " .nr " + nregname(wd[i]) + " 0+" + nreg(plen[i][j][0]) + "\n");
	}
	# the strut: its height and depth
	bs := nregmk();
	sh := nregmk();
	sd := nregmk();
	printf(".nr " + nregname(bs) + " " + nreg(box.szreg) + SZP() + "*12u/10u\n");
	printf(".if \\n[.eqnbs] .nr " + nregname(bs) + " " + nreg(bs) + "*\\n[.eqnbs]/1000\n");
	printf(".nr " + nregname(sh) + " " + nreg(bs) + "*7/10\n");
	printf(".nr " + nregname(sd) + " " + nreg(bs) + "*3/10\n");
	# each row's height, depth and baseline
	ht := array[nrows] of int;
	dp := array[nrows] of int;
	y := array[nrows] of int;
	for(j := 0; j < nrows; j++){
		ht[j] = nregmk();
		dp[j] = nregmk();
		y[j] = nregmk();
		printf(".nr " + nregname(ht[j]) + " 0+" + nreg(sh) + "\n");
		printf(".nr " + nregname(dp[j]) + " 0+" + nreg(sd) + "\n");
		for(i = 0; i < ncols; i++){
			printf(".if " + nreg(plen[i][j][2]) + ">" + nreg(ht[j]) + " .nr " + nregname(ht[j]) + " 0+" + nreg(plen[i][j][2]) + "\n");
			printf(".if " + nreg(plen[i][j][3]) + ">" + nreg(dp[j]) + " .nr " + nregname(dp[j]) + " 0+" + nreg(plen[i][j][3]) + "\n");
		}
		if(j == 0)
			printf(".nr " + nregname(y[j]) + " 0\n");
		else
			printf(".nr " + nregname(y[j]) + " 0+" + nreg(y[j - 1]) + "+" + nreg(dp[j - 1]) + "+" + nreg(ht[j]) +
				"+(" + nreg(box.szreg) + SZP() + "*" + string rowspace + "u/100u)\n");
	}
	# centred on the axis: the shift from the first row's baseline
	sft := nregmk();
	printf(".nr " + nregname(sft) + " 0-(" + nreg(box.szreg) + SZP() + "*" + string e_axisheight + "u/100u)-((" +
		nreg(y[nrows - 1]) + "+" + nreg(dp[nrows - 1]) + "-" + nreg(ht[0]) + ")/2)\n");
	for(i = 0; i < ncols; i++){
		if(i)	# space between them
			box_putf(box, "\\h'" + nreg(box.szreg) + SZP() + "*" + string (e_columnsep + colspace) + "u/100u'");
		for(j = 0; j < nrows; j++){
			if(cols[i][j] == nil)
				continue;
			pre := "";
			post := "\\h'-" + nreg(plen[i][j][0]) + "u'";
			if(adj[i] == 'c'){
				pre = "\\h'" + nreg(wd[i]) + "u-" + nreg(plen[i][j][0]) + "u/2u'";
				post = "\\h'-" + nreg(wd[i]) + "u+(" + nreg(wd[i]) + "u-" + nreg(plen[i][j][0]) + "u/2u)'";
			}
			if(adj[i] == 'r'){
				pre = "\\h'" + nreg(wd[i]) + "u-" + nreg(plen[i][j][0]) + "u'";
				post = "\\h'-" + nreg(wd[i]) + "u'";
			}
			v := nreg(y[j]) + "u+" + nreg(sft) + "u";
			box_putf(box, pre + "\\v'" + v + "'" + box_toreg(cols[i][j]) + "\\v'-(" + v + ")'" + post);
		}
		box_putf(box, "\\h'" + nreg(wd[i]) + "u'");
	}
	box_afterput(box, T_INNER);
	box_toreg(box);
	for(i = 0; i < ncols; i++){
		for(j = 0; j < nrows; j++)
			blen_rm(plen[i][j]);
		nregrm(wd[i]);
	}
	for(j = 0; j < nrows; j++){
		nregrm(ht[j]);
		nregrm(dp[j]);
		nregrm(y[j]);
	}
	nregrm(bs);
	nregrm(sh);
	nregrm(sd);
	nregrm(sft);
}

# a brace over (or under) what is under (or over) it, as TeX's
# \overbrace and \underbrace: the font's smallest wide enough, else one
# made of its pieces (an OpenType math font's horizontal variants and
# assembly of U+23DE and U+23DF: bracesizes and bracepieces, else
# Libertinus Math's); a gap between them (StretchStackGapBelowMin,
# above it); the whole a big operator, its label a limit (to over it,
# from under it)
BRACEWD := array[] of {621, 1001, 1501, 1771, 2181, 2601};
BRACEPC := array[] of {431, 432, 893, 431, 144};	# lt, ex, md, rt, overlap

box_brace(box, sub: ref Box, over: int)
{
	g := "uni23DE";
	if(!over)
		g = "uni23DF";
	# the sizes and pieces
	b := def_brace(over);
	if(b.sizes == nil){
		for(i := len BRACEWD - 1; i >= 0; i--){
			v := g;
			if(i)
				v += ".size" + string i;
			b.sizes = (v, BRACEWD[i]) :: b.sizes;
		}
		(b.lt, b.ex, b.md, b.rt) = (g + ".lt", g + ".ex", g + ".md", g + ".rt");
		(b.ltw, b.exw, b.mdw, b.rtw, b.ov) = (BRACEPC[0], BRACEPC[1], BRACEPC[2], BRACEPC[3], BRACEPC[4]);
	}
	br := sregmk();
	ex := nregmk();
	rise := nregmk();
	allwd := nregmk();
	box_italiccorrection(sub);
	box_beforeput(box, T_BIGOP, 0);
	sublen := blen_mk(box_toreg(sub));
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	# the smallest wide enough, by a flag (a string holding \\N'...'
	# cannot be compared with .if '...'')
	fnd := nregmk();
	printf(".nr " + nregname(fnd) + " 0\n");
	for(l := b.sizes; l != nil; l = tl l){
		(v, w) := hd l;
		printf(".if !" + nreg(fnd) + " .if " + nreg(sublen[0]) + "<=(" + string w + "m/1000u) .ds " +
			sregname(br) + " \"\\N'" + v + "'\n");
		printf(".if !" + nreg(fnd) + " .if " + nreg(sublen[0]) + "<=(" + string w + "m/1000u) .nr " +
			nregname(fnd) + " 1\n");
	}
	# the pieces: each extender half of what the ends and middle leave
	(lt, exw, md, rt, ov) := (b.ltw, b.exw, b.mdw, b.rtw, b.ov);
	printf(".nr " + nregname(ex) + " (" + nreg(sublen[0]) + "-(" + string (lt + md + rt - 4 * ov) + "m/1000u))/2\n");
	printf(".if " + nreg(ex) + "<(" + string exw + "m/1000u) .nr " + nregname(ex) + " " + string exw + "m/1000u\n");
	# (\\N for a glyph by name, which troff looks for in the special
	# fonts; \\l takes a character, so the extender is made one)
	o := "\\h'-" + string ov + "m/1000u'";
	exc := "eqn" + g + "ex";
	printf(".char \\[" + exc + "] \\N'" + b.ex + "'\n");
	# (\\l leaves what is not a whole extender as space at its start:
	# one put there first, under it)
	exs := "\\N'" + b.ex + "'\\h'-" + string exw + "m/1000u'\\l'" + nreg(ex) + "u\\[" + exc + "]'";
	printf(".if !" + nreg(fnd) + " .ds " + sregname(br) + " \"\\N'" + b.lt + "'" + o + exs + o +
		"\\N'" + b.md + "'" + o + exs + o + "\\N'" + b.rt + "'\n");
	brlen := blen_mk(sreg(br));
	roff_max(allwd, sublen[0], brlen[0]);
	# how far it is moved: its ink a gap from what it is over or under
	if(over)
		printf(".nr " + nregname(rise) + " 0" + nreg(sublen[2]) + "+(" + string e_stretchgap + "m/100u)+" + nreg(brlen[3]) + "\n");
	else
		printf(".nr " + nregname(rise) + " 0-" + nreg(sublen[3]) + "-(" + string e_stretchgap + "m/100u)-" + nreg(brlen[2]) + "\n");
	box_putf(box, "\\h'" + nreg(allwd) + "u-" + nreg(sublen[0]) + "u/2u'" + box_toreg(sub) +
		"\\h'-" + nreg(sublen[0]) + "u-(" + nreg(allwd) + "u-" + nreg(sublen[0]) + "u/2u)'");
	box_putf(box, "\\h'" + nreg(allwd) + "u-" + nreg(brlen[0]) + "u/2u'\\v'-" + nreg(rise) + "u'" + sreg(br) +
		"\\v'" + nreg(rise) + "u'\\h'-" + nreg(brlen[0]) + "u-(" + nreg(allwd) + "u-" + nreg(brlen[0]) + "u/2u)'\\h'" + nreg(allwd) + "u'");
	box_afterput(box, T_BIGOP);
	box_toreg(box);
	blen_rm(sublen);
	blen_rm(brlen);
	sregrm(br);
	nregrm(ex);
	nregrm(rise);
	nregrm(allwd);
	nregrm(fnd);
}

# whether a box is one glyph (TeX's character), and the glyph's name if
# it is drawn by name (\N'u1D465'): its sizes, fonts and corrections
# aside, one character
box_glyph(box: ref Box): (int, string)
{
	if(!box_ischar(box))
		return (0, nil);
	s := box.raw;
	n := 0;
	gl: string;
	for(i := 0; i < len s; ){
		if(s[i] != '\\'){
			n++;
			i++;
			continue;
		}
		if(i + 1 >= len s)
			return (0, nil);
		c := s[i + 1];
		case c {
		's' or 'f' =>
			i += 2;
			if(i < len s && s[i] == '['){
				while(i < len s && s[i] != ']')
					i++;
				i++;
			}else if(i < len s && s[i] == '(')
				i += 3;
			else if(c == 's' && i < len s && (s[i] == '+' || s[i] == '-'))
				i += 2;
			else
				i++;
		',' or '/' or '&' =>
			i += 2;
		'N' =>
			e := i + 3;
			while(e < len s && s[e] != '\'')
				e++;
			gl = s[i + 3:e];
			n++;
			i = e + 1;
		'(' =>
			n++;
			i += 4;
		* =>
			return (0, nil);
		}
	}
	if(n != 1)
		return (0, nil);
	return (1, gl);
}

m1000(n: int): string
{
	return "(" + string n + "m/1000u)";
}

# an accent as TeX sets it (e_texaccents): its attachment on the base
# glyph's (the box's middle, if it is not one glyph or has none),
# raised by what the base passes AccentBaseHeight; over more than one
# glyph the widest of its variants not wider than the box
box_texaccent(box: ref Box, vars: array of Accvar, one: int, gl: string)
{
	box_wd := nregmk();
	box_ht := nregmk();
	ac_rise := nregmk();
	ac_x := nregmk();
	ac_pos := nregmk();
	ac_gl := sregmk();
	box_italiccorrection(box);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	tok_dim(box_toreg(box), box_wd, box_ht, 0);
	(ok, pos) := def_accentpos(gl);
	if(one && ok)
		printf(".nr " + nregname(ac_x) + " 0+" + m1000(pos) + "\n");
	else
		printf(".nr " + nregname(ac_x) + " 0" + nreg(box_wd) + "/2\n");
	printf(".ds " + sregname(ac_gl) + " \"\\N'" + vars[0].gl + "'\n");
	printf(".nr " + nregname(ac_pos) + " 0+" + m1000(vars[0].pos) + "\n");
	for(i := 1; !one && i < len vars; i++){
		cond := ".if " + nreg(box_wd) + ">=" + m1000(vars[i].wd) + " ";
		printf(cond + ".ds " + sregname(ac_gl) + " \"\\N'" + vars[i].gl + "'\n");
		printf(cond + ".nr " + nregname(ac_pos) + " 0+" + m1000(vars[i].pos) + "\n");
	}
	printf(".nr " + nregname(ac_rise) + " 0" + nreg(box_ht) + "-" + m100(e_accentbase) + "\n");
	printf(".if " + nreg(ac_rise) + "<0 .nr " + nregname(ac_rise) + " 0\n");
	fnt := gsfont;
	if(fnt == nil)
		fnt = grfont;
	# (\Z's argument does not nest its delimiter)
	box_putf(box, "\\Z|\\v'-" + nreg(ac_rise) + "u'\\h'" + nreg(ac_x) + "u-" + nreg(box_wd) + "u-" +
		nreg(ac_pos) + "u'\\s" + escarg(nreg(box.szreg) + SZU()) + "\\f" + escarg(fnt) + sreg(ac_gl) + "|");
	nregrm(box_wd);
	nregrm(box_ht);
	nregrm(ac_rise);
	nregrm(ac_x);
	nregrm(ac_pos);
	sregrm(ac_gl);
}

# n choose k: TeX's \binom, a stack without a bar (rule 15, 15c) in
# parentheses of TeX's delim1 or delim2, an ordinary atom
box_choose(box, num, den: ref Box)
{
	num_wd := nregmk();
	num_dp := nregmk();
	den_wd := nregmk();
	den_ht := nregmk();
	all_wd := nregmk();
	num_rise := nregmk();
	den_fall := nregmk();
	gap := nregmk();
	br_ht := nregmk();
	br_dp := nregmk();
	box_beforeput(box, T_ORD, 0);
	box_italiccorrection(num);
	box_italiccorrection(den);
	tok_dim(box_toreg(num), num_wd, 0, num_dp);
	tok_dim(box_toreg(den), den_wd, den_ht, 0);
	roff_max(all_wd, num_wd, den_wd);
	printf(".ps " + nreg(box.szreg) + SZU() + "\n");
	# 15b: the shifts; 15c: the least gap
	up := e_stacktop;
	down := e_stackbot;
	clr := e_stackgap;
	delim := e_delim2;
	if(TS_DX(box.style)){
		up = e_stacktopd;
		down = e_stackbotd;
		clr = e_stackgapd;
		delim = e_delim1;
		if(!up)
			up = e_num1;
		if(!down)
			down = e_denom1;
		if(!clr)
			clr = 7 * e_rulethickness;
	}else{
		if(!up)
			up = e_num2;
		if(!down)
			down = e_denom2;
		if(!clr)
			clr = 3 * e_rulethickness;
	}
	printf(".nr " + nregname(num_rise) + " 0+" + m100(up) + "\n");
	printf(".nr " + nregname(den_fall) + " 0+" + m100(down) + "\n");
	printf(".nr " + nregname(gap) + " (" + nreg(num_rise) + "-" + nreg(num_dp) + ")-(" + nreg(den_ht) + "-" +
		nreg(den_fall) + ")\n");
	printf(".if " + nreg(gap) + "<" + m100(clr) + " .nr " + nregname(num_rise) + " +(" + m100(clr) + "-" +
		nreg(gap) + ")/2\n");
	printf(".if " + nreg(gap) + "<" + m100(clr) + " .nr " + nregname(den_fall) + " +(" + m100(clr) + "-" +
		nreg(gap) + ")/2\n");
	# the parentheses: TeX's delim1 or delim2 about the axis (what
	# box_bracket's delimiter factor asks of that), else the stack's
	if(e_delimfactor){
		ax := "(" + string e_axisheight + "m/100u)";
		half := "(" + string delim + "m/100u*500/" + string e_delimfactor + ")";
		printf(".nr " + nregname(br_ht) + " 0+" + ax + "+" + half + "\n");
		printf(".nr " + nregname(br_dp) + " 0+" + half + "-" + ax + "\n");
	}else{
		tok_dim(box_toreg(num), gap, br_ht, 0);
		tok_dim(box_toreg(den), gap, 0, br_dp);
		printf(".nr " + nregname(br_ht) + " +" + nreg(num_rise) + "\n");
		printf(".nr " + nregname(br_dp) + " +" + nreg(den_fall) + "\n");
	}
	printf(".ft " + grfont + "\n");
	box_bracket(box, "(", br_ht, br_dp);
	# the numerator, the denominator, each centred
	# (troff's expressions are read left to right)
	box_putf(box, "\\h'" + nreg(all_wd) + "u/2u'\\h'-" + nreg(num_wd) + "u/2u'");
	box_putf(box, "\\v'-" + nreg(num_rise) + "u'" + box_toreg(num) + "\\v'" + nreg(num_rise) + "u'");
	box_putf(box, "\\h'-" + nreg(num_wd) + "u/2u'\\h'-" + nreg(den_wd) + "u/2u'");
	box_putf(box, "\\v'" + nreg(den_fall) + "u'" + box_toreg(den) + "\\v'-" + nreg(den_fall) + "u'");
	box_putf(box, "\\h'" + nreg(all_wd) + "u/2u'\\h'-" + nreg(den_wd) + "u/2u'");
	box_bracket(box, ")", br_ht, br_dp);
	box_afterput(box, T_ORD);
	box_toreg(box);
	nregrm(num_wd);
	nregrm(num_dp);
	nregrm(den_wd);
	nregrm(den_ht);
	nregrm(all_wd);
	nregrm(num_rise);
	nregrm(den_fall);
	nregrm(gap);
	nregrm(br_ht);
	nregrm(br_dp);
}
