.\" maths.ms — displays known to be hard to set, from tests/eqn/hard.ms
.\"
.\"	book maths.ms		# maths.pdf

.p
.ti 0
\fIQuadratic formula\fP
.EQ
x = {- b +- sqrt {b sup 2 - 4 a c}} over {2 a}
.EN
.p
\fIRogers–Ramanujan continued fraction\fP
.EQ
R ( q ) = {strut q sup {1/5}} over {1 + displaystyle {{strut q} over {1 + displaystyle {{strut q sup 2} over {1 + displaystyle {{strut q sup 3} over {1 + cdots}}}}}}}
.EN
.p
\fIRamanujan's series for 1/π\fP
.EQ
1 over pi = {2 sqrt 2} over 9801 sum from {k = 0} to inf {( 4 k ) ! ^ ( 1103 + 26390 k )} over {( k ! ) sup 4 ^ 396 sup {4 k}}
.EN
.p
\fICardano's formula (cube roots)\fP
.EQ
x = root 3 {q over 2 + sqrt {{q sup 2} over 4 + {p sup 3} over 27}} + root 3 {q over 2 - sqrt {{q sup 2} over 4 + {p sup 3} over 27}}
.EN
.p
\fICauchy's integral formula\fP
.EQ
f ( a ) = 1 over {2 pi i} oint from gamma {f ( z )} over {z - a} ^ d z
.EN
.p
\fIVandermonde determinant\fP
.EQ
roman det left ( matrix { ccol {1 above 1 above vdots above 1} ccol {x sub 1 above x sub 2 above vdots above x sub n} ccol {x sub 1 sup 2 above x sub 2 sup 2 above vdots above x sub n sup 2} ccol {cdots above cdots above ddots above cdots} ccol {x sub 1 sup {n - 1} above x sub 2 sup {n - 1} above vdots above x sub n sup {n - 1}} } right ) = prod from {1 <= i < j <= n} ( x sub j - x sub i )
.EN
.p
\fICases\fP
.EQ
| x | = left { lpile {x above - x} ~~~~ lpile {roman "if " x >= 0 , above roman "otherwise."} right ""
.EN
.p
\fIBinomial theorem\fP
.EQ
( x + y ) sup n = sum from {k = 0} to n {n choose k} x sup {n - k} y sup k
.EN
