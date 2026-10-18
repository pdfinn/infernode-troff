.\" chapter.ms — an example chapter for book(1): notes, citations,
.\" mathematics in the text and displayed, a table and a picture.
.\"
.\"	book -p works.bib chapter.ms		# chapter.pdf
.EQ
delim $$
.EN
.chapter "The Normal Law of Error" normal
.epigraph
The theory of probabilities is at bottom nothing but common sense
reduced to calculus.
.attrib "Laplace, \fIEssai philosophique\fP"
.endepigraph

When an astronomer measures the same angle a hundred times, the
readings scatter about a centre, the small errors many and the large
ones few. Gauss asked which law of error makes the arithmetic mean the
most probable value of the quantity measured, and found it.
.cite gauss1809 §177
If the readings are $x sub 1 , ... , x sub n$ and their errors are
independent, the law must be
.EQ (1.1)
phi ( x ) = 1 over {sigma sqrt {2 pi}} ^ e sup {- {( x - mu ) sup 2} over {2 sigma sup 2}}
.EN
where $mu$ is the true value and $sigma$ measures the spread of the
readings.\c
.fn
Gauss's own measure was the precision $h = 1 / ( sigma sqrt 2 )$; the
standard deviation $sigma$ is Pearson's, of 1894.
.fe
That it is a law at all, that its area is one, rests on an integral
known since de Moivre:
.EQ (1.2)
int from {- inf} to inf e sup {- x sup 2} dx = sqrt pi .
.EN
.section "The integral" integral

Square it, and the product of two integrals is one over the plane,
which polar coordinates take apart:
.EQ (1.3)
left ( int from {- inf} to inf e sup {- x sup 2} dx right ) sup 2
= int from 0 to {2 pi} int from 0 to inf e sup {- r sup 2} r ^ dr ^ d theta
= pi .
.EN
The same argument gives every moment of the law. With $k$ a natural
number, the even moments are
.EQ (1.4)
E [ ( X - mu ) sup {2 k} ] = sigma sup {2 k} ( 2 k - 1 ) !! ,
.EN
and the odd ones vanish, the law being symmetric about $mu$. Table
\*[ref moments] gives the first few, and figure \*[ref curve] the
shape of the curve.
.table moments
.TS
center;
l c c c.
moment	$k = 1$	$k = 2$	$k = 3$
_
$E [ ( X - mu ) sup {2 k} ]$	$sigma sup 2$	$3 sigma sup 4$	$15 sigma sup 6$
fraction within $k sigma$	0.6827	0.9545	0.9973
.TE
.caption "The even moments of the normal law, and how much of it lies within $k$ standard deviations of the mean."
.endtable
.figure curve
.alt "The bell curve of the normal law, its mean marked and one standard deviation either side."
.PS
scale = 1.6
line from (-2.6, 0.000) to (2.6, 0.000)
spline from (-2.5, 0.072) to (-2, 0.216) to (-1.5, 0.520) to (-1, 0.968) \
  to (-0.5, 1.408) to (0, 1.596) to (0.5, 1.408) to (1, 0.968) \
  to (1.5, 0.520) to (2, 0.216) to (2.5, 0.072)
line dashed from (0, 0.000) to (0, 1.596)
line dotted from (-1, 0.000) to (-1, 0.968)
line dotted from (1, 0.000) to (1, 0.968)
"\f2μ\fP" at (0, -0.25)
"\f2μ\fP \- \f2σ\fP" at (-1, -0.25)
"\f2μ\fP + \f2σ\fP" at (1, -0.25)
.PE
.caption "The normal law: two thirds of it within one standard deviation of the mean."
.endfigure
.section "Sums of errors" sums

Why should errors follow this law? Laplace's answer was that an error
is the sum of many small ones. If $X sub 1 , X sub 2 , ...$ are
independent, each with mean $mu$ and variance $sigma sup 2$, then
.EQ (1.5)
lim from {n -> inf} P left ( {sum from {i = 1} to n X sub i - n mu} over {sigma sqrt n} <= z right )
= int from {- inf} to z phi ( t ) ^ dt ,
.EN
whatever the law of each, so long as its variance is finite. This is
the central limit theorem, and it is why the curve of figure
\*[ref curve] is drawn wherever measurements are made.
.p
Setting such mathematics well is an old problem. Kernighan and Cherry
made a language for it that reads as one speaks it,
.cite kernighan1975
and Knuth's rules place each part of a formula as a compositor would.
.cite knuth1984 ch. 17
Typography, in Bringhurst's phrase, exists to honour its content.
.cite bringhurst2004 17
