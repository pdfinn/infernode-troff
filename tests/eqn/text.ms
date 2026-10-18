.title "Inline and Aligned"
.maketitle
.EQ
delim $$
.EN
.chapter "Text" text
For every integer $n >= 1$ the partial sum $sum from {i = 1} to n i$ equals
${n ( n + 1 )} over 2$, and so the mean of the first $n$ integers is
$( n + 1 ) / 2$. A fraction such as $a over b$ in running text should not
push its lines apart more than it needs; a tall one, as
$left ( {x sup 2 + 1} over {x sup 2 - 1} right ) sup {1 over 2}$, may.
The quadratic $a x sup 2 + b x + c = 0$ has the roots
$x = {- b +- sqrt {b sup 2 - 4 a c}} over {2 a}$, which are real when the
discriminant $b sup 2 - 4 a c$ is not negative, and here the line goes on
long enough that an equation such as $f ( x ) = a sub 0 + a sub 1 x + a sub 2 x sup 2 + a sub 3 x sup 3 + a sub 4 x sup 4 + a sub 5 x sup 5$
must be broken somewhere, as TeX breaks one after a relation or an operator.
The integral $int from 0 to 1 x sup n dx = 1 over {n + 1}$ and the limit
$lim from {n -> inf} ( 1 + 1 over n ) sup n = e$ close the paragraph.
.p
Numbered displays follow, then three equations aligned on their signs:
.EQ (1.1)
e sup {i pi} + 1 = 0
.EN
.EQ (1.2)
int from {- inf} to inf e sup {- x sup 2} dx = sqrt pi
.EN
and aligned:
.EQ (1.3)
f ( x ) mark = ( x + 1 ) sup 2
.EN
.EQ (1.4)
lineup = x sup 2 + 2 x + 1
.EN
.EQ (1.5)
lineup >= 2 x + 1 ,
.EN
which ends the section.
