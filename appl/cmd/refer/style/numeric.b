implement Referstyle;

#
# numeric - citations numbered in the order works are first cited, as
# journals of the sciences and engineering give them (IEEE's, ACM's):
# [1] in the line, [1, p. 5] at a place in the work, [1], [3] for two;
# the references numbered, each hung from its number.
#
# A work's authors are named with their initials (B. W. Kernighan), up
# to six, else the first and et al.; titles of articles and chapters in
# quotation marks, of books and journals in italics; page ranges given
# in full (151–157).
#
# Kinds of work: book (author or editor; edition; volume), incollection,
# inbook and inproceedings (a chapter or paper in a book), article,
# techreport, phdthesis and mastersthesis, online and misc.
#

include "sys.m";
	sys: Sys;

include "referstyle.m";

init(): string
{
	sys = load Sys Sys->PATH;
	return nil;
}

nodoi := 0;
nourl := 0;

options(o: list of string): string
{
	for(; o != nil; o = tl o)
		case hd o {
		"nodoi" =>	nodoi = 1;
		"nourl" =>	nourl = 1;
		* =>	return "no option " + hd o + " (nodoi, nourl)";
		}
	return nil;
}

inline(): int
{
	return 1;
}

label(r: ref Ref): string
{
	return "[" + string r.num + "]";
}

get(r: ref Ref, f: string): string
{
	for(l := r.fields; l != nil; l = tl l)
		if((hd l).t0 == f)
			return (hd l).t1;
	return nil;
}

# [n], or [n, p. 5] at a place in the work: a number or a range is a
# page or pages, anything else (ch. 17, §177) is as it is given
note(r: ref Ref, nil: int, loc: string): string
{
	if(loc == nil)
		return "[" + string r.num + "]";
	l := range(loc);
	if(isdigit(l[0])){
		if(hasrange(l))
			l = "pp.\\~" + l;
		else
			l = "p.\\~" + l;
	}
	return "[" + string r.num + ", " + l + "]";
}

bib(r: ref Ref): string
{
	s: string;
	case r.typ {
	"article" =>
		s = articlebib(r);
	"incollection" or "inbook" or "inproceedings" =>
		s = chapterbib(r);
	"phdthesis" or "mastersthesis" or "thesis" =>
		s = thesisbib(r);
	"techreport" or "report" =>
		s = reportbib(r);
	"book" or "collection" or "mvbook" or "proceedings" =>
		s = bookbib(r);
	* =>
		if(get(r, "publisher") != nil)
			s = bookbib(r);
		else
			s = miscbib(r);
	}
	return clean(s);
}

# in the order first cited
sortkey(r: ref Ref): string
{
	return sys->sprint("%08d", r.num);
}

#
# the references
#

bookbib(r: ref Ref): string
{
	s := "";
	if(len r.author > 0)
		s = names(r.author) + ", ";
	else if(len r.editor > 0)
		s = names(r.editor) + ", " + eds(len r.editor) + ", ";
	s += ital(title(r));
	if((v := get(r, "volume")) != nil)
		s += ", vol. " + v;
	if((e := edition(r)) != nil)
		s += ", " + e;
	s += ". " + pubinfo(r);
	return withlink(r, s + ".");
}

chapterbib(r: ref Ref): string
{
	s := names(r.author) + ", " + quote(title(r), ",");
	s += " in " + ital(get(r, "booktitle"));
	if(len r.editor > 0)
		s += ", " + names(r.editor) + ", " + eds(len r.editor);
	if(get(r, "publisher") != nil)
		s += ". " + pubinfo(r);
	else
		s += ", " + year(r);
	if((p := get(r, "pages")) != nil)
		s += ", " + pages(p);
	return withlink(r, s + ".");
}

articlebib(r: ref Ref): string
{
	s := names(r.author) + ", " + quote(title(r), ",");
	s += " " + ital(journal(r));
	if((v := get(r, "volume")) != nil)
		s += ", vol. " + v;
	if((n := get(r, "number")) != nil || (n = get(r, "issue")) != nil)
		s += ", no. " + n;
	if((p := get(r, "pages")) != nil)
		s += ", " + pages(p);
	s += ", " + issuedate(r);
	return withlink(r, s + ".");
}

thesisbib(r: ref Ref): string
{
	s := names(r.author) + ", " + quote(title(r), ",");
	if((t := get(r, "type")) != nil)
		s += " " + t;
	else if(r.typ == "mastersthesis")
		s += " Master’s thesis";
	else
		s += " Ph.D. dissertation";
	if((sch := get(r, "school")) != nil || (sch = get(r, "institution")) != nil)
		s += ", " + sch;
	if((a := get(r, "address")) != nil)
		s += ", " + a;
	s += ", " + year(r);
	return withlink(r, s + ".");
}

# a report: its institution, where, its series and number
reportbib(r: ref Ref): string
{
	s := names(r.author) + ", " + quote(title(r), ",");
	if((i := get(r, "institution")) != nil)
		s += " " + i;
	if((a := get(r, "address")) != nil)
		s += ", " + a;
	t := get(r, "type");
	if(t == nil)
		t = "Tech. Rep.";
	if((n := get(r, "number")) != nil)
		t += " " + n;
	s += ", " + t + ", " + issuedate(r);
	return withlink(r, s + ".");
}

miscbib(r: ref Ref): string
{
	s := "";
	if(len r.author > 0)
		s = names(r.author) + ", ";
	else if(len r.editor > 0)
		s = names(r.editor) + ", " + eds(len r.editor) + ", ";
	s += quote(title(r), ".");
	if((h := get(r, "howpublished")) != nil || (h = get(r, "organization")) != nil || (h = get(r, "publisher")) != nil)
		s += " " + h + ",";
	if((d := get(r, "date")) != nil || (d = get(r, "year")) != nil)
		s += " " + d;
	s = strip(s, ",");
	return withlink(r, s + ".");
}

# the work's DOI or URL after it
withlink(r: ref Ref, s: string): string
{
	if((d := get(r, "doi")) != nil && !nodoi){
		if(len d < 4 || d[0:4] != "http")
			d = "https://doi.org/" + d;
		return s + " " + d;
	}
	if(!nourl && (u := get(r, "url")) != nil)
		return s + " [Online]. Available: " + u;
	return s;
}

#
# parts
#

# names with initials: A, A and B, A, B, and C; up to six, else A et al.
names(n: array of ref Name): string
{
	if(len n == 0)
		return "";
	if(len n > 6)
		return initialled(n[0]) + " \\fIet al.\\fP";
	s := initialled(n[0]);
	if(len n == 2)
		return s + " and " + initialled(n[1]);
	for(i := 1; i < len n; i++){
		if(i == len n - 1)
			s += ", and ";
		else
			s += ", ";
		s += initialled(n[i]);
	}
	return s;
}

# B. W. Kernighan; J.-P. Sartre; an organization as it is
initialled(n: ref Name): string
{
	s := initials(n.first);
	if(n.von != "")
		s = join(s, " ", n.von);
	s = join(s, " ", n.last);
	if(n.jr != "")
		s += ", " + n.jr;
	return s;
}

# each word of a name its initial, with a period; a hyphenated one's parts
# each theirs (Jean-Paul J.-P.); one already an initial (E.) as it is
initials(f: string): string
{
	r := "";
	word := 1;
	for(i := 0; i < len f; i++){
		c := f[i];
		if(c == ' ' || c == '~'){
			if(!word)
				r += " ";
			word = 1;
			continue;
		}
		if(c == '-'){
			r += "-";
			word = 1;
			continue;
		}
		if(word){
			if(c == '\\'){
				# a troff escape (\(...): kept whole with the letter it begins
				j := i;
				while(j < len f && f[j] != ' ' && f[j] != '-')
					j++;
				r += f[i:j];
				if(r[len r - 1] != '.')
					r += ".";
				i = j - 1;
			}else{
				r[len r] = c;
				r += ".";
			}
			word = 0;
		}
	}
	return r;
}

eds(n: int): string
{
	if(n > 1)
		return "Eds.";
	return "Ed.";
}

title(r: ref Ref): string
{
	t := get(r, "title");
	if((st := get(r, "subtitle")) != nil)
		t += ": " + st;
	return t;
}

journal(r: ref Ref): string
{
	if((j := get(r, "journaltitle")) != nil)
		return j;
	return get(r, "journal");
}

issuedate(r: ref Ref): string
{
	y := year(r);
	if((m := get(r, "month")) != nil)
		return monthabbr(m) + " " + y;
	return y;
}

# a month abbreviated as IEEE abbreviates them: Jan., June, Sept.
monthabbr(m: string): string
{
	names := array[] of {"Jan.", "Feb.", "Mar.", "Apr.", "May", "June",
		"July", "Aug.", "Sept.", "Oct.", "Nov.", "Dec."};
	n := 0;
	for(i := 0; i < len m; i++){
		if(m[i] < '0' || m[i] > '9'){
			for(k := 0; k < len names; k++)
				if(len m >= 3 && len names[k] >= 3 && fold(m[0:3]) == fold(names[k][0:3]))
					return names[k];
			return m;
		}
		n = 10 * n + m[i] - '0';
	}
	if(n >= 1 && n <= 12)
		return names[n - 1];
	return m;
}

year(r: ref Ref): string
{
	if((y := get(r, "year")) != nil)
		return y;
	if((d := get(r, "date")) != nil && len d >= 4)
		return d[0:4];
	return "n.d.";
}

# place: publisher, year
pubinfo(r: ref Ref): string
{
	s := "";
	if((p := get(r, "publisher")) != nil)
		s = p;
	if((a := get(r, "address")) != nil || (a = get(r, "location")) != nil){
		if(s != "")
			s = a + ": " + s;
		else
			s = a;
	}
	return join(s, ", ", year(r));
}

edition(r: ref Ref): string
{
	e := get(r, "edition");
	if(e == nil)
		return nil;
	n := 0;
	for(i := 0; i < len e; i++){
		if(e[i] < '0' || e[i] > '9')
			return e;
		n = n * 10 + e[i] - '0';
	}
	if(n == 1)
		return nil;
	sfx := "th";
	if(n % 100 < 11 || n % 100 > 13)
		case n % 10 {
		1 =>	sfx = "st";
		2 =>	sfx = "nd";
		3 =>	sfx = "rd";
		}
	return string n + sfx + " ed.";
}

# p. 5 or pp. 151–157
pages(p: string): string
{
	p = range(p);
	if(hasrange(p))
		return "pp.\\~" + p;
	return "p.\\~" + p;
}

hasrange(s: string): int
{
	for(i := 0; i < len s; i++)
		if(s[i] == '–' || s[i] == ',')
			return 1;
	return 0;
}

# a range's hyphens (- or --) between numbers an en dash, the numbers whole
range(s: string): string
{
	r := "";
	for(i := 0; i < len s; i++){
		c := s[i];
		if((c == '-' || c == '–') && i > 0 && isdigit(s[i - 1])){
			e := i + 1;
			while(e < len s && (s[e] == '-' || s[e] == '–'))
				e++;
			if(e < len s && isdigit(s[e])){
				r += "–";
				i = e - 1;
				continue;
			}
		}
		r[len r] = c;
	}
	return r;
}

ital(s: string): string
{
	if(s == nil)
		return "";
	return "\\fI" + replace(s, "\\fI", "\\fR") + "\\fP";
}

# in quotation marks, the punctuation within (American); quotations
# within single
quote(s, punct: string): string
{
	if(s == nil)
		return "";
	s = replace(replace(s, "“", "‘"), "”", "’");
	if(len s > 0 && (s[len s - 1] == '?' || s[len s - 1] == '!'))
		punct = "";
	return "“" + s + punct + "”";
}

join(a, sep, b: string): string
{
	if(a == "")
		return b;
	if(b == "")
		return a;
	return a + sep + b;
}

strip(s, sep: string): string
{
	if(len s >= len sep && s[len s - len sep:] == sep)
		return s[0:len s - len sep];
	return s;
}

replace(s, a, b: string): string
{
	r := "";
	for(i := 0; i < len s; ){
		if(i + len a <= len s && s[i:i + len a] == a){
			r += b;
			i += len a;
		}else
			r[len r] = s[i++];
	}
	return r;
}

# a period doubled where parts meet (an initial ending a name, a title
# ending in a question): one
clean(s: string): string
{
	r := "";
	for(i := 0; i < len s; i++){
		c := s[i];
		if(c == '.' || c == ','){
			j := len r - 1;
			for(;;){
				if(j >= 2 && r[j - 2] == '\\' && r[j - 1] == 'f')
					j -= 3;
				else if(j >= 0 && (r[j] == '”' || r[j] == '’'))
					j--;
				else
					break;
			}
			if(c == '.' && j >= 0 && (r[j] == '.' || r[j] == '?' || r[j] == '!'))
				continue;
		}
		r[len r] = c;
	}
	return r;
}

isdigit(c: int): int
{
	return c >= '0' && c <= '9';
}

fold(s: string): string
{
	r := "";
	for(i := 0; i < len s; i++){
		c := s[i];
		if(c >= 'A' && c <= 'Z')
			c += 'a' - 'A';
		r[len r] = c;
	}
	return r;
}
