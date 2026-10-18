#
# src.c: the input
#

NARGS: con 10;		# a macro's arguments
NMACROS: con 512;
NSRCDEP: con 512;	# the deepest the streams go

# a stream of input
Esrc: adt {
	prev:	cyclic ref Esrc;	# the stream before; nil for the standard input
	buf:	string;
	pos:	int;
	unbuf:	list of int;		# characters pushed back
	args:	array of string;	# a macro's arguments
	call:	int;			# a macro called
};

esrc: ref Esrc;
srcin: ref Iobuf;
src_cap := "";		# what was read of the input file (its bytes), as written

lineno := 1;
esrc_depth := 0;

src_init(f: ref Iobuf)
{
	srcin = f;
	esrc = ref Esrc(nil, nil, 0, nil, array[NARGS] of string, 0);
}

# push buf; a macro called if args is not nil
src_push(buf: string, args: array of string)
{
	if(esrc_depth > NSRCDEP)
		errdie("neateqn: macro recursion limit reached\n");
	next := ref Esrc(esrc, buf, 0, nil, array[NARGS] of string, args != nil);
	if(args != nil)
		for(i := 0; i < NARGS; i++)
			next.args[i] = args[i];
	esrc = next;
	esrc_depth++;
}

src_pop()
{
	if(esrc.prev != nil){
		esrc = esrc.prev;
		esrc_depth--;
	}
}

src_stdin(): int
{
	c := srcin.getb();
	if(c == '\n')
		lineno++;
	if(c > 0)
		src_cap[len src_cap] = c;
	return c;
}

src_next(): int
{
	for(;;){
		if(esrc.unbuf != nil){
			c := hd esrc.unbuf;
			esrc.unbuf = tl esrc.unbuf;
			return c;
		}
		if(esrc.prev == nil)
			return src_stdin();
		if(esrc.pos < len esrc.buf && esrc.buf[esrc.pos] != 0)
			return esrc.buf[esrc.pos++];
		src_pop();
	}
}

# what is captured begun again: with what was read and put back, unread
# (a token looked ahead to is put back as characters, not bytes: each
# captured as its bytes, UTF-8's)
src_capreset()
{
	src_cap = "";
	if(esrc.prev == nil)
		for(l := esrc.unbuf; l != nil; l = tl l){
			c := hd l;
			if(c < 16r80){
				src_cap[len src_cap] = c;
				continue;
			}
			r := "";
			r[0] = c;
			b := array of byte r;
			for(i := 0; i < len b; i++)
				src_cap[len src_cap] = int b[i];
		}
}

src_back(c: int)
{
	if(c > 0)
		esrc.unbuf = c :: esrc.unbuf;
}

src_lineget(): int
{
	return lineno;
}

src_lineset(n: int)
{
	lineno = n;
}

# eqn's macros
mac_name := array[NMACROS] of string;
mac_def := array[NMACROS] of string;
nmacros := 0;

src_findmacro(name: string): int
{
	for(i := 0; i < nmacros; i++)
		if(mac_name[i] == name)
			return i;
	return -1;
}

src_macro(name: string): int
{
	return src_findmacro(name) >= 0;
}

src_define(name, def: string)
{
	idx := src_findmacro(name);
	if(idx < 0 && nmacros < NMACROS)
		idx = nmacros++;
	if(idx >= 0){
		mac_name[idx] = name;
		mac_def[idx] = def;
	}
}

# expand a macro; non-zero if there is none
src_expand(name: string, args: array of string): int
{
	i := src_findmacro(name);
	if(i >= 0)
		src_push(mac_def[i], args);
	return i < 0;
}

# expand a macro's argument
src_arg(i: int): int
{
	call := esrc.call;
	if(call && esrc.args[i - 1] != nil)
		src_push(esrc.args[i - 1], nil);
	if(call)
		return 0;
	return 1;
}

# whether not reading macros and their arguments
src_top(): int
{
	return esrc.prev == nil;
}
