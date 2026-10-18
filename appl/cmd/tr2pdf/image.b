#
# image.b: images on the page (x X image file w h), not Neatpost's: a
# JPEG's data as it is (DCTDecode); a PNG's decoded, unfiltered and
# compressed again, its alpha a soft mask (SMask), its palette an
# Indexed colour space.  Each image one object, however many pages show
# it; placed by the page (q w 0 0 h x y cm ... Do Q), its lower left
# corner where troff is, w by h (troff's units; either 0, as the image's
# proportions give it).
#

img_path: list of string;	# the images written: their files
img_obj: list of int;		# their objects
img_w: list of int;		# and size in pixels
img_h: list of int;
img_said: list of string;	# the files already complained of

outimage(path: string, hwid, vwid: int)
{
	(id, pw, ph) := imgobj(path);
	if(id < 0 || pw <= 0 || ph <= 0)
		return;
	if(hwid <= 0 && vwid <= 0){	# at 72 pixels an inch
		hwid = pw * devres() / 72;
		vwid = ph * devres() / 72;
	}else if(hwid <= 0)
		hwid = int (big vwid * big pw / big ph);
	else if(vwid <= 0)
		vwid = int (big hwid * big ph / big pw);
	i := 0;
	for(; i < xobj_n; i++)
		if(xobj[i] == id)
			break;
	if(i == xobj_n){
		if(xobj_n == len xobj)
			return;
		xobj[xobj_n++] = id;
	}
	o_flush();
	out_fontup();
	if(!compat){
		tag_content(1);
		textend();
	}else
		pg += "ET ";
	w := hwid * 7200 / devres();
	h := vwid * 7200 / devres();
	pg += "q " + dec2(w) + " 0 0 " + dec2(h) + " " + pdfpos(o_h, o_v) + " cm /FO" + string i + " Do Q\n";
	if(compat)
		pg += "BT\n";
	p_h = -1;
	p_v = -1;
}

# the image's object and size in pixels, written when first met
imgobj(path: string): (int, int, int)
{
	(pl, ol, wl, hl) := (img_path, img_obj, img_w, img_h);
	for(; pl != nil; (pl, ol, wl, hl) = (tl pl, tl ol, tl wl, tl hl))
		if(hd pl == path)
			return (hd ol, hd wl, hd hl);
	data := readfile(path);
	id, pw, ph: int;
	err: string;
	if(data == nil)
		err = "cannot read it";
	else if(len data > 3 && data[0] == byte 16rFF && data[1] == byte 16rD8)
		(id, pw, ph, err) = jpegobj(data);
	else if(len data > 8 && string data[1:4] == "PNG")
		(id, pw, ph, err) = pngobj(data);
	else
		err = "not a JPEG or PNG";
	if(err != nil){
		for(sl := img_said; sl != nil; sl = tl sl)
			if(hd sl == path)
				return (-1, 0, 0);
		img_said = path :: img_said;
		sys->fprint(sys->fildes(2), "tr2pdf: image %s: %s\n", path, err);
		return (-1, 0, 0);
	}
	img_path = path :: img_path;
	img_obj = id :: img_obj;
	img_w = pw :: img_w;
	img_h = ph :: img_h;
	return (id, pw, ph);
}

be16(d: array of byte, i: int): int
{
	return int d[i] << 8 | int d[i+1];
}

be32(d: array of byte, i: int): int
{
	return int d[i] << 24 | int d[i+1] << 16 | int d[i+2] << 8 | int d[i+3];
}

# a JPEG: its frame's size and components from its SOF marker
jpegobj(d: array of byte): (int, int, int, string)
{
	(w, h, nc, adobe) := (0, 0, 0, 0);
	for(i := 2; i + 4 <= len d; ){
		if(d[i] != byte 16rFF)
			return (-1, 0, 0, "a broken JPEG");
		m := int d[i+1];
		if(m == 16rFF){
			i++;
			continue;
		}
		if(m == 16rD8 || m == 16r01 || m >= 16rD0 && m <= 16rD7){
			i += 2;
			continue;
		}
		n := be16(d, i+2);
		if(m >= 16rC0 && m <= 16rCF && m != 16rC4 && m != 16rC8 && m != 16rCC){
			if(i + 10 > len d)
				return (-1, 0, 0, "a broken JPEG");
			h = be16(d, i+5);
			w = be16(d, i+7);
			nc = int d[i+9];
			break;
		}
		if(m == 16rEE && n >= 7 && string d[i+4:i+9] == "Adobe")
			adobe = 1;
		if(m == 16rDA)
			break;
		i += 2 + n;
	}
	if(w <= 0 || h <= 0)
		return (-1, 0, 0, "no frame in the JPEG");
	cs := "/DeviceRGB";
	dec := "";
	case nc {
	1 =>	cs = "/DeviceGray";
	3 =>	cs = "/DeviceRGB";
	4 =>
		cs = "/DeviceCMYK";
		if(adobe)	# Adobe's CMYK JPEGs are stored inverted
			dec = "  /Decode [1 0 1 0 1 0 1 0]\n";
	* =>	return (-1, 0, 0, sys->sprint("a JPEG of %d components", nc));
	}
	id := obj_beg(0);
	pdfout(sys->sprint("<<\n  /Type /XObject\n  /Subtype /Image\n  /Width %d\n  /Height %d\n" +
		"  /ColorSpace %s\n  /BitsPerComponent 8\n%s  /Filter /DCTDecode\n  /Length %d\n>>\nstream\n",
		w, h, cs, dec, len d));
	pdfmem(d);
	pdfout("\nendstream\n");
	obj_end();
	return (id, w, h, nil);
}

# a PNG: its rows decoded and unfiltered, its colour and alpha apart
pngobj(d: array of byte): (int, int, int, string)
{
	(w, h, depth, ct, il) := (0, 0, 0, 0, 0);
	plte: array of byte;
	trns: array of byte;
	z := array[len d] of byte;
	zn := 0;
	for(i := 8; i + 8 <= len d; ){
		n := be32(d, i);
		t := string d[i+4:i+8];
		if(n < 0 || i + 12 + n > len d)
			return (-1, 0, 0, "a broken PNG");
		c := d[i+8:i+8+n];
		case t {
		"IHDR" =>
			(w, h, depth, ct, il) = (be32(c, 0), be32(c, 4), int c[8], int c[9], int c[12]);
		"PLTE" =>
			plte = c;
		"tRNS" =>
			trns = c;
		"IDAT" =>
			z[zn:] = c;
			zn += n;
		"IEND" =>
			break;
		}
		i += 12 + n;
	}
	if(w <= 0 || h <= 0)
		return (-1, 0, 0, "no header in the PNG");
	if(il)
		return (-1, 0, 0, "an interlaced PNG (save it not interlaced)");
	nch := 0;
	case ct {
	0 =>	nch = 1;
	2 =>	nch = 3;
	3 =>	nch = 1;
	4 =>	nch = 2;
	6 =>	nch = 4;
	* =>	return (-1, 0, 0, "a PNG of an unknown colour type");
	}
	raw := unzip(z[0:zn]);
	if(raw == nil)
		return (-1, 0, 0, "a PNG its data cannot be read from");
	bpp := (nch * depth + 7) / 8;
	row := (w * nch * depth + 7) / 8;
	if(len raw < h * (row + 1))
		return (-1, 0, 0, "a PNG with too few rows");
	pix := array[h * row] of byte;
	prev := array[row] of {* => byte 0};
	for(y := 0; y < h; y++){
		f := int raw[y * (row + 1)];
		cur := raw[y * (row + 1) + 1:(y + 1) * (row + 1)];
		for(x := 0; x < row; x++){
			a := 0;
			if(x >= bpp)
				a = int cur[x - bpp];
			b := int prev[x];
			c := 0;
			if(x >= bpp)
				c = int prev[x - bpp];
			v := int cur[x];
			case f {
			1 =>	v += a;
			2 =>	v += b;
			3 =>	v += (a + b) / 2;
			4 =>	v += paeth(a, b, c);
			}
			cur[x] = byte v;
		}
		pix[y * row:] = cur;
		prev = cur;
	}
	# alpha apart from colour
	smask := 0;
	if(ct == 4 || ct == 6){
		bs := depth / 8;
		cn := nch - 1;
		col := array[w * h * cn * bs] of byte;
		alp := array[w * h * bs] of byte;
		(ci, ai, pi) := (0, 0, 0);
		for(k := 0; k < w * h; k++){
			col[ci:] = pix[pi:pi + cn * bs];
			ci += cn * bs;
			pi += cn * bs;
			alp[ai:] = pix[pi:pi + bs];
			ai += bs;
			pi += bs;
		}
		pix = col;
		smask = writestream(sys->sprint("  /Type /XObject\n  /Subtype /Image\n  /Width %d\n  /Height %d\n" +
			"  /ColorSpace /DeviceGray\n  /BitsPerComponent %d\n", w, h, depth), alp);
	}
	cs := "/DeviceRGB";
	extra := "";
	case ct {
	0 or 4 =>	cs = "/DeviceGray";
	3 =>
		if(plte == nil)
			return (-1, 0, 0, "a PNG with no palette");
		cs = sys->sprint("[/Indexed /DeviceRGB %d <", len plte / 3 - 1);
		for(k := 0; k < len plte; k++)
			cs += sys->sprint("%02X", int plte[k]);
		cs += ">]";
		if(trns != nil && depth == 8){	# each index's alpha, a mask
			alp := array[w * h] of byte;
			for(k = 0; k < w * h; k++){
				ix := int pix[k];
				if(ix < len trns)
					alp[k] = trns[ix];
				else
					alp[k] = byte 255;
			}
			smask = writestream(sys->sprint("  /Type /XObject\n  /Subtype /Image\n  /Width %d\n  /Height %d\n" +
				"  /ColorSpace /DeviceGray\n  /BitsPerComponent 8\n", w, h), alp);
		}
	}
	if(smask)
		extra = sys->sprint("  /SMask %d 0 R\n", smask);
	else if(trns != nil && ct == 0 && len trns >= 2)
		extra = sys->sprint("  /Mask [%d %d]\n", be16(trns, 0), be16(trns, 0));
	else if(trns != nil && ct == 2 && len trns >= 6)
		extra = sys->sprint("  /Mask [%d %d %d %d %d %d]\n", be16(trns, 0), be16(trns, 0),
			be16(trns, 2), be16(trns, 2), be16(trns, 4), be16(trns, 4));
	id := writestream(sys->sprint("  /Type /XObject\n  /Subtype /Image\n  /Width %d\n  /Height %d\n" +
		"  /ColorSpace %s\n  /BitsPerComponent %d\n%s", w, h, cs, depth, extra), pix);
	return (id, w, h, nil);
}

paeth(a, b, c: int): int
{
	p := a + b - c;
	(pa, pb, pc) := (abs(p - a), abs(p - b), abs(p - c));
	if(pa <= pb && pa <= pc)
		return a;
	if(pb <= pc)
		return b;
	return c;
}

# zlib's data inflated; nil if it cannot be
unzip(data: array of byte): array of byte
{
	inflate := load Filter Filter->INFLATEPATH;
	if(inflate == nil)
		return nil;
	inflate->init();
	rq := inflate->start("z");
	out := array[4 * len data + 1024] of byte;
	n := 0;
	i := 0;
	for(;;){
	pick m := <-rq {
	Start =>
		;
	Fill =>
		k := len data - i;
		if(k > len m.buf)
			k = len m.buf;
		m.buf[0:] = data[i:i + k];
		i += k;
		m.reply <-= k;
	Result =>
		if(n + len m.buf > len out){
			no := array[2 * (n + len m.buf)] of byte;
			no[0:] = out[0:n];
			out = no;
		}
		out[n:] = m.buf;
		n += len m.buf;
		m.reply <-= 0;
	Finished =>
		return out[0:n];
	Info =>
		;
	Error =>
		return nil;
	}
	}
}
