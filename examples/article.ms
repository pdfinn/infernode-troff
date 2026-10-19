.\" article.ms — a journal article for -marticle: two columns, the title
.\" block across both, numbered citations (refer -S numeric), an
.\" equation, a table, a figure in a column and one across both.
.\"
.\"	book -m article -S numeric -p works.bib article.ms	# article.pdf
.EQ
delim $$
.EN
.title "Setting a Paragraph Whole"
.subtitle "Optimum-fit line breaking in a troff for InferNode"
.author "A. Typesetter"
.affil "InferNode Project"
.email "typesetter@example.org"
.author "B. Compositor"
.affil "Department of Letters"
.email "compositor@example.org"
.abstract
A paragraph broken one line at a time is broken greedily: each line
takes as many words as fit, and a loose line is discovered only when
it can no longer be helped. Knuth and Plass showed that choosing every
break of a paragraph at once, as the shortest path through a graph of
feasible breaks, gives evenly spaced text with fewer hyphens. We
describe how the method fits troff's model of filling and adjusting,
and compare its spacing with LuaLaTeX's on the same prose.
.endabstract
.keywords "typesetting, line breaking, troff, dynamic programming"
.maketitle
.section "Introduction" intro

Troff fills a line until the next word will not fit, then adjusts it
to the measure by widening its spaces.
.cite ossanna1976
The rule is simple and fast, and it is local: the line just set is
never reconsidered. When a long word follows a short line, the line
must be stretched however far it takes, and the reader sees a river
of white running down the page.
.p
TeX instead treats a paragraph as a whole.
.cite knuthplass1981
Every place a line may end is a node; every way of setting the words
between two such places as a line is an edge, weighted by how badly
the line would look. The best paragraph is the cheapest path from the
first node to the last, found by dynamic programming in time linear in
the length of the paragraph when, as in practice, lines are few
words long.\*[fnmark]
.fn
A line can end only where it would not be stretched or shrunk beyond
what its spaces allow, so each node has only a handful of predecessors.
.fe
.section "The cost of a line" cost

A line's spaces can stretch or shrink. Let $r$ be the ratio by which
they must, as a fraction of what they allow. Its badness grows as the
cube of that ratio, and a line's demerits combine it with the penalty
$p$ of the break it ends at:
.EQ (1)
d = left ( l + 100 | r | sup 3 right ) sup 2 + p sup 2 ,
.EN
where $l$ is a small constant that makes fewer lines better than more.
A hyphen's break carries a penalty, and two hyphenated lines in a row
an extra one, so hyphens are few and seldom stacked.
.figure graph
.alt "Five nodes, the breaks a paragraph may take, joined by arcs from left to right; the cheapest path through them drawn solid, the others dashed."
.PS
circlerad = 0.12
A: circle "0"
B: circle "1" at A + (0.9, 0.35)
C: circle "2" at A + (0.9, -0.35)
D: circle "3" at A + (1.8, 0)
E: circle "4" at A + (2.7, 0)
arrow from A to B chop dashed
arrow from A to C chop
arrow from B to D chop dashed
arrow from C to D chop
arrow from B to E chop dashed
arrow from D to E chop
.PE
.caption "Feasible breaks of a short paragraph. Each arc is a line; the solid path is the one of least total demerits."
.endfigure
.p
Figure \*[ref graph] shows the idea for a paragraph of three lines.
Breaking greedily would take the first arc that fits and follow it;
the whole-paragraph method keeps, for each node, only the cheapest way
of reaching it, and so considers every path without enumerating them.
.section "Fitting it to troff" troff

Troff's filling is driven by its input: words arrive one at a time,
and requests such as a break or a change of font may come between
them. Our troff collects a paragraph's words, with their fonts, sizes
and the escapes between them, until something ends the paragraph, and
only then chooses its breaks.
.p
Two of TeX's refinements carry over directly. A space may shrink by a
third, so that a line need not be broken short and stretched; and a
hyphen costs as a loose line does, a second in a row ten times as
much, a fourth not allowed at all.
.figure* pipeline
.alt "A row of boxes joined by arrows: the source, refer, chess, pic, tbl, eqn, troff and tr2pdf, ending in the PDF."
.PS
boxwid = 0.55; boxht = 0.28; linewid = 0.2
S: box "source"
arrow
box "refer"
arrow
box "chess"
arrow
box "pic"
arrow
box "tbl"
arrow
box "eqn"
arrow
box "\fBtroff\fP"
arrow
box "tr2pdf"
arrow
ellipse "PDF"
.PE
.caption "The pipeline book(1) runs. Each preprocessor runs only if the document uses it; troff runs as often as cross-references need."
.endfigure*
.section "Results" results

We set 180 pages of prose, the documentation of this system, with our
troff and with LuaLaTeX and its microtype package, on the same page
and in the same face, and measured every justified line of each.
Table \*[ref spacing] gives the results.
.table spacing
.TS
center;
l c c.
	troff	LuaLaTeX
_
mean space (em)	0.27	0.28
95th percentile (em)	0.38	0.35
lines looser than 0.5 em	21	25
lines hyphenated	10%	8%
two hyphens in a row	32	28
.TE
.caption "Interword spacing and hyphenation on 180 pages of prose."
.endtable
.p
The two are close. Troff's spaces are as even on average, with a
slightly longer tail; it hyphenates a little more often.
.section "Pictures and the rest" rest

Figures in this article are drawn with pic,
.cite kernighan1982
equations set by eqn
.cite kernighan1975
and tables by tbl. Each is a preprocessor that turns its own small
language into troff's requests, so that the formatter itself need know
nothing of graphs, formulas or tables; the pipeline that runs them is
shown in figure \*[ref pipeline]. The same arrangement serves an
article and a book: the class decides the page, and the tools are
shared.
.section "Conclusion" conclusion

Whole-paragraph line breaking costs troff little: a page of prose is
set in about twenty milliseconds, and its spacing is as even as
LaTeX's. The method belongs as much to troff's tradition of small,
composable programs as to TeX's.
.section* "Acknowledgements"

The measurements were made with the tools described here, on the
documents distributed with them.
.bibliography
