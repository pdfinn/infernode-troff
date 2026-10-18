.\" hard.ms - displays known to be hard to set, one a page, for maths_test.sh
.\" (the same in LaTeX were set against them; see docs/TROFF.md)
.rules 1
.pl 3i
.ll 6.5i
.po 0.25i
.ps 11
.vs 13.6p
.de EQ
.sp |1.3i
.ce 1
..
.de EN
..
.\" 1. Quadratic formula
.EQ
x = {- b +- sqrt {b sup 2 - 4 a c}} over {2 a}
.EN
.bp
.\" 2. Rogers–Ramanujan continued fraction
.EQ
R ( q ) = {q sup {1/5}} over {1 + displaystyle {q over {1 + displaystyle {{q sup 2} over {1 + displaystyle {{q sup 3} over {1 + cdots}}}}}}}
.EN
.bp
.\" 3. Ramanujan's series for 1/π
.EQ
1 over pi = {2 sqrt 2} over 9801 sum from {k = 0} to inf {( 4 k ) ! ^ ( 1103 + 26390 k )} over {( k ! ) sup 4 ^ 396 sup {4 k}}
.EN
.bp
.\" 4. Nested radicals
.EQ
3 = sqrt {1 + 2 sqrt {1 + 3 sqrt {1 + 4 sqrt {1 + cdots}}}}
.EN
.bp
.\" 5. Cardano's formula (cube roots)
.EQ
x = root 3 {q over 2 + sqrt {{q sup 2} over 4 + {p sup 3} over 27}} + root 3 {q over 2 - sqrt {{q sup 2} over 4 + {p sup 3} over 27}}
.EN
.bp
.\" 6. Cauchy's integral formula
.EQ
f ( a ) = 1 over {2 pi i} oint from gamma {f ( z )} over {z - a} ^ d z
.EN
.bp
.\" 7. Fourier transform
.EQ
f hat ( xi ) = int from {- inf} to inf f ( x ) ^ e sup {- 2 pi i x xi} ^ d x
.EN
.bp
.\" 8. Euler–Maclaurin formula
.EQ
sum from {i = m} to n f ( i ) = int from m to n f ( x ) ^ d x + {f ( n ) + f ( m )} over 2 + sum from {k = 1} to {\(lf p / 2 \(rf} {B sub {2 k}} over {( 2 k ) !} left ( f sup {( 2 k - 1 )} ( n ) - f sup {( 2 k - 1 )} ( m ) right ) + R sub p
.EN
.bp
.\" 9. Vandermonde determinant
.EQ
roman det left ( matrix { ccol {1 above 1 above vdots above 1} ccol {x sub 1 above x sub 2 above vdots above x sub n} ccol {x sub 1 sup 2 above x sub 2 sup 2 above vdots above x sub n sup 2} ccol {cdots above cdots above ddots above cdots} ccol {x sub 1 sup {n - 1} above x sub 2 sup {n - 1} above vdots above x sub n sup {n - 1}} } right ) = prod from {1 <= i < j <= n} ( x sub j - x sub i )
.EN
.bp
.\" 10. Cases
.EQ
| x | = left { lpile {x above - x} ~~~~ lpile {roman "if " x >= 0 , above roman "otherwise."} right ""
.EN
.bp
.\" 11. Maxwell's equations (aligned)
.EQ
matrix -100 { rcol 27 {nabla cdot bold E above nabla cdot bold B above nabla times bold E above nabla times bold B} lcol {{} = rho over {epsilon sub 0} above {} = 0 above {} = - {partial bold B} over {partial t} above {} = mu sub 0 left ( bold J + epsilon sub 0 {partial bold E} over {partial t} right )} }
.EN
.bp
.\" 12. Einstein field equations
.EQ
G sub {mu nu} + LAMBDA g sub {mu nu} = {8 pi G} over {c sup 4} T sub {mu nu}
.EN
.bp
.\" 13. Schrödinger equation
.EQ
i hbar partial over {partial t} PSI ( bold r , t ) = left [ - {hbar sup 2} over {2 m} nabla sup 2 + V ( bold r , t ) right ] PSI ( bold r , t )
.EN
.bp
.\" 14. Navier–Stokes equations
.EQ
rho left ( {partial bold u} over {partial t} + ( bold u cdot nabla ) bold u right ) = - nabla p + mu nabla sup 2 bold u + bold f
.EN
.bp
.\" 15. Binomial theorem
.EQ
( x + y ) sup n = sum from {k = 0} to n left ( pile {n above k} right ) x sup {n - k} y sup k
.EN
.bp
.\" 16. Gaussian (nested scripts)
.EQ
f ( x ) = 1 over {sigma sqrt {2 pi}} ^ e sup {- {( x - mu ) sup 2} over {2 sigma sup 2}}
.EN
.bp
.\" 17. Towers of scripts
.EQ
x sup {y sup {z sup w}} ~~~~ a sub {i sub {j sub k}} ~~~~ x sub n sup 2 ~~~~ e sup {i pi} + 1 = 0
.EN
.bp
.\" 18. Over- and underbraces
.EQ
underbrace {1 + 2 + cdots + n} from {n ~ roman terms} = overbrace {{n ( n + 1 )} over 2} to {roman triangular}
.EN
.bp
.\" 19. Divergence theorem
.EQ
iiint sub V ( nabla cdot bold F ) ^ d V = oiint sub {partial V} bold F cdot d bold S
.EN
.bp
.\" 20. Euler product for ζ
.EQ
zeta ( s ) = sum from {n = 1} to inf 1 over {n sup s} = prod from {p ~ roman "prime"} 1 over {1 - p sup {- s}}
.EN
.bp
.\" 21. Hessian matrix
.EQ
bold H sub f = left [ matrix { ccol {displaystyle {{partial sup 2 f} over {partial x sub 1 sup 2}} above displaystyle {{partial sup 2 f} over {partial x sub 2 ^ partial x sub 1}} above vdots} ccol {displaystyle {{partial sup 2 f} over {partial x sub 1 ^ partial x sub 2}} above displaystyle {{partial sup 2 f} over {partial x sub 2 sup 2}} above vdots} ccol {cdots above cdots above ddots} } right ]
.EN
.bp
.\" 22. Limits and isotopes
.EQ
lim from {x -> 0} {sin x} over x = 1 ~~~~ "" sub 6 sup 14 roman C -> "" sub 7 sup 14 roman N + e sup - + nu bar sub e
.EN
