.\" book -m article -S numeric -p works.bib
.\" paper.ms: the acceptance corpus's technical paper (tests/host/latex_test.sh),
.\" set by troff and written as LaTeX for a journal: book2tex -c ieee,
.\" -c acm, and LaTeX's own article. What a paper for the IEEE or the ACM
.\" has: authors and where they are, an abstract and keywords, numbered
.\" sections, numbered and aligned equations, a matrix and cases, mathematics
.\" in the text (eqn's words and Unicode's), a table with spans and a text
.\" block, figures in a column and across both, notes, lists, a program,
.\" citations (one, several, with a page) and cross-references, LaTeX's
.\" special characters and names with accents, URLs and an appendix.
.EQ
delim $$
define RR % ℝ %
.EN
.title "Setting Mathematics with Small Languages"
.subtitle "Preprocessors for troff, and the same paper as LaTeX"
.author "Ada Typesetter"
.affil "InferNode Project, Murray Hill, USA"
.email "ada_typesetter@example.org"
.author "Zoë Compositor"
.affil "Département de Lettres, Université de Lyon, France"
.email "zoe.compositor@example.fr"
.author "Jan Łukasiewicz-Smith"
.affil "Instytut Matematyki, Warsaw, Poland"
.email "jls@example.pl"
.abstract
Small languages, each turned into troff's requests by a preprocessor of
its own, set a paper's mathematics, tables and pictures. We describe
how the same source becomes LaTeX for a journal, measure what is kept,
and show that a paper written once can be submitted to the IEEE or to
the ACM without being typed again. Equations such as $x sup 2 + y sup 2 = z sup 2$
and tables survive the trip; so do 100% of the citations.
.endabstract
.keywords "typesetting, troff, LaTeX, eqn, tbl, pic"
.maketitle
.section "Introduction" intro

Troff was written by Joseph Ossanna for the phototypesetter at Bell
Laboratories,
.cite ossanna1976
and eqn followed it, so that mathematics could be described as it is
spoken.
.cite kernighan1975
TeX took another path: one large program with mathematics inside it.
.cite knuth1984; lamport1994
Both set a paragraph well, though TeX looks at the whole of it at once
.cite knuthplass1981 1124-26
and troff, traditionally, a line at a time.\*[fnmark]
.fn
Our troff now breaks a paragraph whole, as TeX does (section \*[ref method]).
.fe
.p
Journals ask for LaTeX. This paper is written for troff, and section
\*[ref method] shows how it becomes LaTeX that the IEEE's and the ACM's
classes accept. We claim three things:
.list 1
.item
the text, every word of it, arrives;
.item
equations, tables and figures arrive as LaTeX's own, not as pictures
of themselves, except for pictures, which arrive as PDF;
.item
citations become BibTeX's, in the journal's style.
.endlist
.section "Method" method
.subsection "Equations" eqns

An equation numbered in the source is numbered in LaTeX:
.EQ (1)
E = m c sup 2
.EN
and a display whose lines are aligned stays aligned:
.EQ (2)
f(x) mark = sum from {i = 0} to n a sub i x sup i
.EN
.EQ (3)
lineup = a sub 0 + a sub 1 x + ... + a sub n x sup n .
.EN
A matrix, and a function defined by cases, are written as eqn writes
them:
.EQ
A = left [ matrix { ccol { a above c } ccol { b above d } } right ] ,~~~
| x | = left { lpile { x above -x } ~~ lpile { roman "if " x >= 0 above roman "otherwise" } right ""
.EN
In the text, $alpha sub i <= beta$, $x ∈ RR sup n$, $int from 0 to inf e sup {-x} dx = 1$
and $sqrt {a sup 2 + b sup 2}$ are inline.
Greek written directly, $θ → φ$, is the same.
.subsection "Tables" tables

Table \*[ref timing] compares the two systems on a corpus of 180
pages. Its first column is text; the numbers line up on their decimal
points.
.table timing
.TS
center;
l c s
l n n
l n n.
	Time (s)
System	cold	warm
_
troff	0.42	0.21
LaTeX	1.95	0.88
=
Ratio	4.6	4.2
.TE
.caption "Time to set the corpus, cold and warm, and the ratio of the two systems."
.endtable
.p
A table may hold a paragraph in a cell:
.TS
center;
lb l.
Name	Description
_
eqn	T{
Mathematics, described as it is spoken: $x sup 2$ is \(lqx squared\(rq.
T}
tbl	Tables, in columns and spans.
.TE
.subsection "Figures" figs

Figure \*[ref flow] shows a picture with mathematics in its labels; the
pipeline across both columns is figure \*[ref pipe].
.figure flow
.alt "Three boxes, source, eqn and troff, joined by arrows; the middle box labelled with alpha."
.PS
boxwid = 0.6; boxht = 0.3
A: box "source"
arrow "$alpha$" above
B: box "eqn"
arrow
C: box "troff"
.PE
.caption "A picture whose label is an equation."
.endfigure
.figure* pipe
.alt "The whole pipeline: refer, pic, tbl, eqn, troff and tr2pdf, joined by arrows, ending in a PDF."
.PS
boxwid = 0.55; boxht = 0.28; linewid = 0.25
box "refer"; arrow; box "pic"; arrow; box "tbl"; arrow; box "eqn"; arrow
box "\fBtroff\fP"; arrow; box "tr2pdf"; arrow; ellipse "PDF"
.PE
.caption "The pipeline, across both columns."
.endfigure*
.subsection "Programs and special characters" special

A program is set as it is typed:
.nf
\f(CRfor(i = 0; i < n; i++)
	sum += a[i] & mask;	# 50% of {x}\fP
.fi
.EQ
delim off
.EN
.p
LaTeX's special characters are only characters here: 50% of $3, item #4,
snake_case, {braces}, a~tilde, a^caret and a back\eslash.
.EQ
delim $$
.EN
.p
Names keep their accents: Kurt Gödel,
.cite godel1931
Jan Łukasiewicz,
.cite lukasiewicz1957
Paul Erdős, Antonín Dvořák, Søren Kierkegaard and Anders Ångström; so do
“quotations,” dashes \(em long and short, 1984\(en1994 \(em and an ellipsis…
.section "Results" results

Every section, numbered equation, table and figure of this paper
arrives in each class; Plan 9 is cited as a system of its own
.cite pike1990 3
and Unicode's standard
.cite unicode2022
for its characters. Equation (2) and table \*[ref timing] keep their
numbers. The programs are at
.url https://github.com/pdfinn/infernode-troff/tree/main/appl/cmd ,
and the corpus is described in appendix \*[ref corpus]; its sources are on
.link https://github.com/pdfinn/infernode-troff/tree/main/tests/latex "the project's pages" .
.section "Conclusion" conclusion

A paper written once, in troff, is a paper for any journal that takes
LaTeX.
.appendix
.section "The corpus" corpus

The corpus is this paper and an essay in the humanities, with the
examples distributed with the programs.
.section* "Acknowledgments"

We thank the authors of Neatroff, whose programs these are.
.bibliography
