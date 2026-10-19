#
# vjust.b: a page's text made to end where a full page's does (not
# Neatpost's), as LaTeX's \flushbottom makes it: a page broken short
# (a widow or orphan kept from it, a heading kept with its text, a
# display not fitting) has the space it lacks spread where the macros
# say space may stretch (x X vstretch weight: between paragraphs, about
# headings and displays), as much as each may, in proportion; what they
# cannot take is spread over its lines' gaps, a fraction of a point each.
#
#	x X vstretch w		the space after the line set last may stretch
#				by w (units), with others in proportion
#	x X vfoot b vs		the page's text ends here; a full page's last
#				baseline is b; vs, its line spacing
#	x X vcol		a column begins: what follows is a region of
#				its own, made to end at its own foot (x X
#				vfoot), what came before kept as it was
#
# A page in columns is in regions, one a column, each made to end where
# a full column does; what is set above the columns (a title, a figure
# across them) is a region with no foot, and stays as set.
#
# The text is what was set before x X vfoot: what follows (notes, the
# folio, the running heads) stays where it is set. A page whose text
# would move more than five lines, or with no x X vfoot, stays as set.
# The page's vertical places are written as placeholders (VJ0 the place
# in hundredths of troff's units VJ1) and given at its end, with its
# links' rectangles, destinations and bookmarks.
#

VJ0: con 16r01;
VJ1: con 16r02;

vj_sv: array of int;		# the stretch points: where, and how much
vj_sw: array of int;
vj_sr: array of int;		# and how many rows were set before it
vj_sn := 0;
vj_lv: array of int;		# the lines' baselines
vj_lr: array of int;		# and how many rows were set before the next
vj_ln := 0;
vj_rv: array of int;		# where anything is set: rows, a picture's too, and lines drawn
vj_rn := 0;
vj_first := -1;			# the text's first and last baselines
vj_last := -1;
vj_foot := 0;			# x X vfoot seen: the text ended
vj_target := 0;
vj_vs := 0;
# the plan: each point's share, and below what nothing moves
vj_pv: array of int;
vj_pa: array of int;
vj_pr: array of int;
vj_pn := 0;
vj_cut := -1;
vj_annots: list of (int, string);	# the page's annotations, waiting for their places
# the page's regions (columns, x X vcol): each one's plan, kept when the
# next begins; vj_reg the one being set
vj_reg := 0;
vj_rpv: array of array of int;
vj_rpa: array of array of int;
vj_rpn: array of int;
vj_rcut: array of int;

vj_reset()
{
	if(vj_sv == nil){
		vj_sv = array[64] of int;
		vj_sw = array[64] of int;
		vj_sr = array[64] of int;
		vj_lv = array[256] of int;
		vj_lr = array[256] of int;
		vj_rv = array[256] of int;
	}
	vj_sn = vj_ln = vj_rn = 0;
	vj_first = vj_last = -1;
	vj_foot = 0;
	vj_target = vj_vs = 0;
	vj_pn = 0;
	vj_cut = -1;
	vj_reg = 0;
	vj_rpv = array[4] of array of int;
	vj_rpa = array[4] of array of int;
	vj_rpn = array[4] of int;
	vj_rcut = array[4] of int;
}

# the region set so far planned and kept, a new one begun (x X vcol)
vj_region()
{
	vj_keep();
	vj_reg++;
	vj_sn = vj_ln = vj_rn = 0;
	vj_first = vj_last = -1;
	vj_foot = 0;
	vj_target = vj_vs = 0;
	vj_pn = 0;
	vj_cut = -1;
}

# the region's plan, kept
vj_keep()
{
	vj_plan();
	if(vj_reg >= len vj_rpn){
		n := 2 * len vj_rpn;
		a := array[n] of array of int;
		a[0:] = vj_rpv;
		vj_rpv = a;
		a = array[n] of array of int;
		a[0:] = vj_rpa;
		vj_rpa = a;
		vj_rpn = growint(vj_rpn, n);
		vj_rcut = growint(vj_rcut, n);
	}
	vj_rpv[vj_reg] = vj_pv;
	vj_rpa[vj_reg] = vj_pa;
	vj_rpn[vj_reg] = vj_pn;
	vj_rcut[vj_reg] = vj_cut;
}

# x X vstretch w
vj_stretch(w: int)
{
	if(vj_foot || w <= 0)
		return;
	if(vj_sn == len vj_sv){
		vj_sv = growint(vj_sv, 2 * vj_sn);
		vj_sw = growint(vj_sw, 2 * vj_sn);
		vj_sr = growint(vj_sr, 2 * vj_sn);
	}
	vj_sv[vj_sn] = o_v;
	vj_sr[vj_sn] = vj_rn;
	vj_sw[vj_sn++] = w;
}

# a glyph set: of the text, before x X vfoot; a line begun where it is
# half its size or more below the line before (a script is not a line).
# A picture's, a displayed formula's or a table's rows are not lines:
# it moves whole, its lines drawn still meeting its text.
vj_glyph()
{
	if(vj_foot)
		return;
	if(vj_first < 0 || o_v < vj_first)
		vj_first = o_v;
	if(o_v > vj_last)
		vj_last = o_v;
	vj_row(o_v);
	if(tag_rigid())
		return;
	if(vj_ln > 0 && o_v < vj_lv[vj_ln - 1] + o_s * devres() / (72 * dev_szscale) / 2)
		return;
	if(vj_ln == len vj_lv){
		vj_lv = growint(vj_lv, 2 * vj_ln);
		vj_lr = growint(vj_lr, 2 * vj_ln);
	}
	vj_lv[vj_ln] = o_v;
	vj_lr[vj_ln++] = vj_rn;
}

# something set or drawn at v: a row if half the type's size or more
# below the lowest so far (not a script, nor a rule under a line)
vj_row(v: int)
{
	if(compat || vj_foot)	# (-c: as Neatpost, not justified; nothing kept)
		return;
	if(vj_rn > 0 && v < vj_rv[vj_rn - 1] + o_s * devres() / (72 * dev_szscale) / 2)
		return;
	if(vj_rn == len vj_rv)
		vj_rv = growint(vj_rv, 2 * vj_rn);
	vj_rv[vj_rn++] = v;
}

# x X vfoot b vs
vj_setfoot(b, vs: int)
{
	if(vj_foot)
		return;
	vj_foot = 1;
	vj_target = b;
	vj_vs = vs;
}

# the space the page lacks, shared: the points first, as much as each
# may take; then the lines, a seventh of their spacing each at most
# (none else to take it, as much as is left); what is left still to
# the points, beyond what they would take, in proportion, as TeX gives
# what its glue cannot stretch to to the glue that stretches
vj_plan()
{
	vj_pn = 0;
	vj_cut = -1;
	if(!vj_foot || vj_first < 0 || vj_last <= vj_first || vj_vs <= 0)
		return;
	s := vj_target - vj_last;
	if(s == 0 || s > 5 * vj_vs || -s > vj_vs)
		return;
	n := vj_sn + vj_ln;
	vj_pv = array[n] of int;
	vj_pa = array[n] of int;
	vj_pr = array[n] of int;
	w := 0;
	for(i := 0; i < vj_sn; i++)
		if(vj_sv[i] >= vj_first && vj_sv[i] < vj_last)
			w += vj_sw[i];
	lines := 0;
	for(i = 0; i < vj_ln; i++)
		if(vj_lv[i] >= vj_first && vj_lv[i] < vj_last)
			lines++;
	sign := 1;
	if(s < 0)
		sign = -1;
	share := 0;
	if(w > 0)
		share = sign * min(abs(s), w);
	left := s - share;
	lshare := left;
	if(w > 0 && abs(left) > lines * vj_vs / 7)
		lshare = sign * (lines * vj_vs / 7);
	share += left - lshare;
	if(w > 0)
		vj_points(share, w);
	if(lshare != 0 && lines > 0){
		given := 0;
		k := 0;
		for(i = 0; i < vj_ln; i++)
			if(vj_lv[i] >= vj_first && vj_lv[i] < vj_last){
				k++;
				a := int (big lshare * big k / big lines) - given;
				given += a;
				vj_pv[vj_pn] = vj_lv[i];
				vj_pr[vj_pn] = vj_lr[i];
				vj_pa[vj_pn++] = a;
			}
	}
	# a gap's space goes to what is set past its middle, the next row's
	# (set after it), not to a subscript or a descender of the line above
	# it, nor a table's rule under its last row, nor to half a picture
	# below it
	for(i = 0; i < vj_pn; i++){
		# below all set before it (a table's rule under its last row)
		base := vj_pv[i];
		for(j := 0; j < vj_pr[i] && j < vj_rn; j++)
			if(vj_rv[j] > base)
				base = vj_rv[j];
		next := -1;
		for(j = vj_pr[i]; j < vj_rn; j++)
			if(vj_rv[j] > base && (next < 0 || vj_rv[j] < next))
				next = vj_rv[j];
		if(next > 0)
			vj_pv[i] = (base + next) / 2;
		else
			vj_pv[i] = base;
	}
	# what is set below the text's last line, as far as a script hangs
	# below it, moves with it; nothing further (the notes, the folio)
	vj_cut = vj_last + vj_vs * 8 / 10;
}

# share given the points, as their weights (w in all) divide it
vj_points(share, w: int)
{
	given := 0;
	last := -1;
	for(i := 0; i < vj_sn; i++)
		if(vj_sv[i] >= vj_first && vj_sv[i] < vj_last){
			a := int (big share * big vj_sw[i] / big w);
			vj_pv[vj_pn] = vj_sv[i];
			vj_pr[vj_pn] = vj_sr[i];
			vj_pa[vj_pn] = a;
			last = vj_pn++;
			given += a;
		}
	if(last >= 0)
		vj_pa[last] += share - given;
}

# how far what is set at v in region r moves
vj_off(v, r: int): int
{
	if(r < 0 || r >= len vj_rpn || vj_rcut[r] < 0 || v > vj_rcut[r])
		return 0;
	o := 0;
	pv := vj_rpv[r];
	pa := vj_rpa[r];
	for(i := 0; i < vj_rpn[r]; i++)
		if(v > pv[i])
			o += pa[i];
	return o;
}

# a vertical place, in hundredths of troff's units, as the PDF's: given
# at the page's end; in a drawing, moved as its first point is (a rule
# or a polygon moves whole, not stretched where a point of the page's
# stretching falls between its edges)
vj_anchor := -1;

vj_place(uv: big): string
{
	return vj_char(VJ0) + string uv + ":" + string vj_anchor + ":" + string vj_reg + vj_char(VJ1);
}

vj_char(c: int): string
{
	s := "";
	s[0] = c;
	return s;
}

# a placeholder's fields: the place, the anchor (or -1), the region
vj_fields(p: string): (big, int, int)
{
	f := array[3] of {* => "-1"};
	n := 0;
	b := 0;
	for(k := 0; k <= len p && n < 3; k++)
		if(k == len p || p[k] == ':'){
			f[n++] = p[b:k];
			b = k + 1;
		}
	return (big f[0], int f[1], int f[2]);
}

# s with its places given
vj_resolve(s: string): string
{
	r := "";
	b := 0;
	for(i := 0; i < len s; i++){
		if(s[i] != VJ0)
			continue;
		j := i + 1;
		while(j < len s && s[j] != VJ1)
			j++;
		# uv:anchor:region
		(uv, at, rg) := vj_fields(s[i + 1:j]);
		if(at < 0)
			at = int (uv / big 100);
		uv += big vj_off(at, rg) * big 100;
		v := int (big pdf_height * big 100 - uv * big 72 / big devres());
		r += s[b:i] + dec2(v);
		i = j;
		b = j + 1;
	}
	if(b == 0)
		return s;
	return r + s[b:];
}

# the page ends: its places given, its annotations written, its
# destinations and bookmarks moved with its text
vj_pageend()
{
	vj_keep();
	pg = vj_resolve(pg);
	for(l := vj_annots; l != nil; l = tl l){
		(id, s) := hd l;
		obj_beg(id);
		pdfout(vj_resolve(s));
		obj_end();
	}
	vj_annots = nil;
	# (destinations and bookmarks moved on a page of one region only:
	# in columns, which a place is in is not known)
	if(vj_reg > 0 || vj_cut < 0)
		return;
	for(i := 0; i < name_n; i++)
		if(name_page[i] == o_pages)
			name_offset[i] += vj_off(name_offset[i], 0);
	for(i = 0; i < mark_n; i++)
		if(mark_page[i] == o_pages)
			mark_offset[i] += vj_off(mark_offset[i], 0);
}

# an annotation, written when its places are known
vj_annot(id: int, s: string)
{
	vj_annots = (id, s) :: vj_annots;
}
