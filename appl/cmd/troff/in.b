#
# in.c: the input layer
#

Inbuf: adt {
	path:	string;		# for file buffers
	isfile:	int;
	buf:	string;		# for string buffers
	args:	array of string;	# macro arguments
	hasargs:	int;
	unbuf:	array of int;	# unread characters
	un:	int;
	pos:	int;
	chr:	int;		# the last character read from fin
	lnum:	int;		# file line number
	prev:	cyclic ref Inbuf;
};

buf: ref Inbuf;
files := array[NFILES] of string;
nfiles := 0;
cfile := 0;

ifree: ref Inbuf;	# buffers popped, to be used again (one is pushed for every string interpolated)

in_new()
{
	next := ifree;
	if(next != nil){
		ifree = next.prev;
		next.isfile = 0;
		next.hasargs = 0;
		next.un = 0;
		next.pos = 0;
		next.chr = 0;
		next.lnum = 0;
	}else
		next = ref Inbuf;
	next.prev = buf;
	buf = next;
}

in_push(s: string, args: array of string)
{
	in_new();
	buf.buf = s;
	if(args != nil){
		buf.args = args_init(args);
		buf.hasargs = 1;
	}
}

# like in_push(), with an empty argument list (Neatroff's non-NULL args)
in_pushargs(s: string, args: array of string)
{
	in_new();
	buf.buf = s;
	buf.args = args_init(args);
	buf.hasargs = 1;
}

in_so(path: string)
{
	fd: ref Sys->FD;
	if(path != nil)
		fd = sys->open(path, Sys->OREAD);
	else
		fd = sys->fildes(0);
	if(fd == nil){
		errmsg(sys->sprint("troff: failed to open <%s>\n", path));
		return;
	}
	# read whole, its characters then taken as a string's (a call to
	# Bufio's getc for each was a tenth of troff's time)
	b := array[65536] of byte;
	n := 0;
	for(;;){
		if(n == len b){
			nb := array[2 * len b] of byte;
			nb[0:] = b;
			b = nb;
		}
		if((k := sys->read(fd, b[n:], len b - n)) <= 0)
			break;
		n += k;
	}
	in_new();
	buf.buf = string b[0:n];
	buf.isfile = 1;
	buf.lnum = 1;
	buf.path = path;
}

in_lf(path: string, lnum: int)
{
	cur := buf;
	while(cur != nil && !cur.isfile)
		cur = cur.prev;
	if(cur == nil)
		return;
	if(path != nil)
		cur.path = path;
	cur.lnum = lnum - 1;
}

in_queue(path: string)
{
	if(nfiles < NFILES)
		files[nfiles++] = path;
}

in_pop()
{
	old := buf;
	buf = buf.prev;
	old.path = nil;
	old.buf = nil;
	old.args = nil;
	old.prev = ifree;
	ifree = old;
}

in_nx(path: string)
{
	while(buf != nil)
		in_pop();
	if(path != nil)
		in_so(path);
}

in_ex()
{
	while(buf != nil)
		in_pop();
	cfile = nfiles;
}

in_nextfile(): int
{
	while(buf == nil && cfile < nfiles)
		in_so(files[cfile++]);
	return buf == nil;
}

in_next(): int
{
	while(buf != nil || !in_nextfile()){
		if(buf.un)
			return buf.unbuf[--buf.un];
		if(buf.pos < len buf.buf){
			c := buf.buf[buf.pos++];
			if(buf.isfile){
				if(buf.chr == '\n')
					buf.lnum++;
				buf.chr = c;
			}
			return c;
		}
		in_pop();
	}
	return -1;
}

# in copy mode, the characters next in a string being read (not a
# file's) that copy mode would give as they are: all but a newline,
# c_ni, and an escape it acts on (\n \* \$ \" ...); none if the next is
# one of those. read_string takes them at once, not each through
# cp_next (an equation's strings appended to one another are most of
# what eqn's output has troff read)
CPKEEP: con "\n.\\ta\"#n*g$?";

in_cprun(): string
{
	if(buf == nil || buf.un || buf.isfile)
		return nil;
	s := buf.buf;
	i := buf.pos;
	n := len s;
	for(; i < n; i++){
		c := s[i];
		if(c == '\n' || c == c_ni)
			break;
		if(c == c_ec){
			if(i + 1 >= n)
				break;
			d := s[i + 1];
			if(d == c_ni || d == c_ec || strchr(CPKEEP, d) >= 0)
				break;
			i++;
		}
	}
	if(i == buf.pos)
		return nil;
	r := s[buf.pos:i];
	buf.pos = i;
	return r;
}

in_back(c: int)
{
	if(c < 0)
		return;
	if(buf == nil)
		return;
	if(buf.unbuf == nil)
		buf.unbuf = array[32] of int;
	if(buf.un < len buf.unbuf)
		buf.unbuf[buf.un++] = c;
}

in_top(): int
{
	if(buf != nil && buf.un)
		return buf.unbuf[buf.un - 1];
	return -1;
}

in_arg(i: int): string
{
	cur := buf;
	while(cur != nil && !cur.hasargs)
		cur = cur.prev;
	if(cur != nil && i < NARGS && i < len cur.args)
		return cur.args[i];
	return "";
}

in_nargs(): int
{
	cur := buf;
	while(cur != nil && !cur.hasargs)
		cur = cur.prev;
	if(cur != nil)
		return len cur.args;
	return 0;
}

in_shift()
{
	cur := buf;
	while(cur != nil && !cur.hasargs)
		cur = cur.prev;
	if(cur != nil && len cur.args > 1){
		a := array[len cur.args - 1] of string;
		a[0] = cur.args[0];
		a[1:] = cur.args[2:];
		cur.args = a;
	}
}

in_filename(): string
{
	cur := buf;
	while(cur != nil && !cur.isfile)
		cur = cur.prev;
	if(cur != nil && cur.path != nil)
		return cur.path;
	return "-";
}

in_lnum(): int
{
	cur := buf;
	while(cur != nil && !cur.isfile)
		cur = cur.prev;
	if(cur != nil)
		return cur.lnum;
	return 0;
}

args_init(args: array of string): array of string
{
	n := len args;
	if(n > NARGS)
		n = NARGS;
	out := array[n] of string;
	out[0:] = args[0:n];
	return out;
}
