#
# pdfext.c: a PDF's first page included as an XObject (x X pdf)
#

# a byte of the PDF, NUL past its end as in Neatpost's buffer
at(p: array of byte, i: int): int
{
	if(i >= 0 && i < len p)
		return int p[i];
	return 0;
}

pdf_ws(p: array of byte, pos: int): int
{
	i := pos;
	while(i < len p && isspace(int p[i]))
		i++;
	return i - pos;
}

isnumc(c: int): int
{
	return c != 0 && strchr("0123456789+-.", c) >= 0;
}

# s: string, d: dictionary, l: list, n: number, /: name, r: reference
pdf_type(p: array of byte, pos: int): int
{
	pos += pdf_ws(p, pos);
	c := at(p, pos);
	if(c == '/')
		return '/';
	if(c == '(')
		return 's';
	if(c == '<' && at(p, pos + 1) != '<')
		return 's';
	if(c == '<' && at(p, pos + 1) == '<')
		return 'd';
	if(c == '[')
		return 'l';
	if(isnumc(c)){
		if(!isdigit(c))
			return 'n';
		while(pos < len p && isdigit(int p[pos]))
			pos++;
		pos += pdf_ws(p, pos);
		if(!isdigit(at(p, pos)))
			return 'n';
		while(pos < len p && isdigit(int p[pos]))
			pos++;
		pos += pdf_ws(p, pos);
		if(pos < len p && p[pos] == byte 'R')
			return 'r';
		return 'n';
	}
	return -1;
}

# the length of an object
pdf_len(p: array of byte, pos: int): int
{
	old := pos;
	if(pos >= len p)
		return 0;
	pos += pdf_ws(p, pos);
	c := at(p, pos);
	if(isnumc(c)){
		if(pdf_type(p, pos) == 'r'){
			for(r := pos; r < len p; r++)
				if(p[r] == byte 'R')
					return r - old + 1;
		}
		pos++;
		while(pos < len p && strchr("0123456789.", int p[pos]) >= 0)
			pos++;
	}
	if(c == '('){
		depth := 1;
		pos++;
		while(pos < len p && depth > 0){
			if(p[pos] == byte '(')
				depth++;
			if(p[pos] == byte ')')
				depth--;
			if(p[pos] == byte '\\')
				pos++;
			pos++;
		}
	}
	if(c == '<' && pos + 1 < len p && p[pos + 1] == byte '<'){
		pos += 2;
		while(pos + 2 < len p && (p[pos] != byte '>' || p[pos + 1] != byte '>')){
			pos += pdf_len(p, pos);
			pos += pdf_len(p, pos);
			pos += pdf_ws(p, pos);
		}
		if(pos + 2 < len p)
			pos += 2;
	}else if(c == '<'){
		while(pos < len p && p[pos] != byte '>')
			pos++;
		if(pos < len p)
			pos++;
	}
	if(c == '/'){
		pos++;
		while(pos < len p && strchr(" \t\r\n\f()<>[]{}/%", int p[pos]) < 0 && p[pos] != byte 0)
			pos++;
	}
	if(c == '['){
		pos++;
		while(pos < len p && p[pos] != byte ']'){
			pos += pdf_len(p, pos);
			pos += pdf_ws(p, pos);
		}
		pos++;
	}
	# a keyword (true, false, null), which Neatpost takes as nothing
	# and loops on for ever
	start := old + pdf_ws(p, old);
	if(pos == start)
		while(pos < len p && !isspace(int p[pos]) && strchr("()<>[]{}/%", int p[pos]) < 0)
			pos++;
	if(pos == start && pos < len p)
		pos++;
	return pos - old;
}

startswith(p: array of byte, pos: int, t: string): int
{
	for(i := 0; i < len t; i++)
		if(at(p, pos + i) != t[i])
			return at(p, pos + i) == 0;
	return 1;
}

# C's atoi of the bytes at pos
patoi(p: array of byte, pos: int): int
{
	e := pos;
	while(e < len p && e - pos < 32 && (isspace(int p[e]) || isdigit(int p[e]) || p[e] == byte '-' || p[e] == byte '+'))
		e++;
	return atoi(string p[pos:e]);
}

# an indirect reference: its object and revision
pdf_obj(p: array of byte, pos: int): (int, int, int)
{
	if(pdf_type(p, pos) != 'r')
		return (-1, 0, 0);
	# the revision is the second number (Neatpost reads the number
	# after the R, the next reference's in [3 0 R 4 0 R])
	pos += pdf_ws(p, pos);
	obj := patoi(p, pos);
	while(pos < len p && isdigit(int p[pos]))
		pos++;
	return (0, obj, patoi(p, pos));
}

# where a dictionary key's value is
pdf_dval(p: array of byte, pos: int, key: string): int
{
	pos += 2;
	while(pos + 2 < len p && (p[pos] != byte '>' || p[pos + 1] != byte '>')){
		pos += pdf_ws(p, pos);
		if(pdf_len(p, pos) == len key && startswith(p, pos, key)){
			pos += pdf_len(p, pos);
			pos += pdf_ws(p, pos);
			return pos;
		}
		pos += pdf_len(p, pos);
		pos += pdf_len(p, pos);
		pos += pdf_ws(p, pos);
	}
	return -1;
}

# where a dictionary's key-th key is
pdf_dkey(p: array of byte, pos: int, key: int): int
{
	i := 0;
	pos += 2;
	while(pos + 2 < len p && (p[pos] != byte '>' || p[pos + 1] != byte '>')){
		pos += pdf_ws(p, pos);
		if(i++ == key)
			return pos;
		pos += pdf_len(p, pos);
		pos += pdf_len(p, pos);
		pos += pdf_ws(p, pos);
	}
	return -1;
}

# where a list's idx-th entry is
pdf_lval(p: array of byte, pos: int, idx: int): int
{
	i := 0;
	pos++;
	while(pos < len p && p[pos] != byte ']'){
		if(i++ == idx)
			return pos;
		pos += pdf_len(p, pos);
		pos += pdf_ws(p, pos);
	}
	return -1;
}

memrchr(p: array of byte, c: int, n: int): int
{
	for(i := n - 1; i >= 0; i--)
		if(int p[i] == c)
			return i;
	return -1;
}

prevline(p: array of byte, off: int): int
{
	nl := memrchr(p, '\n', off);
	if(nl > 0){
		nl2 := memrchr(p, '\n', nl - 1);
		if(nl2 >= 0)
			return nl2 + 1;
	}
	return -1;
}

nextline(p: array of byte, off: int): int
{
	for(i := off; i < len p; i++)
		if(p[i] == byte '\n')
			return i + 1;
	return -1;
}

pdf_trailer(p: array of byte): int
{
	pos := prevline(p, len p);	# %%EOF
	while(pos < 0 || !startswith(p, pos, "trailer"))
		if(pos < 0 || (pos = prevline(p, pos)) < 0)
			return -1;
	return nextline(p, pos);
}

pdf_xref(p: array of byte): int
{
	pos := prevline(p, len p);
	if(pos < 0 || (pos = prevline(p, pos)) < 0)
		return -1;
	v := scanints(string p[pos:min(pos + 32, len p)], 1);
	if(len v != 1 || v[0] >= len p || v[0] < 0)
		return -1;
	return nextline(p, v[0]);
}

min(a, b: int): int
{
	if(a < b)
		return a;
	return b;
}

# where an object's value is
pdf_find(p: array of byte, obj, rev: int): int
{
	if(xtrailer >= 0){
		if(obj < 0 || obj >= len xkind)
			return -1;
		case xkind[obj] {
		1 =>
			if(xb[obj] != rev)
				return -1;
			return objval(p, xa[obj]);
		2 =>
			return xa[obj];
		}
		return -1;
	}
	pos := pdf_xref(p);
	if(pos < 0)
		return -1;
	for(;;){
		if(pos >= len p)
			return -1;
		v := scanints(string p[pos:min(pos + 64, len p)], 2);
		if(len v != 2)
			return -1;
		(obj_beg, obj_cnt) := (v[0], v[1]);
		for(i := 0; i < obj_cnt; i++){
			if((pos = nextline(p, pos)) < 0)
				return -1;
			e := scanints(string p[pos:min(pos + 64, len p)], 2);
			if(len e != 2)
				return -1;
			(cur_pos, cur_rev) := (e[0], e[1]);
			if(obj_beg + i == obj && cur_rev == rev){
				if(cur_pos < 0 || cur_pos >= len p)
					return -1;
				# strstr: to the first NUL
				for(k := cur_pos; k + 3 <= len p && p[k] != byte 0; k++)
					if(p[k] == byte 'o' && p[k + 1] == byte 'b' && p[k + 2] == byte 'j'){
						pos = k + 3;
						return pos + pdf_ws(p, pos);
					}
				return -1;
			}
		}
		# the next subsection (Neatpost reads this one's last entry
		# as one, for ever)
		if((pos = nextline(p, pos)) < 0)
			return -1;
	}
}

# where the value of the object at off is, after its "obj"
objval(p: array of byte, off: int): int
{
	if(off < 0 || off >= len p)
		return -1;
	for(k := off; k + 3 <= len p && k < off + 64; k++)
		if(p[k] == byte 'o' && p[k + 1] == byte 'b' && p[k + 2] == byte 'j'){
			k += 3;
			return k + pdf_ws(p, k);
		}
	return -1;
}

# the cross-reference, read whole: PDF 1.5's cross-reference streams
# and object streams (pdfTeX's, LuaTeX's, Ghostscript's), the sections of
# an updated file; Neatpost reads only a table, the last
xkind: array of int;	# by object: 1 at an offset, 2 in an object stream
xa: array of int;	# the offset (or, in a stream, where it is in p)
xb: array of int;	# the revision (or the object stream, its index)
xtrailer := -1;		# the trailer's dictionary

xset(obj, kind, a, b: int)
{
	if(obj < 0 || obj > 1000000)
		return;
	if(obj >= len xkind){
		n := 2 * obj + 64;
		k := array[n] of {* => 0};
		na := array[n] of int;
		nb := array[n] of int;
		k[0:] = xkind;
		na[0:] = xa;
		nb[0:] = xb;
		(xkind, xa, xb) = (k, na, nb);
	}
	if(xkind[obj] == 0)	# the newest section's is first
		(xkind[obj], xa[obj], xb[obj]) = (kind, a, b);
}

# the PDF with the objects of its object streams after it, each where
# pdf_find finds it; the cross-reference read
pdfprep(p: array of byte): array of byte
{
	(xkind, xa, xb, xtrailer) = (nil, nil, nil, -1);
	pos := prevline(p, len p);
	if(pos < 0 || (pos = prevline(p, pos)) < 0)
		return p;
	v := scanints(string p[pos:min(pos + 32, len p)], 1);
	if(len v != 1)
		return p;
	off := v[0];
	for(n := 0; n < 64 && off > 0 && off < len p; n++){
		q := off + pdf_ws(p, off);
		dict := -1;
		if(startswith(p, q, "xref")){
			dict = xreftable(p, nextline(p, q));
			if(dict >= 0 && (v1 := pdf_dval(p, dict, "/XRefStm")) >= 0)
				xrefstream(p, objval(p, patoi(p, v1)));
		}else if(!xrefstream(p, dict = objval(p, q)))
			dict = -1;
		if(dict < 0)
			break;
		if(xtrailer < 0)
			xtrailer = dict;
		if((v1 := pdf_dval(p, dict, "/Prev")) < 0)
			break;
		off = patoi(p, v1);
	}
	if(xtrailer < 0)
		return p;
	# the objects in object streams, appended
	sb := ref Bytes(array[len p + 4096] of byte, 0);
	sb.mem(p);
	stms: list of (int, array of byte, array of int);
	for(obj := 0; obj < len xkind; obj++){
		if(xkind[obj] != 2)
			continue;
		stm := xa[obj];
		data: array of byte;
		offs: array of int;
		for(l := stms; l != nil; l = tl l)
			if((hd l).t0 == stm)
				(nil, data, offs) = hd l;
		if(data == nil){
			if(stm < len xkind && xkind[stm] == 1 && (d := objval(p, xa[stm])) >= 0 &&
			    pdf_type(p, d) == 'd' && (data = pdf_stream(p, d)) != nil){
				first := 0;
				cnt := 0;
				if((v1 := pdf_dval(p, d, "/First")) >= 0)
					first = patoi(p, v1);
				if((v1 = pdf_dval(p, d, "/N")) >= 0)
					cnt = patoi(p, v1);
				if(first > len data)
					first = len data;
				offs = scanints(string data[0:first], 2 * cnt);
				for(i := 1; i < len offs; i += 2)
					offs[i] += first;
			}else
				data = array[0] of byte;
			stms = (stm, data, offs) :: stms;
		}
		# by its index, or (as some writers number them) its number
		idx := xb[obj];
		if(2 * idx >= len offs || offs[2 * idx] != obj)
			for(idx = 0; 2 * idx < len offs && offs[2 * idx] != obj; idx++)
				;
		if(2 * idx + 1 >= len offs){
			xkind[obj] = 0;
			continue;
		}
		beg := offs[2 * idx + 1];
		end := len data;
		if(2 * idx + 3 < len offs)
			end = offs[2 * idx + 3];
		if(beg < 0 || beg > end || end > len data){
			xkind[obj] = 0;
			continue;
		}
		sb.str("\n");
		xa[obj] = sb.n;
		sb.mem(data[beg:end]);
	}
	sb.str("\n");
	return sb.b[0:sb.n];
}

# a cross-reference table's entries; where its trailer's dictionary is
xreftable(p: array of byte, pos: int): int
{
	while(pos >= 0 && pos < len p){
		pos += pdf_ws(p, pos);
		if(startswith(p, pos, "trailer")){
			pos += len "trailer";
			pos += pdf_ws(p, pos);
			if(pdf_type(p, pos) != 'd')
				return -1;
			return pos;
		}
		v := scanints(string p[pos:min(pos + 64, len p)], 2);
		if(len v != 2)
			return -1;
		for(i := 0; i < v[1]; i++){
			if((pos = nextline(p, pos)) < 0)
				return -1;
			# an entry is twenty bytes, some writers' lines shorter
			if(pos < len p && isspace(int p[pos]))
				pos += pdf_ws(p, pos);
			e := scanints(string p[pos:min(pos + 20, len p)], 2);
			if(len e != 2)
				return -1;
			k := pos;
			while(k < len p && k < pos + 20 && p[k] != byte 'n' && p[k] != byte 'f')
				k++;
			if(at(p, k) == 'n')
				xset(v[0] + i, 1, e[0], e[1]);
			else
				xset(v[0] + i, -1, 0, 0);
		}
		pos = nextline(p, pos);
	}
	return -1;
}

# a cross-reference stream's entries; 0 if dict is not one
xrefstream(p: array of byte, dict: int): int
{
	if(dict < 0 || pdf_type(p, dict) != 'd')
		return 0;
	if((t := pdf_dval(p, dict, "/Type")) < 0 || pdf_copy(p, t) != "/XRef")
		return 0;
	wv := pdf_dval(p, dict, "/W");
	if(wv < 0)
		return 0;
	w := array[3] of int;
	for(i := 0; i < 3; i++){
		if((e := pdf_lval(p, wv, i)) < 0)
			return 0;
		w[i] = patoi(p, e);
		if(w[i] < 0 || w[i] > 8)
			return 0;
	}
	ent := w[0] + w[1] + w[2];
	if(ent <= 0)
		return 0;
	data := pdf_stream(p, dict);
	if(data == nil)
		return 0;
	size := 0;
	if((v := pdf_dval(p, dict, "/Size")) >= 0)
		size = patoi(p, v);
	idx := array[] of {0, size};
	if((v = pdf_dval(p, dict, "/Index")) >= 0){
		n := 0;
		while(pdf_lval(p, v, n) >= 0)
			n++;
		idx = array[n] of int;
		for(i = 0; i < n; i++)
			idx[i] = patoi(p, pdf_lval(p, v, i));
	}
	pos := 0;
	for(s := 0; s + 1 < len idx; s += 2)
		for(i = 0; i < idx[s + 1] && pos + ent <= len data; i++){
			f := array[3] of int;
			for(j := 0; j < 3; j++){
				f[j] = 0;
				for(k := 0; k < w[j]; k++)
					f[j] = (f[j] << 8) | int data[pos++];
			}
			if(w[0] == 0)
				f[0] = 1;
			case f[0] {
			0 =>
				xset(idx[s] + i, -1, 0, 0);
			1 =>
				xset(idx[s] + i, 1, f[1], f[2]);
			2 =>
				xset(idx[s] + i, 2, f[1], f[2]);
			}
		}
	return 1;
}

# a stream's data, decoded (Flate, its PNG predictors); nil if it cannot be
pdf_stream(p: array of byte, dict: int): array of byte
{
	val := pdf_dval_val(p, dict, "/Length");
	if(val < 0)
		return nil;
	slen := patoi(p, val);
	pos := dict + pdf_len(p, dict);
	pos += pdf_ws(p, pos);
	if(!startswith(p, pos, "stream"))
		return nil;
	pos += len "stream";
	if(at(p, pos) == '\r')
		pos++;
	if(at(p, pos) == '\n')
		pos++;
	if(slen < 0 || pos + slen > len p)
		return nil;
	data := p[pos:pos + slen];
	f := pdf_dval_val(p, dict, "/Filter");
	parms := pdf_dval_val(p, dict, "/DecodeParms");
	if(f >= 0 && pdf_type(p, f) == 'l'){
		if(pdf_lval(p, f, 1) >= 0)
			return nil;
		f = pdf_lval(p, f, 0);
		if(parms >= 0 && pdf_type(p, parms) == 'l')
			parms = pdf_lval(p, parms, 0);
	}
	if(f < 0)
		return data;
	if(pdf_copy(p, f) != "/FlateDecode" || (data = unzip(data)) == nil)
		return nil;
	if(parms < 0 || pdf_type(p, parms) != 'd')
		return data;
	pred := 1;
	cols := 1;
	if((v := pdf_dval(p, parms, "/Predictor")) >= 0)
		pred = patoi(p, v);
	if((v = pdf_dval(p, parms, "/Columns")) >= 0)
		cols = patoi(p, v);
	if(pred < 10)
		return data;	# (TIFF's, 2, not in a cross-reference)
	ncomp := 1;
	if((v = pdf_dval(p, parms, "/Colors")) >= 0)
		ncomp = patoi(p, v);
	bpc := 8;
	if((v = pdf_dval(p, parms, "/BitsPerComponent")) >= 0)
		bpc = patoi(p, v);
	return unpng(data, (cols * ncomp * bpc + 7) / 8, (ncomp * bpc + 7) / 8);
}

# rows of n bytes, each after its PNG filter's byte, unfiltered
unpng(d: array of byte, n, bpp: int): array of byte
{
	if(n <= 0)
		return nil;
	rows := len d / (n + 1);
	out := array[rows * n] of {* => byte 0};
	for(r := 0; r < rows; r++){
		ft := int d[r * (n + 1)];
		src := r * (n + 1) + 1;
		o := r * n;
		for(i := 0; i < n; i++){
			x := int d[src + i];
			a := 0;
			if(i >= bpp)
				a = int out[o + i - bpp];
			b := 0;
			if(r > 0)
				b = int out[o - n + i];
			c := 0;
			if(r > 0 && i >= bpp)
				c = int out[o - n + i - bpp];
			case ft {
			1 =>	x += a;
			2 =>	x += b;
			3 =>	x += (a + b) / 2;
			4 =>	x += paeth(a, b, c);
			}
			out[o + i] = byte x;
		}
	}
	return out;
}

pdf_ref(p: array of byte, pos: int): int
{
	(e, obj, rev) := pdf_obj(p, pos);
	if(e)
		return -1;
	return pdf_find(p, obj, rev);
}

pdf_dval_val(p: array of byte, pos: int, key: string): int
{
	val := pdf_dval(p, pos, key);
	if(val < 0)
		return -1;
	if(pdf_type(p, val) == 'r'){
		(nil, obj, rev) := pdf_obj(p, val);
		return pdf_find(p, obj, rev);
	}
	return val;
}

pdf_dval_obj(p: array of byte, pos: int, key: string): int
{
	val := pdf_dval(p, pos, key);
	if(val < 0)
		return -1;
	return pdf_ref(p, val);
}

# a copy of an object, at most 4095 bytes
pdf_copy(p: array of byte, pos: int): string
{
	pos += pdf_ws(p, pos);
	n := pdf_len(p, pos);
	if(n > 4095)
		n = 4095;
	return cstring(p[pos:min(pos + n, len p)]);
}

cstring(b: array of byte): string
{
	for(i := 0; i < len b; i++)
		if(b[i] == byte 0)
			return string b[0:i];
	return string b;
}

# a stream, to buf
pdf_strcopy(p: array of byte, pos: int, sb: ref Bytes): int
{
	val := pdf_dval_val(p, pos, "/Length");
	if(val < 0)
		return -1;
	slen := patoi(p, val);
	pos = pos + pdf_len(p, pos);
	pos += pdf_ws(p, pos);
	if(pos + slen + 15 > len p)
		return -1;
	beg := pos;
	pos += len "stream";
	if(at(p, pos) == '\r')
		pos++;
	pos += 1 + slen;
	if(at(p, pos) == '\r' || at(p, pos) == ' ')
		pos++;
	if(at(p, pos) == '\n')
		pos++;
	pos += len "endstream" + 1;
	sb.mem(p[beg:min(pos, len p)]);
	return 0;
}

copied: list of (int, int);	# objects copied: where, and their new identifiers

# an object copied; its new identifier
pdf_objcopy(p: array of byte, pos: int): int
{
	if((pos = pdf_ref(p, pos)) < 0)
		return -1;
	id := 0;
	if(!compat){
		# once each, so that a cycle of references ends
		for(l := copied; l != nil; l = tl l)
			if((hd l).t0 == pos)
				return (hd l).t1;
		id = obj_map();
		copied = (pos, id) :: copied;
	}
	if(pdf_type(p, pos) == 'd'){
		sb := ref Bytes(array[1024] of byte, 0);
		pdf_dictcopy(p, pos, sb);
		sb.str("\n");
		if(pdf_dval(p, pos, "/Length") >= 0)
			pdf_strcopy(p, pos, sb);
		id = obj_beg(id);
		pdfmem(sb.b[0:sb.n]);
		obj_end();
	}else if(!compat){
		sb := ref Bytes(array[1024] of byte, 0);
		pdf_valcopy(p, pos, sb);
		sb.str("\n");
		id = obj_beg(id);
		pdfmem(sb.b[0:sb.n]);
		obj_end();
	}else{
		id = obj_beg(id);
		pdfmem(p[pos:min(pos + pdf_len(p, pos), len p)]);
		pdfout("\n");
		obj_end();
	}
	return id;
}

pdf_dictcopy(p: array of byte, pos: int, sb: ref Bytes)
{
	sb.str("<<");
	for(i := 0; ; i++){
		key := pdf_dkey(p, pos, i);
		if(key < 0)
			break;
		k := pdf_copy(p, key);
		sb.str(" " + k);
		val := pdf_dval(p, pos, k);
		if(!compat){
			sb.str(" ");
			pdf_valcopy(p, val, sb);
		}else if(pdf_type(p, val) == 'r'){
			if((id := pdf_objcopy(p, val)) >= 0)
				sb.str(" " + string id + " 0 R");
		}else
			sb.str(" " + pdf_copy(p, val));
	}
	sb.str(" >>");
}

# a value, the objects it refers to copied, however deep (Neatpost
# copies those of a dictionary's values only, in a figure's resources an
# array's [/ICCBased 7 0 R] or a form's own /Resources left referring
# to objects of the file it came from)
pdf_valcopy(p: array of byte, pos: int, sb: ref Bytes)
{
	case pdf_type(p, pos) {
	'r' =>
		if((id := pdf_objcopy(p, pos)) >= 0)
			sb.str(string id + " 0 R");
		else
			sb.str("null");
	'd' =>
		pdf_dictcopy(p, pos + pdf_ws(p, pos), sb);
	'l' =>
		sb.str("[");
		pos += pdf_ws(p, pos) + 1;
		for(i := 0; ; i++){
			pos += pdf_ws(p, pos);
			if(pos >= len p || p[pos] == byte ']')
				break;
			if(i > 0)
				sb.str(" ");
			pdf_valcopy(p, pos, sb);
			pos += pdf_len(p, pos);
		}
		sb.str("]");
	* =>
		pos += pdf_ws(p, pos);
		sb.mem(p[pos:min(pos + pdf_len(p, pos), len p)]);
	}
}

pdf_rescopy(p: array of byte, pos: int, sb: ref Bytes)
{
	fields := array[] of {"/ProcSet", "/ExtGState", "/ColorSpace",
		"/Pattern", "/Shading", "/Properties", "/Font", "/XObject"};
	sb.str("  /Resources <<\n");
	for(i := 0; i < len fields; i++){
		if((res := pdf_dval_val(p, pos, fields[i])) >= 0){
			if(pdf_type(p, res) == 'd'){
				sb.str("    " + fields[i] + " ");
				pdf_dictcopy(p, res, sb);
				sb.str("\n");
			}else
				sb.str("    " + fields[i] + " " + pdf_copy(p, res) + "\n");
		}
	}
	sb.str("  >>\n");
}

pdfbbox100(p: array of byte, pos: int): (int, array of int)
{
	dim := array[4] of int;
	for(i := 0; i < 4; i++){
		n := 0;
		f1 := 0;
		f2 := 0;
		val := pdf_lval(p, pos, i);
		if(val < 0)
			return (-1, dim);
		val += pdf_ws(p, val);
		sign := 1;
		if(at(p, val) == '-' && !compat){
			sign = -1;
			val++;
		}
		for(; isdigit(at(p, val)); val++)
			n = n * 10 + at(p, val) - '0';
		if(at(p, val) == '.' && isdigit(at(p, val + 1))){
			f1 = at(p, val + 1) - '0';
			if(isdigit(at(p, val + 2)))
				f2 = at(p, val + 2) - '0';
		}
		dim[i] = sign * (n * 100 + f1 * 10 + f2);
	}
	return (0, dim);
}

# the PDF's first page as an XObject; its index in xobj
pdfext(p: array of byte, hwid, vwid: int): int
{
	if(xobj_n == len xobj)
		return -1;
	copied = nil;
	{
		p = pdfprep(p);
		trailer := xtrailer;
		if(trailer < 0)
			trailer = pdf_trailer(p);
		if(trailer < 0)
			return -1;
		root := pdf_dval_obj(p, trailer, "/Root");
		if(root < 0)
			return -1;
		pages := pdf_dval_obj(p, root, "/Pages");
		if(pages < 0)
			return -1;
		kids_val := pdf_dval_val(p, pages, "/Kids");
		if(kids_val < 0)
			return -1;
		page1_val := pdf_lval(p, kids_val, 0);
		if(page1_val < 0)
			return -1;
		page1 := pdf_ref(p, page1_val);
		if(page1 < 0)
			return -1;
		# a tree of pages: its first leaf, its ancestors' attributes
		# inherited
		up := pages :: nil;
		for(n := 0; n < 32 && pdf_dval(p, page1, "/Kids") >= 0; n++){
			up = page1 :: up;
			if((kids_val = pdf_dval_val(p, page1, "/Kids")) < 0 ||
			    (page1_val = pdf_lval(p, kids_val, 0)) < 0 ||
			    (page1 = pdf_ref(p, page1_val)) < 0)
				return -1;
		}
		cont := pdf_dval_obj(p, page1, "/Contents");
		data: array of byte;
		length := 0;
		if(cont < 0 && !compat){
			# its contents in pieces: one stream of them
			if((l := pdf_dval_val(p, page1, "/Contents")) < 0 || pdf_type(p, l) != 'l')
				return -1;
			data = array[0] of byte;
			for(i := 0; (e := pdf_lval(p, l, i)) >= 0; i++){
				if((e = pdf_ref(p, e)) < 0 || (d := pdf_stream(p, e)) == nil)
					return -1;
				nd := array[len data + len d + 1] of byte;
				nd[0:] = data;
				nd[len data:] = d;
				nd[len nd - 1] = byte '\n';
				data = nd;
			}
			data = zip(data);
			length = len data;
		}else{
			if(cont < 0)
				return -1;
			val := pdf_dval_val(p, cont, "/Length");
			if(val < 0)
				return -1;
			length = patoi(p, val);
		}
		res := pdf_dval_val(p, page1, "/Resources");
		# what is shown of it: its crop box (as viewers show it), or
		# its media box
		bbox := -1;
		if(!compat)
			bbox = pdf_dval_val(p, page1, "/CropBox");
		if(bbox < 0)
			bbox = pdf_dval_val(p, page1, "/MediaBox");
		for(l := up; l != nil; l = tl l){
			if(bbox < 0 && !compat)
				bbox = pdf_dval_val(p, hd l, "/CropBox");
			if(bbox < 0)
				bbox = pdf_dval_val(p, hd l, "/MediaBox");
			if(res < 0 && !compat)
				res = pdf_dval_val(p, hd l, "/Resources");
		}
		# its scale, in hundredths (Neatpost's), or ten-thousandths
		zs := 100;
		if(!compat)
			zs = 10000;
		hzoom := zs;
		vzoom := zs;
		x0 := 0;
		y0 := 0;
		if(bbox >= 0){
			(e, dim) := pdfbbox100(p, bbox);
			if(!e && dim[2] > dim[0] && dim[3] > dim[1]){
				if(hwid > 0)
					hzoom = int (big hwid * big (zs * 7200 / devres()) / big (dim[2] - dim[0]));
				if(vwid > 0)
					vzoom = int (big vwid * big (zs * 7200 / devres()) / big (dim[3] - dim[1]));
				if(vwid <= 0)
					vzoom = hzoom;
				if(hwid <= 0)
					hzoom = vzoom;
				(x0, y0) = (dim[0], dim[1]);
			}
		}
		sb := ref Bytes(array[4096] of byte, 0);
		sb.str("<<\n  /Type /XObject\n  /Subtype /Form\n  /FormType 1\n");
		if(bbox >= 0)
			sb.str("  /BBox " + pdf_copy(p, bbox) + "\n");
		# placed by the page (outpdf), where its place is given at the
		# page's end; Neatpost's, here
		at := "0 0";
		if(compat)
			at = pdfpos(o_h, o_v);
		else if(x0 != 0 || y0 != 0)	# the box's corner at the place
			at = hundredths(int (big -x0 * big hzoom / big zs)) + " " +
				hundredths(int (big -y0 * big vzoom / big zs));
		if(compat)
			sb.str(sys->sprint("  /Matrix [%d.%02d 0 0 %d.%02d %s]\n",
				hzoom / 100, hzoom % 100, vzoom / 100, vzoom % 100, at));
		else
			sb.str(sys->sprint("  /Matrix [%d.%04d 0 0 %d.%04d %s]\n",
				hzoom / zs, hzoom % zs, vzoom / zs, vzoom % zs, at));
		if(res >= 0)
			pdf_rescopy(p, res, sb);
		sb.str("  /Length " + string length + "\n");
		if(data != nil){
			sb.str("  /Filter /FlateDecode\n>>\nstream\n");
			sb.mem(data);
			sb.str("\nendstream\n");
		}else{
			cf := array[] of {"/Filter", "/DecodeParms"};
			for(i := 0; i < len cf; i++)
				if((val := pdf_dval_val(p, cont, cf[i])) >= 0)
					sb.str("  " + cf[i] + " " + pdf_copy(p, val) + "\n");
			sb.str(">>\n");
			pdf_strcopy(p, cont, sb);
		}
		xobj_id := obj_beg(0);
		pdfmem(sb.b[0:sb.n]);
		obj_end();
		xobj[xobj_n++] = xobj_id;
		return xobj_n - 1;
	} exception {
	"array bounds error" =>
		return -1;
	}
}

# n hundredths, as a PDF number
hundredths(n: int): string
{
	s := "";
	if(n < 0){
		s = "-";
		n = -n;
	}
	return sys->sprint("%s%d.%02d", s, n / 100, n % 100);
}

# a growing buffer of bytes
Bytes: adt {
	b:	array of byte;
	n:	int;

	mem:	fn(s: self ref Bytes, b: array of byte);
	str:	fn(s: self ref Bytes, t: string);
};

Bytes.mem(s: self ref Bytes, b: array of byte)
{
	if(s.n + len b > len s.b){
		nb := array[2 * (s.n + len b)] of byte;
		nb[0:] = s.b[0:s.n];
		s.b = nb;
	}
	s.b[s.n:] = b;
	s.n += len b;
}

Bytes.str(s: self ref Bytes, t: string)
{
	s.mem(array of byte t);
}
