implement Tr2img;

#
# tr2img - a page of troff's output painted, as a PPM image
#
#	tr2img [-p page] [-r dpi] [-d dir] [file] >page.ppm
#
# The page (from 1; 1) at dpi dots to the inch (72), painted as the
# document views paint it (troffpage(2)): its glyphs from the device's
# outline fonts, its drawings, its images (their names taken from dir,
# else the current directory).
#

include "sys.m";
	sys: Sys;

include "draw.m";
	draw: Draw;
	Display, Image, Rect: import draw;

include "bufio.m";
	bufio: Bufio;
	Iobuf: import bufio;

include "troffpage.m";
	troffpage: Troffpage;
	Doc: import troffpage;

Tr2img: module
{
	init:	fn(nil: ref Draw->Context, args: list of string);
};

init(nil: ref Draw->Context, args: list of string)
{
	sys = load Sys Sys->PATH;
	draw = load Draw Draw->PATH;
	bufio = load Bufio Bufio->PATH;
	troffpage = load Troffpage Troffpage->PATH;
	if(troffpage == nil)
		fail(sys->sprint("cannot load %s: %r", Troffpage->PATH));
	page := 1;
	dpi := 72;
	dir: string;
	file: string;
	for(args = tl args; args != nil; args = tl args){
		a := hd args;
		if((a == "-p" || a == "-r" || a == "-d") && tl args != nil){
			args = tl args;
			case a {
			"-p" =>	page = int hd args;
			"-r" =>	dpi = int hd args;
			"-d" =>	dir = hd args;
			}
		}else if(a != nil && a[0] == '-')
			fail("usage: tr2img [-p page] [-r dpi] [-d dir] [file]");
		else
			file = a;
	}
	data := readall(file);
	if(data == nil)
		fail(sys->sprint("cannot read %s: %r", file));
	display := Display.allocate(nil);
	if(display == nil)
		fail(sys->sprint("no display: %r"));
	if((e := troffpage->init(display)) != nil)
		fail(e);
	(d, err) := troffpage->opendir(data, nil, dir);
	if(d == nil)
		fail(err);
	if(page < 1 || page > d.npages)
		fail(sys->sprint("no page %d of %d", page, d.npages));
	k := real dpi / 72.0;
	r := Rect((0, 0), (int (real d.width * k + 0.5), int (real d.height * k + 0.5)));
	im := display.newimage(r, Draw->RGB24, 0, Draw->White);
	if(im == nil)
		fail(sys->sprint("no image: %r"));
	if((err = d.paint(page - 1, k, im, r, (0, 0))) != nil)
		fail(err);
	px := array[3 * r.dx() * r.dy()] of byte;
	im.readpixels(r, px);
	for(i := 0; i < len px; i += 3){	# RGB24 is b, g, r in memory
		(px[i], px[i + 2]) = (px[i + 2], px[i]);
	}
	out := bufio->fopen(sys->fildes(1), Bufio->OWRITE);
	out.puts(sys->sprint("P6\n%d %d\n255\n", r.dx(), r.dy()));
	out.write(px, len px);
	out.flush();
}

readall(file: string): array of byte
{
	fd: ref Sys->FD;
	if(file == nil)
		fd = sys->fildes(0);
	else
		fd = sys->open(file, Sys->OREAD);
	if(fd == nil)
		return nil;
	b := array[1 << 16] of byte;
	n := 0;
	for(;;){
		if(n == len b){
			nb := array[2 * len b] of byte;
			nb[0:] = b;
			b = nb;
		}
		m := sys->read(fd, b[n:], len b - n);
		if(m <= 0)
			break;
		n += m;
	}
	return b[0:n];
}

fail(s: string)
{
	sys->fprint(sys->fildes(2), "tr2img: %s\n", s);
	raise "fail:" + s;
}
