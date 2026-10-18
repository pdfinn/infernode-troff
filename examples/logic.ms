.\" logic.ms — logic set with eqn, tbl and pic: formulas in the text,
.\" a truth table, and proofs by tableau (truth trees), an argument's
.\" countermodel as a table. The tableaux and the countermodel are
.\" tableau(1)'s, from infernode-wwb (prove -P, then tableau), each
.\" tree made a figure, its title a caption.
.\"
.\"	book logic.ms		# logic.pdf
.char → \f[S]\N'arrowright'
.char ↔ \f[S]\N'arrowboth'
.char ∧ \f[S]\N'logicaland'
.char ∨ \f[S]\N'logicalor'
.char ¬ \f[S]\N'logicalnot'
.char ∀ \f[S]\N'universal'
.char ∃ \f[S]\N'existential'
.char ◇ \f[S]\N'uni25C7'
.char × \f[S]\N'multiply'
.char ∅ \f[S]\N'emptyset'
.char ↑ \f[S]\N'arrowup'
.rules 1
.fp 13 SZ S
.fzoom SZ 1333
.char □ \v'0.072m'\f[SZ]\N'H22073'\v'-0.072m'
.de tableau-hd
'sp |1i
..
.de tableau-fo
'bp
..
.if !\n[book-ps] .wh 0 tableau-hd
.if !\n[book-ps] .wh -1i tableau-fo
.if !\n[book-ps] .ps 11
.if !\n[book-ps] .vs 14
.EQ
delim $$
chartype bin "∧"
chartype bin "∨"
chartype bin "→"
chartype bin "↔"
chartype punct ","
.EN
.char ⊢ \f[S]\N'uni22A2'
.chapter "Proof by Tableau" logic
.epigraph
If controversies were to arise, there would be no more need of
disputation between two philosophers than between two accountants.
For it would suffice to take their pencils in their hands, and say to
each other: Let us calculate.
.attrib "Leibniz"
.endepigraph

An argument is valid when its conclusion cannot be false while its
premises are true. For a few propositional letters the definition can
be checked by brute force: list every way of making the letters true
or false, and look for a row where every premise is true and the
conclusion false. There is no such row for modus ponens, from
$p → q$ and $p$ to $q$:
.TS
center;
c c | c c | c
c c | c c | c.
$p$	$q$	$p → q$	$p$	$q$
_
T	T	T	T	T
T	F	F	T	F
F	T	T	F	T
F	F	T	F	F
.TE
.p
The table doubles with every letter, and says nothing about necessity
or obligation, where a sentence's truth depends on other worlds than
this one. A tableau, or truth tree, does better. Suppose the premises
true and the conclusion false, and take the formulas apart by their
connectives: $A ∧ B$ puts both $A$ and $B$ on the branch, while
$A ∨ B$ and $A → B$ split it in two. A branch holding a formula and
its negation is closed ($times$): no way of making things true lies
along it. If every branch closes, the supposition was impossible and
the argument is valid. A branch that stays open describes a
counterexample.
.section "Modus ponens" mp

Here is modus ponens again, as a tableau, with a third premise, that
it is cold, which the proof never uses. Denying the conclusion (line
3) and splitting the conditional (line 1) closes both branches at
once (figure \*[ref mp]).
.figure mp
.alt "A tableau for modus ponens: 1. rain → wet, P1. 2. rain, P2. 3. ¬wet, C denied. It branches in two, by 1 →. Branch 1: 4. ¬rain. Closed by 2, 4. Branch 2: 5. wet. Closed by 3, 5. "
.PS
"\s-11.\s0" rjust at (0.603,0.000)
"$ roman \&rain → roman \&wet $" ljust at (0.673,0.000)
"\s-1P1\s0" ljust at (1.659,0.000)
"\s-12.\s0" rjust at (0.603,-0.215)
"$ roman \&rain $" ljust at (0.673,-0.215)
"\s-1P2\s0" ljust at (1.659,-0.215)
"\s-13.\s0" rjust at (0.603,-0.430)
"$¬ roman \&wet $" ljust at (0.673,-0.430)
"\s-1C denied\s0" ljust at (1.659,-0.430)
"\s-11 →\s0" ljust at (1.659,-0.692)
line from (1.016,-0.548) to (0.336,-0.868)
"\s-14.\s0" rjust at (0.095,-0.986)
"$¬ roman \&rain $" ljust at (0.165,-0.986)
"$times$ \s-12, 4\s0" ljust at (0.165,-1.202)
line from (1.016,-0.548) to (1.577,-0.868)
"\s-15.\s0" rjust at (1.352,-0.986)
"$ roman \&wet $" ljust at (1.422,-0.986)
"$times$ \s-13, 5\s0" ljust at (1.422,-1.202)
.PE
.caption "Modus ponens, by tableau: both branches close. The premise that it is cold (P3) is never used."
.endfigure
.section "Necessity" necessity

Modal logic reads $□ A$ as \(lqnecessarily $A$\(rq and $◇ A$ as
\(lqpossibly $A$\(rq. Following Kripke, a model is a set of worlds
and a relation $roman R$ of accessibility between them: $□ A$ is true
at a world when $A$ is true at every world it sees, and $◇ A$ when $A$
is true at some world it sees. Each formula in a tableau is now true
at a world, $w sub 0$ to begin with. A $◇$ opens a new world, and a
$□$ sends its formula along every arrow already drawn. The axiom of
the weakest normal logic, K, is that necessity distributes over the
conditional:
.EQ
□ ( p → q ) , ~ □ p ~ ⊢ ~ □ q
.EN
.LP
Its tableau (figure \*[ref axk]) needs one new world, $w sub 1$, and
closes on both branches there.
.figure axk
.alt "A tableau for axiom K: 1. □(p → q), w0, P1. 2. □p, w0, P2. 3. ¬□q, w0, C denied. 4. ◇¬q, w0, 3 ¬□. 5. w0 R w1, 4 ◇. 6. ¬q, w1, 4 ◇. 7. p → q, w1, 1 □. 8. p, w1, 2 □. It branches in two, by 7 →. Branch 1: 9. ¬p, w1. Closed by 8, 9. Branch 2: 10. q, w1. Closed by 6, 10. "
.PS
"\s-11.\s0" rjust at (0.642,0.000)
"$□ (  p → q  )  ,  w sub 0 $" ljust at (0.712,0.000)
"\s-1P1\s0" ljust at (1.790,0.000)
"\s-12.\s0" rjust at (0.642,-0.215)
"$□ p  ,  w sub 0 $" ljust at (0.712,-0.215)
"\s-1P2\s0" ljust at (1.790,-0.215)
"\s-13.\s0" rjust at (0.642,-0.430)
"$¬□ q  ,  w sub 0 $" ljust at (0.712,-0.430)
"\s-1C denied\s0" ljust at (1.790,-0.430)
"\s-14.\s0" rjust at (0.642,-0.645)
"$◇¬ q  ,  w sub 0 $" ljust at (0.712,-0.645)
"\s-13 ¬□\s0" ljust at (1.790,-0.645)
"\s-15.\s0" rjust at (0.642,-0.860)
"$ w sub 0  ~roman R~  w sub 1 $" ljust at (0.712,-0.860)
"\s-14 ◇\s0" ljust at (1.790,-0.860)
"\s-16.\s0" rjust at (0.642,-1.075)
"$¬ q  ,  w sub 1 $" ljust at (0.712,-1.075)
"\s-14 ◇\s0" ljust at (1.790,-1.075)
"\s-17.\s0" rjust at (0.642,-1.290)
"$ p → q  ,  w sub 1 $" ljust at (0.712,-1.290)
"\s-11 □\s0" ljust at (1.790,-1.290)
"\s-18.\s0" rjust at (0.642,-1.505)
"$ p  ,  w sub 1 $" ljust at (0.712,-1.505)
"\s-12 □\s0" ljust at (1.790,-1.505)
"\s-17 →\s0" ljust at (1.790,-1.767)
line from (1.101,-1.623) to (0.357,-1.943)
"\s-19.\s0" rjust at (0.095,-2.062)
"$¬ p  ,  w sub 1 $" ljust at (0.165,-2.062)
"$times$ \s-18, 9\s0" ljust at (0.165,-2.276)
line from (1.101,-1.623) to (1.715,-1.943)
"\s-110.\s0" rjust at (1.457,-2.062)
"$ q  ,  w sub 1 $" ljust at (1.527,-2.062)
"$times$ \s-16, 10\s0" ljust at (1.527,-2.276)
.PE
.caption "Axiom K in the logic K: $□ ( p → q ) , ~ □ p ~ ⊢ ~ □ q$."
.endfigure
.section "When a branch stays open" open

What is necessary, one would think, is possible: from $□ p$, $◇ p$.
In K it does not follow, and the tableau shows why. Denying $◇ p$
gives $□ ¬ p$, but no rule of K draws a world from two boxes, so
nothing is left to apply and the branch stays open ($↑$). An open
branch is a recipe for a countermodel: one world that sees no world,
where every $□$ is true for want of anything to check and every $◇$
is false (figure \*[ref dk], table \*[ref dk-cm]).
.figure dk
.alt "A tableau for necessarily p, so possibly p, in K, not valid (a branch stays open): 1. □p, w0, P1. 2. ¬◇p, w0, C denied. 3. □¬p, w0, 2 ¬◇. Open: . "
.PS
"\s-11.\s0" rjust at (0.095,0.000)
"$□ p  ,  w sub 0 $" ljust at (0.165,0.000)
"\s-1P1\s0" ljust at (0.966,0.000)
"\s-12.\s0" rjust at (0.095,-0.215)
"$¬◇ p  ,  w sub 0 $" ljust at (0.165,-0.215)
"\s-1C denied\s0" ljust at (0.966,-0.215)
"\s-13.\s0" rjust at (0.095,-0.430)
"$□¬ p  ,  w sub 0 $" ljust at (0.165,-0.430)
"\s-12 ¬◇\s0" ljust at (0.966,-0.430)
"$↑$" ljust at (0.165,-0.645)
.PE
.caption "From $□ p$ to $◇ p$ in K: a branch stays open, and the argument is not valid."
.endfigure
.table dk-cm
.TS
center;
l c.
_
	$ w sub 0 $
_
.sp 0.2
$ p $	F
$roman R ( w )$	$∅$
.sp 0.2
_
.TE
.caption "The countermodel to $□ p ~ ⊢ ~ ◇ p$ in K: one world, $w sub 0$, where $p$ is false and which sees no world."
.endtable
.LP
The cure is to require that every world see at least one world. This
is the logic KD, and its D is the rule that draws a new world when
none is there. Read $□$ as \(lqit ought to be that\(rq and $◇$ as
\(lqit is permitted that\(rq, written O and P, and KD becomes the
standard deontic logic. Its axiom is that what is obligatory is
permitted, and now the tree closes (figure \*[ref kd]).
.figure kd
.alt "A tableau for O p, so P p, in KD: 1. O p, w0, P1. 2. ¬P p, w0, C denied. 3. O ¬p, w0, 2 ¬P. 4. w0 R w1, D. 5. p, w1, 1 O. 6. ¬p, w1, 3 O. Closed by 5, 6. "
.PS
"\s-11.\s0" rjust at (0.095,0.000)
"$ roman O ^  p  ,  w sub 0 $" ljust at (0.165,0.000)
"\s-1P1\s0" ljust at (0.982,0.000)
"\s-12.\s0" rjust at (0.095,-0.215)
"$¬ roman P ^  p  ,  w sub 0 $" ljust at (0.165,-0.215)
"\s-1C denied\s0" ljust at (0.982,-0.215)
"\s-13.\s0" rjust at (0.095,-0.430)
"$ roman O ^ ¬ p  ,  w sub 0 $" ljust at (0.165,-0.430)
"\s-12 ¬P\s0" ljust at (0.982,-0.430)
"\s-14.\s0" rjust at (0.095,-0.645)
"$ w sub 0  ~roman R~  w sub 1 $" ljust at (0.165,-0.645)
"\s-1D\s0" ljust at (0.982,-0.645)
"\s-15.\s0" rjust at (0.095,-0.860)
"$ p  ,  w sub 1 $" ljust at (0.165,-0.860)
"\s-11 O\s0" ljust at (0.982,-0.860)
"\s-16.\s0" rjust at (0.095,-1.075)
"$¬ p  ,  w sub 1 $" ljust at (0.165,-1.075)
"\s-13 O\s0" ljust at (0.982,-1.075)
"$times$ \s-15, 6\s0" ljust at (0.165,-1.290)
.PE
.caption "From O $p$ to P $p$ in KD: the rule D draws $w sub 1$, and the tree closes."
.endfigure
